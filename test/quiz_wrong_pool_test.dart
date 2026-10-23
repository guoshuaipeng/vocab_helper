import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/models/word.dart';
import 'package:vocab_helper/screens/quiz_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/review_queue.dart';
import 'package:vocab_helper/services/word_speaker.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';

Word w(String id, String word, String meaning, {String unit = 'U1'}) =>
    Word(id: id, word: word, meaning: meaning, unit: unit);

Future<void> pumpUntilChips(WidgetTester tester) async {
  for (var i = 0; i < 80; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.byKey(const ValueKey('quiz_pool_chips')).evaluate().isNotEmpty) {
      return;
    }
  }
  fail(
    'quiz_pool_chips not found; texts='
    '${find.byType(Text).evaluate().map((e) => (e.widget as Text).data).whereType<String>().toList()}',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final book = [
    w('b-1', 'apple', '苹果', unit: 'U1'),
    w('b-2', 'pear', '梨', unit: 'U1'),
    w('b-3', 'cat', '猫', unit: 'U1'),
    w('b-4', 'dog', '狗', unit: 'U2'),
    w('b-5', 'egg', '鸡蛋', unit: 'U2'),
  ];

  test('buildQuizPool wrong-only ∩ unit', () {
    final wrong = {'b-1', 'b-4', 'b-5'};
    expect(
      buildQuizPool(bookWords: book, wrongIds: wrong, wrongOnly: true)
          .map((e) => e.id)
          .toSet(),
      {'b-1', 'b-4', 'b-5'},
    );
    expect(
      buildQuizPool(
        bookWords: book,
        wrongIds: wrong,
        unitFilter: 'U1',
        wrongOnly: true,
      ).map((e) => e.id).toList(),
      ['b-1'],
    );
    expect(
      buildQuizPool(
        bookWords: book,
        wrongIds: wrong,
        unitFilter: 'U2',
        wrongOnly: false,
      ).map((e) => e.id).toSet(),
      {'b-4', 'b-5'},
    );
  });

  testWidgets('pool chips: wrong mode / switch / empty snackbar', (tester) async {
    // --- wrong mode starts on 只测错词 ---
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-4',
      'quiz_variant': 'meaning',
      'daily_goal': 5,
      'wrong_ids': ['pep-ps-4-1', 'pep-ps-4-2', 'pep-ps-4-3', 'pep-ps-4-4'],
    });
    var store = await ProgressStore.open();
    await tester.pumpWidget(
      MaterialApp(
        home: QuizScreen(
          store: store,
          repo: WordbookRepository(),
          mode: QuizMode.wrong,
          speaker: FakeWordSpeaker()..voiceAvailable = true,
        ),
      ),
    );
    // R46: wrong mode locks pool (no switch chips).
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const ValueKey('quiz_pool_locked')).evaluate().isNotEmpty) break;
    }
    expect(find.byKey(const ValueKey('quiz_pool_locked')), findsOneWidget);
    expect(find.textContaining('测这些错词'), findsWidgets);
    expect(find.byKey(const ValueKey('quiz_pool_all')), findsNothing);
    expect(find.byKey(const ValueKey('quiz_pool_chips')), findsNothing);

    // --- book mode: switch to wrong-only ---
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-4',
      'quiz_variant': 'meaning',
      'daily_goal': 5,
      'wrong_ids': ['pep-ps-4-1', 'pep-ps-4-2', 'pep-ps-4-3', 'pep-ps-4-4'],
    });
    store = await ProgressStore.open();
    for (final id in ['pep-ps-4-1', 'pep-ps-4-2', 'pep-ps-4-3', 'pep-ps-4-4']) {
      await store.markWrong(id);
    }
    await tester.pumpWidget(
      MaterialApp(
        home: QuizScreen(
          store: store,
          repo: WordbookRepository(),
          mode: QuizMode.book,
          speaker: FakeWordSpeaker()..voiceAvailable = true,
        ),
      ),
    );
    await pumpUntilChips(tester);
    expect(
      tester.widget<FilterChip>(find.byKey(const ValueKey('quiz_pool_all'))).selected,
      isTrue,
    );
    await tester.tap(find.byKey(const ValueKey('quiz_pool_wrong')));
    await pumpUntilChips(tester);
    expect(find.textContaining('改测错词'), findsOneWidget);
    expect(
      tester.widget<FilterChip>(find.byKey(const ValueKey('quiz_pool_wrong'))).selected,
      isTrue,
    );

    // --- empty wrong: snackbar ---
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-4',
      'quiz_variant': 'meaning',
      'daily_goal': 5,
      'wrong_ids': <String>[],
    });
    store = await ProgressStore.open();
    for (final id in store.wrongIds().toList()) {
      await store.removeWrong(id);
    }
    await tester.pumpWidget(
      MaterialApp(
        home: QuizScreen(
          store: store,
          repo: WordbookRepository(),
          mode: QuizMode.book,
          speaker: FakeWordSpeaker()..voiceAvailable = true,
        ),
      ),
    );
    await pumpUntilChips(tester);
    await tester.tap(find.byKey(const ValueKey('quiz_pool_wrong')));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.textContaining('还没有错词'), findsOneWidget);
  });
}
