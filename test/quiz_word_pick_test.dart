import 'dart:math';

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

  test('quizVariant persists word', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.open();
    await store.setQuizVariant('word');
    expect(store.quizVariant(), 'word');
  });

  test('word-pick question: prompt is English word; options include correct meaning', () {
    final book = [
      w('1', 'apple', '苹果'),
      w('2', 'pear', '梨'),
      w('3', 'banana', '香蕉'),
      w('4', 'grape', '葡萄'),
      w('5', 'applause', '苹果'), // duplicate meaning — skip as distractor
    ];
    final q = QuizEngine.buildQuestion(
      target: book[0],
      bookWords: book,
      listenMode: true, // distinct meanings (same as word-pick)
      random: Random(3),
    )!;
    expect(q.target.word, 'apple');
    expect(q.options.map((o) => o.meaning).toSet().length, q.options.length);
    expect(q.options.any((o) => o.id == '1'), isTrue);
    expect(q.options.any((o) => o.id == '5'), isFalse);
    expect(q.options[q.correctIndex].meaning, '苹果');
  });

  testWidgets('word variant shows English stem + Chinese meaning options', (tester) async {
    SharedPreferences.setMockInitialValues({'quiz_variant': 'word', 'daily_goal': 5});
    final store = await ProgressStore.open();
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
          speaker: FakeWordSpeaker()..voiceAvailable = true,
          seedQuestions: questions,
          seedBookTitle: '测试词书',
        ),
      ),
    );
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const ValueKey('prompt_word')), findsOneWidget);
    expect(find.byKey(const ValueKey('prompt_word_text')), findsOneWidget);
    expect(find.text('apple'), findsOneWidget);
    expect(find.text('苹果'), findsOneWidget);
    expect(find.text('梨'), findsOneWidget);
    // 判分前不露正解高亮 — options still enabled
    await tester.tap(find.text('梨'));
    await tester.pump();
    expect(find.textContaining('正确答案'), findsOneWidget);
  });

  testWidgets('narrow segmented shows 义 词 听 写', (tester) async {
    SharedPreferences.setMockInitialValues({'quiz_variant': 'word', 'daily_goal': 5});
    final store = await ProgressStore.open();
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
          speaker: FakeWordSpeaker()..voiceAvailable = true,
          seedQuestions: questions,
        ),
      ),
    );
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('义'), findsOneWidget);
    expect(find.text('词'), findsOneWidget);
    expect(find.text('听'), findsOneWidget);
    expect(find.text('写'), findsOneWidget);
  });


  testWidgets('wide short shows all 4 meaning options on screen', (tester) async {
    SharedPreferences.setMockInitialValues({'quiz_variant': 'word', 'daily_goal': 5});
    final store = await ProgressStore.open();
    tester.view.physicalSize = const Size(900, 560);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final questions = [
      QuizQuestion(
        target: w('a', 'apple', '苹果'),
        options: [
          w('a', 'apple', '苹果'),
          w('b', 'book', '书本'),
          w('c', 'desk', '桌子'),
          w('d', 'water', '水'),
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
          speaker: FakeWordSpeaker()..voiceAvailable = true,
          seedQuestions: questions,
        ),
      ),
    );
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('苹果'), findsOneWidget);
    expect(find.text('书本'), findsOneWidget);
    expect(find.text('桌子'), findsOneWidget);
    expect(find.text('水'), findsOneWidget);
    // Prefer grid when vertical space is tight.
    expect(find.byKey(const ValueKey('quiz_options_grid')), findsOneWidget);
  });

}
