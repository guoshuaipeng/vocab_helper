import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/me_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';
import 'package:vocab_helper/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('export disabled without book; enabled with book opens sheet', (tester) async {
    SharedPreferences.setMockInitialValues({});
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
          ),
        ),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const ValueKey('export_progress')), findsOneWidget);
    final btn = tester.widget<TextButton>(find.byKey(const ValueKey('export_progress')));
    expect(btn.onPressed, isNull);
    expect(find.text('先选一本词书'), findsOneWidget);
  });

  testWidgets('export with book shows preview and copy snackbar', (tester) async {
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-3',
      'learned_ids': ['pep-ps-3-1'],
      'wrong_ids': ['pep-ps-3-2'],
      'streak_days': 2,
    });
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
          ),
        ),
      ),
    );
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('导出本词书进度'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('export_progress')));
    await tester.tap(find.byKey(const ValueKey('export_progress')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('导出进度'), findsOneWidget);
    expect(find.byKey(const ValueKey('export_copy')), findsOneWidget);
    expect(find.byKey(const ValueKey('export_share')), findsOneWidget);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') return null;
        if (call.method == 'Clipboard.getData') return {'text': ''};
        return null;
      },
    );
    await tester.tap(find.byKey(const ValueKey('export_copy')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('已复制到剪贴板'), findsOneWidget);
  });
}
