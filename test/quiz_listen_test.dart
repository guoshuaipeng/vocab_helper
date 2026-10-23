import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/models/word.dart';
import 'package:vocab_helper/screens/quiz_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/quiz_engine.dart';
import 'package:vocab_helper/services/word_speaker.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';

Word w(String id, String word, String meaning, {String unit = 'U1'}) => Word(
      id: id,
      word: word,
      meaning: meaning,
      unit: unit,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('quizVariant defaults meaning and persists listen', () async {
    final store = await ProgressStore.open();
    expect(store.quizVariant(), 'meaning');
    await store.setQuizVariant('listen');
    expect(store.quizVariant(), 'listen');
    await store.setQuizVariant('other');
    expect(store.quizVariant(), 'meaning');
  });

  test('listenMode distractors have distinct meanings', () {
    final book = [
      w('1', 'apple', '苹果'),
      w('2', 'pear', '梨'),
      w('3', 'banana', '香蕉'),
      w('4', 'grape', '葡萄'),
      w('5', 'applause', '苹果'), // same meaning as apple — skip in listen
    ];
    final q = QuizEngine.buildQuestion(
      target: book[0],
      bookWords: book,
      listenMode: true,
      random: null,
    )!;
    final meanings = q.options.map((o) => o.meaning).toSet();
    expect(meanings.length, q.options.length);
    expect(q.options.any((o) => o.id == '5'), isFalse);
  });

  testWidgets('listen mode auto-speaks target; options show meanings; no spelling before answer',
      (tester) async {
    SharedPreferences.setMockInitialValues({'quiz_variant': 'listen', 'daily_goal': 5});
    final store = await ProgressStore.open();
    final fake = FakeWordSpeaker();
    final questions = [
      QuizQuestion(
        target: w('a', 'apple', '苹果'),
        options: [
          w('a', 'apple', '苹果'),
          w('b', 'pear', '梨'),
          w('c', 'banana', '香蕉'),
          w('d', 'grape', '葡萄'),
        ],
        correctIndex: 0,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: QuizScreen(
          store: store,
          repo: WordbookRepository(),
          mode: QuizMode.book,
          speaker: fake,
          seedQuestions: questions,
          seedBookTitle: 'demo',
        ),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('听英文，选意思'), findsOneWidget);
    expect(find.text('apple'), findsNothing);
    expect(find.text('苹果'), findsWidgets);
    expect(fake.spoken, contains('apple'));
    final before = fake.spoken.length;
    await tester.tap(find.byKey(const ValueKey('quiz_replay')));
    await tester.pump();
    expect(fake.spoken.length, greaterThan(before));
  });

  testWidgets('TTS failure degrades to meaning mode with SnackBar', (tester) async {
    SharedPreferences.setMockInitialValues({'quiz_variant': 'listen', 'daily_goal': 5});
    final store = await ProgressStore.open();
    final fake = FakeWordSpeaker(); // speak ok on boot
    final questions = [
      QuizQuestion(
        target: w('a', 'apple', '苹果'),
        options: [
          w('a', 'apple', '苹果'),
          w('b', 'pear', '梨'),
          w('c', 'banana', '香蕉'),
        ],
        correctIndex: 0,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuizScreen(
            store: store,
            repo: WordbookRepository(),
            mode: QuizMode.book,
            speaker: fake,
            seedQuestions: questions,
            seedBookTitle: 'demo',
            embedded: true,
          ),
        ),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('听英文，选意思'), findsOneWidget);
    fake.throwOnSpeak = true;
    await tester.tap(find.byKey(const ValueKey('quiz_replay')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('暂时没法朗读，已改为看中文选英文'), findsOneWidget);
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('选出对应的英文单词'), findsOneWidget);
  });

  testWidgets('no English voice disables listen segment', (tester) async {
    SharedPreferences.setMockInitialValues({'quiz_variant': 'listen'});
    final store = await ProgressStore.open();
    final fake = FakeWordSpeaker()..voiceAvailable = false;
    final questions = [
      QuizQuestion(
        target: w('a', 'apple', '苹果'),
        options: [w('a', 'apple', '苹果'), w('b', 'pear', '梨')],
        correctIndex: 0,
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: QuizScreen(
          store: store,
          repo: WordbookRepository(),
          mode: QuizMode.book,
          speaker: fake,
          seedQuestions: questions,
          seedBookTitle: 'demo',
        ),
      ),
    );
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('请安装系统英文语音包后再用听音'), findsOneWidget);
    expect(find.text('选出对应的英文单词'), findsOneWidget);
  });
}
