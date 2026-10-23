import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/learn_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/word_speaker.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';
import 'package:vocab_helper/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProgressStore> pumpStudying(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    ThemeData? theme,
    String bookId = 'pep-ps-3',
    Map<String, Object>? prefs,
  }) async {
    SharedPreferences.setMockInitialValues({
      'selected_book_id': bookId,
      'daily_goal': 20,
      ...?prefs,
    });
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;

    final store = await ProgressStore.open();
    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        theme: theme ?? AppTheme.light(),
        home: Scaffold(
          appBar: AppBar(title: const Text('单词小助手')),
          body: LearnScreen(
            store: store,
            repo: WordbookRepository(),
            bookId: bookId,
            onNeedSetup: () {},
            speaker: FakeWordSpeaker(),
            onStartQuiz: () {},
            onLearnNew: () {},
            onReviewWrongAll: () {},
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 40));
    });
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const ValueKey('learn_flash_card')).evaluate().isNotEmpty) break;
    }
    expect(
      find.byKey(const ValueKey('learn_flash_card')),
      findsOneWidget,
      reason: 'studying UI did not load flash card',
    );
    return store;
  }

  Future<void> clearTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
  }

  testWidgets('R43 wow layout + reveal + overflow + SRS + wide', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // --- keys / proportions / no chip dump ---
    await pumpStudying(tester);
    expect(find.byKey(const ValueKey('learn_progress_thin')), findsOneWidget);
    expect(find.byKey(const ValueKey('learn_wow_word')), findsOneWidget);
    expect(find.byKey(const ValueKey('learn_wow_reveal_hint')), findsOneWidget);
    expect(find.byKey(const ValueKey('learn_known')), findsOneWidget);
    expect(find.byKey(const ValueKey('learn_unknown')), findsOneWidget);
    expect(find.byKey(const ValueKey('learn_overflow_menu')), findsOneWidget);
    expect(find.byKey(const ValueKey('today_task_learn')), findsNothing);
    expect(find.byType(SegmentedButton<String>), findsNothing);
    final bodyH = tester.getSize(find.byType(LearnScreen)).height;
    final cardH = tester.getSize(find.byKey(const ValueKey('learn_flash_card'))).height;
    expect(cardH / bodyH, greaterThan(0.50), reason: 'card $cardH / body $bodyH');
    expect(tester.getSize(find.byKey(const ValueKey('learn_known'))).height, greaterThanOrEqualTo(48));

    // --- reveal keeps word ---
    expect(find.byKey(const ValueKey('learn_wow_meaning')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('learn_wow_reveal_hint')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('learn_wow_word')), findsOneWidget);
    expect(find.byKey(const ValueKey('learn_wow_meaning')), findsOneWidget);

    // --- overflow modes ---
    await tester.tap(find.byKey(const ValueKey('learn_overflow_menu')));
    await tester.pumpAndSettle();
    expect(find.text('更多练习'), findsOneWidget);
    expect(find.byKey(const ValueKey('today_task_learn')), findsOneWidget);
    expect(find.byKey(const ValueKey('today_task_wrong')), findsOneWidget);
    expect(find.byKey(const ValueKey('today_task_quiz')), findsOneWidget);
    expect(find.byKey(const ValueKey('unit_picker_button')), findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    // --- know advances SRS ---
    final store = await ProgressStore.open();
    final before = store.learnedIds().length;
    final firstWord = (tester.widget(find.byKey(const ValueKey('learn_wow_word'))) as Text).data;
    await tester.tap(find.byKey(const ValueKey('learn_known')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 40));
    });
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      final w = find.byKey(const ValueKey('learn_wow_word'));
      if (w.evaluate().isNotEmpty && (tester.widget(w) as Text).data != firstWord) break;
    }
    expect(store.learnedIds().length, greaterThan(before));
    expect((tester.widget(find.byKey(const ValueKey('learn_wow_word'))) as Text).data, isNot(equals(firstWord)));

    // --- wide ---
    await clearTree(tester);
    await pumpStudying(tester, size: const Size(1024, 700));
    expect(find.byKey(const ValueKey('learn_flash_card')), findsOneWidget);
    expect(find.byKey(const ValueKey('learn_known')), findsOneWidget);
    expect(find.byKey(const ValueKey('learn_unknown')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
