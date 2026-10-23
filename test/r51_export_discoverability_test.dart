import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/me_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';
import 'package:vocab_helper/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('R51: export row visible without expanding more', (tester) async {
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-3',
      'learned_ids': <String>['pep-ps-3-1'],
    });
    tester.view.physicalSize = const Size(390, 844);
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
            onStartDueReview: () {},
          ),
        ),
      ),
    );
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const ValueKey('me_export_row')), findsOneWidget);
    expect(find.byKey(const ValueKey('export_progress')), findsOneWidget);
    expect(find.text('复制或分享给家长 · 老师'), findsOneWidget);
    expect(find.text('朗读口音'), findsNothing);
    expect(find.text('单元 · 口音 · 统计'), findsOneWidget);
    expect(find.textContaining('导出 ·'), findsNothing);
  });
}
