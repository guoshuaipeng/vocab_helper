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

  Future<void> pumpDictation(
    WidgetTester tester,
    ProgressStore store,
    FakeWordSpeaker speaker, {
    List<QuizQuestion>? questions,
  }) async {
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
          speaker: speaker,
          seedQuestions: qs,
          seedBookTitle: 'demo',
        ),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
  }

  testWidgets('dictation: auto-speak + replay increments FakeWordSpeaker', (tester) async {
    SharedPreferences.setMockInitialValues({
      'quiz_variant': 'dictation',
      'daily_goal': 5,
    });
    final store = await ProgressStore.open();
    final speaker = FakeWordSpeaker();
    await pumpDictation(tester, store, speaker);

    expect(find.byKey(const ValueKey('quiz_dictation_input')), findsOneWidget);
    expect(find.text('听写'), findsWidgets);
    expect(find.text('苹果'), findsNothing);
    expect(find.text('apple'), findsNothing);
    expect(speaker.spoken, isNotEmpty);
    expect(speaker.spoken.last, 'apple');
    final afterBoot = speaker.spoken.length;

    await tester.tap(find.byKey(const ValueKey('quiz_dictation_replay')));
    await tester.pump();
    expect(speaker.spoken.length, afterBoot + 1);
    expect(speaker.spoken.last, 'apple');
  });

  testWidgets('dictation: correct / wrong / empty; no stem leak before grade', (tester) async {
    SharedPreferences.setMockInitialValues({
      'quiz_variant': 'dictation',
      'daily_goal': 5,
    });
    final store = await ProgressStore.open();
    final speaker = FakeWordSpeaker();
    await pumpDictation(tester, store, speaker);

    expect(find.text('apple'), findsNothing);
    expect(find.text('苹果'), findsNothing);
    expect(find.byKey(const ValueKey('quiz_dictation_input')), findsOneWidget);

    // empty: no wrong
    await tester.tap(find.byKey(const ValueKey('quiz_dictation_check')));
    await tester.pump();
    expect(store.wrongIds(), isEmpty);
    expect(find.text('正确答案：apple'), findsNothing);

    // wrong
    await tester.enterText(find.byKey(const ValueKey('quiz_dictation_input')), 'aple');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('quiz_dictation_check')));
    await tester.pump();
    // Allow async markWrong + setState to settle.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(find.textContaining('正确答案：apple'), findsOneWidget);
    expect(store.wrongIds().contains('a'), isTrue);
    expect(find.text('苹果'), findsNothing);
    // Grade succeeded; skip CTA navigation (covered by spell tests / result page).
    expect(find.byKey(const ValueKey('quiz_dictation_input')), findsOneWidget);
    expect(find.byKey(const ValueKey('quiz_dictation_replay')), findsOneWidget);
  });

  testWidgets('dictation correct: case-insensitive; removeWrong + bumpToday', (tester) async {
    SharedPreferences.setMockInitialValues({
      'quiz_variant': 'dictation',
      'daily_goal': 5,
      'wrong_ids': ['a'],
      'today_count': 0,
    });
    final store = await ProgressStore.open();
    final speaker = FakeWordSpeaker();
    await pumpDictation(tester, store, speaker);

    await tester.enterText(find.byKey(const ValueKey('quiz_dictation_input')), 'Apple');
    await tester.tap(find.byKey(const ValueKey('quiz_dictation_check')));
    await tester.pump();
    expect(find.text('拼对了'), findsOneWidget);
    expect(find.text('apple'), findsWidgets); // revealed after grade
    expect(store.wrongIds().contains('a'), isFalse);
    expect(store.todayCount(), 1);
    expect(store.learnedIds().contains('a'), isFalse);
  });

  testWidgets('dictation TTS unavailable falls back; no silent quiz', (tester) async {
    SharedPreferences.setMockInitialValues({
      'quiz_variant': 'dictation',
      'daily_goal': 5,
    });
    final store = await ProgressStore.open();
    final speaker = FakeWordSpeaker()..voiceAvailable = false;
    await pumpDictation(tester, store, speaker);

    // prepareAndBoot should fall back to meaning (no dictation pane)
    expect(find.byKey(const ValueKey('quiz_dictation_input')), findsNothing);
    expect(find.byKey(const ValueKey('prompt_meaning')), findsOneWidget);
  });

  test('gradeSpell reused for dictation', () {
    expect(QuizEngine.gradeSpell(input: ' apple ', target: 'Apple'), SpellGrade.correct);
    expect(QuizEngine.gradeSpell(input: '', target: 'Apple'), SpellGrade.empty);
  });
}
