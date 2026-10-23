import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/me_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';
import 'package:vocab_helper/theme/app_theme.dart';

/// One testWidgets — SharedPreferences mock is process-singleton; multi-test leaks.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProgressStore> openStore(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    for (final e in values.entries) {
      final v = e.value;
      if (v is String) {
        await prefs.setString(e.key, v);
      } else if (v is int) {
        await prefs.setInt(e.key, v);
      } else if (v is bool) {
        await prefs.setBool(e.key, v);
      } else if (v is List<String>) {
        await prefs.setStringList(e.key, v);
      }
    }
    if (!values.containsKey('selected_book_id')) {
      await prefs.remove('selected_book_id');
    }
    if (!values.containsKey('learned_ids')) {
      await prefs.setStringList('learned_ids', <String>[]);
    }
    if (!values.containsKey('wrong_ids')) {
      await prefs.setStringList('wrong_ids', <String>[]);
    }
    return ProgressStore(prefs);
  }

  Future<void> clearTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  Future<void> pumpMe(
    WidgetTester tester,
    Map<String, Object> prefs, {
    Size size = const Size(390, 1400),
  }) async {
    await clearTree(tester);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    final store = await openStore(prefs);
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
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> openExportSheet(WidgetTester tester) async {
    final export = find.byKey(const ValueKey('export_progress'));
    await tester.ensureVisible(export);
    await tester.pump(const Duration(milliseconds: 100));
    final ink = tester.widget<InkWell>(export);
    expect(ink.onTap, isNotNull);
    ink.onTap!();
    await tester.pump();
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const ValueKey('export_preview')).evaluate().isNotEmpty) break;
    }
    expect(find.byKey(const ValueKey('export_preview')), findsOneWidget);
  }

  testWidgets('R51 export discoverability + empty hint + copy', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // A2: no book → disabled
    await pumpMe(tester, {}, size: const Size(390, 900));
    expect(find.byKey(const ValueKey('export_progress')), findsOneWidget);
    expect(find.byKey(const ValueKey('me_export_row')), findsOneWidget);
    final ink = tester.widget<InkWell>(find.byKey(const ValueKey('export_progress')));
    expect(ink.onTap, isNull);
    expect(find.text('先选一本词书'), findsWidgets);

    // A4: empty progress sheet
    await pumpMe(tester, {
      'selected_book_id': 'pep-ps-3',
    });
    expect(find.textContaining('三年级'), findsWidgets);
    expect(find.text('复制或分享给家长 · 老师'), findsOneWidget);
    await openExportSheet(tester);
    expect(find.byKey(const ValueKey('export_empty_hint')), findsOneWidget);
    expect(find.textContaining('还没有已学或错词'), findsOneWidget);
    expect(find.byKey(const ValueKey('export_copy')), findsOneWidget);

    // A3: with progress → preview + copy snackbar
    await pumpMe(tester, {
      'selected_book_id': 'pep-ps-3',
      'learned_ids': <String>['pep-ps-3-1'],
      'wrong_ids': <String>['pep-ps-3-2'],
      'streak_days': 2,
    });
    expect(find.textContaining('本词书已学 1'), findsOneWidget);
    expect(find.text('复制或分享给家长 · 老师'), findsOneWidget);
    await openExportSheet(tester);
    expect(find.byKey(const ValueKey('export_empty_hint')), findsNothing);
    expect(find.byKey(const ValueKey('export_share')), findsOneWidget);
    expect(find.byKey(const ValueKey('export_copy')), findsOneWidget);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') return null;
        if (call.method == 'Clipboard.getData') return <String, dynamic>{'text': ''};
        return null;
      },
    );
    final copyBtn = tester.widget<FilledButton>(find.byKey(const ValueKey('export_copy')));
    expect(copyBtn.onPressed, isNotNull);
    copyBtn.onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('已复制到剪贴板'), findsOneWidget);
  });
}
