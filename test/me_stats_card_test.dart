import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/me_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';
import 'package:vocab_helper/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-3',
      'daily_goal': 20,
      'learned_ids': ['pep-ps-3-1', 'pep-ps-3-2'],
      'today_count': 3,
      'streak_days': 5,
    });
  });


  Future<void> scrollToStats(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      if (find.byKey(const ValueKey('me_stats_summary')).evaluate().isNotEmpty) {
        return;
      }
      final list = find.byType(Scrollable);
      if (list.evaluate().isEmpty) break;
      await tester.drag(list.first, const Offset(0, -400));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpMe(WidgetTester tester, ProgressStore store) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
          onStartDueReview: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('我的页统计合并为一张三列卡，数字与 store 一致', (tester) async {
    final store = await ProgressStore.open();
    await pumpMe(tester, store);
    await scrollToStats(tester);

    expect(find.byKey(const ValueKey('me_stats_summary')), findsOneWidget);
    expect(find.byKey(const ValueKey('me_stat_learned')), findsOneWidget);
    expect(find.byKey(const ValueKey('me_stat_today')), findsOneWidget);
    expect(find.byKey(const ValueKey('me_stat_streak')), findsOneWidget);

    // One summary card only — not three stacked StatCards
    expect(find.text('已学单词'), findsOneWidget);
    expect(find.text('今日新学'), findsOneWidget);
    expect(find.text('连续天数'), findsOneWidget);

    expect(find.text('${store.learnedCount()}'), findsWidgets);
    expect(find.text('${store.todayCount()}'), findsWidgets);
    expect(find.text('${store.streakDays()}'), findsWidgets);

    // R23 week view still present, untouched structurally
    expect(find.byKey(const ValueKey('me_week_checkin')), findsOneWidget);
  });

  testWidgets('窄窗 360 宽统计卡无横向溢出', (tester) async {
    final store = await ProgressStore.open();
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
          onStartDueReview: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await scrollToStats(tester);

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('me_stats_summary')), findsOneWidget);
  });
}
