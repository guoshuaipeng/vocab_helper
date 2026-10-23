import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/me_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';
import 'package:vocab_helper/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('dark disabledForeground vs button face contrast >= 3:1', () {
    final theme = AppTheme.dark();
    final scheme = theme.colorScheme;
    final fg = AppTheme.disabledForeground(scheme);
    final bg = AppTheme.disabledBackground(scheme);
    final ratio = AppTheme.contrastRatio(fg, bg);
    expect(ratio, greaterThanOrEqualTo(3.0));
    expect(theme.filledButtonTheme.style, isNotNull);
  });

  testWidgets('deep dark me page shows disabled 自测/复习 buttons', (tester) async {
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-3',
      'daily_goal': 20,
      'learned_ids': ['pep-ps-3-1'],
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
        theme: AppTheme.dark(),
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
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    for (var i = 0; i < 20; i++) {
      if (find.text('自测当前单元').evaluate().isNotEmpty) break;
      final list = find.byType(Scrollable);
      if (list.evaluate().isEmpty) break;
      await tester.drag(list.first, const Offset(0, -320));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('自测当前单元'), findsOneWidget);
    final unitBtn = tester.widget<FilledButton>(find.widgetWithText(FilledButton, '自测当前单元'));
    expect(unitBtn.onPressed, isNull);

    for (var i = 0; i < 12; i++) {
      if (find.text('复习全部错词').evaluate().isNotEmpty) break;
      final list = find.byType(Scrollable);
      if (list.evaluate().isEmpty) break;
      await tester.drag(list.first, const Offset(0, -280));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('复习全部错词'), findsOneWidget);
    final wrongBtn = tester.widget<FilledButton>(find.widgetWithText(FilledButton, '复习全部错词'));
    expect(wrongBtn.onPressed, isNull);
  });
}
