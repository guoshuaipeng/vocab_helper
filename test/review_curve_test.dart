import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/learn_screen.dart';
import 'package:vocab_helper/screens/me_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/word_speaker.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';
import 'package:vocab_helper/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpLearn(WidgetTester tester, ProgressStore store, {Key? key}) async {
    tester.view.physicalSize = const Size(390, 920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(
      MaterialApp(
        key: key ?? UniqueKey(),
        theme: AppTheme.light(),
        home: Scaffold(
          body: LearnScreen(
            store: store,
            repo: WordbookRepository(),
            bookId: 'pep-ps-3',
            onNeedSetup: () {},
            speaker: FakeWordSpeaker(),
          ),
        ),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('认识后显示下次提示；关闭后不显示', (tester) async {
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-3',
      'daily_goal': 50,
    });
    final store = await ProgressStore.open();
    await pumpLearn(tester, store, key: const ValueKey('learn_hint_on'));

    expect(find.byKey(const ValueKey('learn_known')), findsOneWidget);
    expect(find.byKey(const ValueKey('review_next_hint')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('learn_known')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('review_next_hint')), findsOneWidget);
    expect(find.text('下次 · 明天复习'), findsOneWidget);

    await store.setReviewNextHintEnabled(false);
    await tester.pump(const Duration(milliseconds: 1700)); // clear tip timer
    expect(store.reviewNextHintEnabled(), isFalse);
    expect(find.byKey(const ValueKey('learn_known')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('learn_known')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('review_next_hint')), findsNothing);
  });

  testWidgets('我的页待复习旁有间隔说明', (tester) async {
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-3',
      'daily_goal': 20,
      'learned_ids': <String>['pep-ps-3-1'],
      'review_at_pep-ps-3-1': '2026-10-01',
    });
    tester.view.physicalSize = const Size(390, 920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
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
            onStartDueReview: () {},
          ),
        ),
      ),
    );
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const ValueKey('me_review_curve_hint')), findsOneWidget);
    expect(find.text('间隔会随认识变长'), findsOneWidget);
  });
}
