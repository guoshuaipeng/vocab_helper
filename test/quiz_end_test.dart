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

Future<void> pumpToEnd(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({
    'quiz_variant': 'meaning',
    'daily_goal': 5,
    'selected_book_id': 'pep-ps-3',
  });
  final store = await ProgressStore.open();
  final questions = [
    QuizQuestion(
      target: w('a', 'apple', '苹果'),
      options: [w('a', 'apple', '苹果'), w('b', 'pear', '梨'), w('c', 'banana', '香蕉'), w('d', 'grape', '葡萄')],
      correctIndex: 0,
    ),
  ];
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: QuizScreen(
        store: store,
        repo: WordbookRepository(),
        mode: QuizMode.book,
        speaker: FakeWordSpeaker(),
        seedQuestions: questions,
        seedBookTitle: '测试词书',
      ),
    ),
  );
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 40));
  }
  // tap correct option (apple)
  await tester.tap(find.text('apple'));
  await tester.pump();
  // next / view results
  final next = find.text('查看结果');
  expect(next, findsOneWidget);
  await tester.tap(next);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('quiz end: title 22sp, rate weight, retry padding', (tester) async {
    await pumpToEnd(tester);
    expect(find.text('本轮自测完成'), findsOneWidget);
    final title = tester.widget<Text>(find.text('本轮自测完成'));
    expect(title.style?.fontSize, 22);

    expect(find.byKey(const ValueKey('quiz_end_rate')), findsOneWidget);
    final rate = tester.widget<Text>(find.byKey(const ValueKey('quiz_end_rate')));
    expect(rate.style?.fontSize, 36);
    expect(find.textContaining('正确 1 / 1'), findsOneWidget);

    expect(find.byKey(const ValueKey('quiz_end_retry')), findsOneWidget);
    expect(find.text('再测一轮'), findsOneWidget);
    final pad = find.descendant(
      of: find.byKey(const ValueKey('quiz_end_retry')),
      matching: find.byWidgetPredicate(
        (w) => w is Padding &&
            w.padding == const EdgeInsets.symmetric(vertical: 14),
      ),
    );
    expect(pad, findsOneWidget);
  });
}
