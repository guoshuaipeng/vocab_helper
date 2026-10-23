import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/models/word.dart';
import 'package:vocab_helper/screens/quiz_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/quiz_engine.dart';
import 'package:vocab_helper/services/word_speaker.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';
import 'package:vocab_helper/theme/app_theme.dart';

Word w(String id, String word, String meaning) =>
    Word(id: id, word: word, meaning: meaning, unit: 'U1');

List<QuizQuestion> twoQuestions() => [
      QuizQuestion(
        target: w('a', 'apple', '苹果'),
        options: [w('a', 'apple', '苹果'), w('b', 'pear', '梨'), w('c', 'banana', '香蕉'), w('d', 'grape', '葡萄')],
        correctIndex: 0,
      ),
      QuizQuestion(
        target: w('b', 'pear', '梨'),
        options: [w('b', 'pear', '梨'), w('a', 'apple', '苹果'), w('c', 'banana', '香蕉'), w('d', 'grape', '葡萄')],
        correctIndex: 0,
      ),
    ];

Future<void> pumpQuiz(WidgetTester tester, {required bool missFirst}) async {
  SharedPreferences.setMockInitialValues({
    'quiz_variant': 'meaning',
    'daily_goal': 5,
    'selected_book_id': 'pep-ps-3',
  });
  final store = await ProgressStore.open();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: QuizScreen(
        store: store,
        repo: WordbookRepository(),
        mode: QuizMode.book,
        speaker: FakeWordSpeaker(),
        seedQuestions: twoQuestions(),
        seedBookTitle: '测试词书',
      ),
    ),
  );
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 40));
  }
  // Q1
  await tester.tap(find.text(missFirst ? 'pear' : 'apple'));
  await tester.pump();
  await tester.tap(find.text('下一题'));
  await tester.pump();
  // Q2 correct
  await tester.tap(find.text('pear'));
  await tester.pump();
  await tester.tap(find.text('查看结果'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('quiz end all-correct: 回学习 only, no 错题再练', (tester) async {
    await pumpQuiz(tester, missFirst: false);
    expect(find.text('本轮自测完成'), findsOneWidget);
    expect(find.byKey(const ValueKey('quiz_end_rate')), findsOneWidget);
    expect(find.byKey(const ValueKey('quiz_end_back')), findsOneWidget);
    expect(find.text('回学习'), findsOneWidget);
    expect(find.byKey(const ValueKey('quiz_end_wrong_retry')), findsNothing);
    expect(find.text('错题再练'), findsNothing);
    final pad = find.descendant(
      of: find.byKey(const ValueKey('quiz_end_back')),
      matching: find.byWidgetPredicate(
        (w) => w is Padding &&
            w.padding == const EdgeInsets.symmetric(vertical: 14),
      ),
    );
    expect(pad, findsOneWidget);
  });

  testWidgets('quiz end with wrongs: shows 错题再练 then retry badge', (tester) async {
    await pumpQuiz(tester, missFirst: true);
    expect(find.textContaining('本场错了 1 个'), findsOneWidget);
    expect(find.byKey(const ValueKey('quiz_end_wrong_retry')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('quiz_end_wrong_retry')));
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
    expect(find.byKey(const ValueKey('quiz_retry_badge')), findsOneWidget);
    expect(find.textContaining('错题再练'), findsWidgets);
    // Only the missed word (apple) should be in retry pool — prompt meaning.
    expect(find.text('苹果'), findsOneWidget);
  });
}
