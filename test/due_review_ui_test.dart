import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/me_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';
import 'package:vocab_helper/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('待复习行可点；清单含到期词；开始复习回调', (tester) async {
    var started = false;
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-3',
      'learned_ids': ['pep-ps-3-1', 'pep-ps-3-2'],
      'review_at_pep-ps-3-1': '2026-10-01',
      'review_at_pep-ps-3-2': '2026-10-05',
      'daily_goal': 20,
      'today_count': 1,
      'streak_days': 1,
      'today_date': ProgressStore.dateKey(DateTime.now()),
    });
    tester.view.physicalSize = const Size(390, 920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await ProgressStore.open();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: MeScreen(
            store: store,
            repo: WordbookRepository(),
            onRefresh: () {},
            onChangeBook: () {},
            onReviewWrong: () {},
            onReviewWrongCurrentUnit: () {},
            onQuizBook: () {},
            onQuizUnit: () {},
            onQuizWrong: () {},
            onStartDueReview: () => started = true,
          ),
        ),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.byKey(const ValueKey('me_due_review')), findsOneWidget);
    expect(find.textContaining('待复习'), findsOneWidget);
    expect(find.byKey(const ValueKey('me_due_go')), findsOneWidget);
    expect(find.byKey(const ValueKey('me_due_action')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('me_due_review')));
    await tester.pump();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('到期复习').evaluate().isNotEmpty) break;
    }
    expect(find.text('到期复习'), findsOneWidget);
    expect(find.byKey(const ValueKey('due_review_subtitle')), findsOneWidget);
    expect(find.byKey(const ValueKey('due_review_start')), findsOneWidget);
    expect(find.byKey(const ValueKey('due_review_list')), findsOneWidget);

    // CTA above list: start Y < list Y
    final startY = tester.getTopLeft(find.byKey(const ValueKey('due_review_start'))).dy;
    final listY = tester.getTopLeft(find.byKey(const ValueKey('due_review_list'))).dy;
    expect(startY < listY, isTrue);

    final startBtn = find.byKey(const ValueKey('due_review_start'));
    await tester.ensureVisible(startBtn);
    await tester.pumpAndSettle();
    await tester.tap(startBtn);
    await tester.pumpAndSettle();
    expect(started, isTrue);
  });

  testWidgets('Hero 去复习一键开练', (tester) async {
    var started = false;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-3',
      'learned_ids': ['pep-ps-3-1', 'pep-ps-3-2'],
      'review_at_pep-ps-3-1': '2026-10-01',
      'review_at_pep-ps-3-2': '2026-10-05',
      'daily_goal': 20,
      'today_count': 1,
      'streak_days': 1,
      'today_date': ProgressStore.dateKey(DateTime.now()),
    });
    tester.view.physicalSize = const Size(390, 920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await ProgressStore.open();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: MeScreen(
            store: store,
            repo: WordbookRepository(),
            onRefresh: () {},
            onChangeBook: () {},
            onReviewWrong: () {},
            onReviewWrongCurrentUnit: () {},
            onQuizBook: () {},
            onQuizUnit: () {},
            onQuizWrong: () {},
            onStartDueReview: () => started = true,
          ),
        ),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    final go = find.byKey(const ValueKey('me_due_go'));
    await tester.ensureVisible(go);
    await tester.tap(go);
    await tester.pump();
    expect(started, isTrue);
  });

  testWidgets('N=0 进空态并可去学新词', (tester) async {
    var started = false;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-3',
      'learned_ids': ['pep-ps-3-1'],
      'review_at_pep-ps-3-1': '2099-01-01',
      'daily_goal': 20,
      'today_count': 0,
      'streak_days': 0,
      'today_date': ProgressStore.dateKey(DateTime.now()),
    });
    tester.view.physicalSize = const Size(390, 920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await ProgressStore.open();
    expect(store.dueReviewCountForBook('pep-ps-3'), 0);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: MeScreen(
            store: store,
            repo: WordbookRepository(),
            onRefresh: () {},
            onChangeBook: () {},
            onReviewWrong: () {},
            onReviewWrongCurrentUnit: () {},
            onQuizBook: () {},
            onQuizUnit: () {},
            onQuizWrong: () {},
            onStartDueReview: () => started = true,
          ),
        ),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('暂无到期复习'), findsWidgets);
    expect(find.byKey(const ValueKey('me_due_go')), findsNothing);
    expect(find.byKey(const ValueKey('me_due_action')), findsNothing);
    final entry = find.byKey(const ValueKey('me_due_review'));
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pump();
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('到期复习').evaluate().isNotEmpty) break;
    }
    expect(find.text('到期复习'), findsOneWidget);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const ValueKey('due_review_empty')).evaluate().isNotEmpty) break;
    }
    expect(find.byKey(const ValueKey('due_review_empty')), findsOneWidget);
    expect(find.byKey(const ValueKey('due_review_empty_hint')), findsOneWidget);
    final learnNew = find.byKey(const ValueKey('due_review_learn_new'));
    await tester.ensureVisible(learnNew);
    await tester.pump(const Duration(milliseconds: 100));
    final btn = tester.widget<FilledButton>(learnNew);
    btn.onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(started, isTrue);
  });
}
