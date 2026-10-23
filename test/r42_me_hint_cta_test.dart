import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/me_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';
import 'package:vocab_helper/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('R3 me: 去切换 calls onChangeBook', (tester) async {
    SharedPreferences.setMockInitialValues({'selected_book_id': 'pep-ps-3'});
    final store = await ProgressStore.open();
    var called = 0;
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
            onChangeBook: () => called++,
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
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const ValueKey('me_recommend_switch_hint')).evaluate().isNotEmpty) break;
    }
    expect(find.byKey(const ValueKey('me_recommend_switch_hint')), findsOneWidget);
    await tester.tap(find.descendant(
      of: find.byKey(const ValueKey('me_recommend_switch_hint')),
      matching: find.text('去切换'),
    ));
    await tester.pump();
    expect(called, 1);
  });
}
