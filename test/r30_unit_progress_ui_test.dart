import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/expand_me_more.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/me_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/word_speaker.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';
import 'package:vocab_helper/theme/app_theme.dart';





void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpMe(WidgetTester tester, {required Map<String, Object> prefs}) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues(prefs);
    final store = await ProgressStore.open();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: MeScreen(
            store: store,
            repo: WordbookRepository(),
            speaker: FakeWordSpeaker()..voiceAvailable = true,
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
  }

  testWidgets('entry opens sheet with unit rows; tap sets filter + snackbar', (tester) async {
    // pep-ps-4 has Unit 1..12 in assets
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-4',
      'learned_ids': ['pep-ps-4-1'], // may or may not match real ids — counts still show
      'daily_goal': 20,
      'today_count': 1,
      'streak_days': 1,
      'today_date': ProgressStore.dateKey(DateTime.now()),
    });
    // rebuild with open store after mock
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final store = await ProgressStore.open();
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var wentLearn = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: MeScreen(
            store: store,
            repo: WordbookRepository(),
            speaker: FakeWordSpeaker()..voiceAvailable = true,
            onRefresh: () {},
            onChangeBook: () {},
            onReviewWrong: () {},
            onReviewWrongCurrentUnit: () {},
            onQuizBook: () {},
            onQuizUnit: () {},
            onQuizWrong: () {},
            onStartDueReview: () => wentLearn = true,
          ),
        ),
      ),
    );
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    await expandMeMore(tester);
    expect(find.byKey(const ValueKey('me_unit_progress')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('me_unit_progress')));
    await tester.tap(find.byKey(const ValueKey('me_unit_progress')));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('单元进度'), findsWidgets);
    expect(find.byKey(const ValueKey('unit_progress_list')), findsOneWidget);

    final row = find.byKey(const ValueKey('unit_progress_row_Unit 1'));
    expect(row, findsOneWidget);
    await tester.tap(row);
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(store.unitFilterForBook('pep-ps-4'), 'Unit 1');
    expect(find.textContaining('已筛选 · Unit 1'), findsOneWidget);
    expect(wentLearn, isTrue);
  });

  testWidgets('no book → entry disabled with 先选一本词书', (tester) async {
    await pumpMe(tester, prefs: {
      'daily_goal': 20,
      'today_count': 0,
      'streak_days': 0,
      'today_date': ProgressStore.dateKey(DateTime.now()),
    });
    await expandMeMore(tester);
    final entry = find.byKey(const ValueKey('me_unit_progress'));
    expect(entry, findsOneWidget);
    final btn = tester.widget<TextButton>(entry);
    expect(btn.onPressed, isNull);
    // export + unit-progress both show 先选一本词书 when no book
    expect(find.text('先选一本词书'), findsWidgets);
  });
}
