import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/models/word.dart';
import 'package:vocab_helper/screens/quiz_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/quiz_engine.dart';
import 'package:vocab_helper/services/word_speaker.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';
import 'package:vocab_helper/theme/app_theme.dart';

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

  test('gradeSpell trim + case-insensitive; empty not wrong', () {
    expect(QuizEngine.gradeSpell(input: '', target: 'Apple'), SpellGrade.empty);
    expect(QuizEngine.gradeSpell(input: '   ', target: 'Apple'), SpellGrade.empty);
    expect(QuizEngine.gradeSpell(input: 'apple', target: 'Apple'), SpellGrade.correct);
    expect(QuizEngine.gradeSpell(input: ' APPLE ', target: 'apple'), SpellGrade.correct);
    expect(QuizEngine.gradeSpell(input: 'aple', target: 'apple'), SpellGrade.wrong);
  });

  test('quizVariant persists spell', () async {
    final store = await ProgressStore.open();
    expect(store.quizVariant(), 'meaning');
    await store.setQuizVariant('spell');
    expect(store.quizVariant(), 'spell');
    await store.setQuizVariant('listen');
    expect(store.quizVariant(), 'listen');
    await store.setQuizVariant('nope');
    expect(store.quizVariant(), 'meaning');
  });

  Future<void> pumpSpell(WidgetTester tester, ProgressStore store, {List<QuizQuestion>? questions}) async {
    final qs = questions ??
        [
          QuizQuestion(
            target: w('a', 'apple', '苹果'),
            options: [
              w('a', 'apple', '苹果'),
              w('b', 'pear', '梨'),
            ],
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
          seedQuestions: qs,
          seedBookTitle: 'demo',
        ),
      ),
    );
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
  }

  testWidgets('spell: correct / wrong / empty submit', (tester) async {
    SharedPreferences.setMockInitialValues({'quiz_variant': 'spell', 'daily_goal': 5});
    final store = await ProgressStore.open();
    await pumpSpell(tester, store);

    expect(find.byKey(const ValueKey('quiz_spell_input')), findsOneWidget);
    expect(find.text('苹果'), findsOneWidget);
    expect(find.text('apple'), findsNothing);

    // empty
    await tester.tap(find.byKey(const ValueKey('quiz_spell_check')));
    await tester.pump();
    expect(find.text('先写出单词'), findsOneWidget);
    expect(store.wrongCountForBook('a'), 0);

    // wrong
    await tester.enterText(find.byKey(const ValueKey('quiz_spell_input')), 'aple');
    await tester.tap(find.byKey(const ValueKey('quiz_spell_check')));
    await tester.pump();
    expect(find.text('拼对了'), findsNothing);
    expect(find.textContaining('正确答案：apple'), findsOneWidget);
    expect(store.wrongIds().contains('a'), isTrue);

    // next then correct
    await tester.tap(find.byKey(const ValueKey('quiz_spell_next')));
    await tester.pump();
    // only one question -> result page
    expect(find.textContaining('本轮自测完成'), findsOneWidget);
  });

  testWidgets('spell correct removes wrong and bumps today; no markLearned', (tester) async {
    SharedPreferences.setMockInitialValues({
      'quiz_variant': 'spell',
      'daily_goal': 5,
      'wrong_ids': ['a'],
      'today_count': 0,
    });
    final store = await ProgressStore.open();
    await pumpSpell(tester, store);
    await tester.enterText(find.byKey(const ValueKey('quiz_spell_input')), 'Apple');
    await tester.tap(find.byKey(const ValueKey('quiz_spell_check')));
    await tester.pump();
    expect(find.text('拼对了'), findsOneWidget);
    expect(store.wrongIds().contains('a'), isFalse);
    expect(store.todayCount(), 1);
    expect(store.learnedIds().contains('a'), isFalse);
  });
}
