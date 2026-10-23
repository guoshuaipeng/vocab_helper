import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/me_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';
import 'package:vocab_helper/theme/app_theme.dart';

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
    if (!values.containsKey('learned_ids')) {
      await prefs.setStringList('learned_ids', <String>[]);
    }
    if (!values.containsKey('wrong_ids')) {
      await prefs.setStringList('wrong_ids', <String>[]);
    }
    return ProgressStore(prefs);
  }

  Future<void> pumpMe(
    WidgetTester tester,
    Map<String, Object> prefs, {
    Size size = const Size(390, 1200),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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

  testWidgets('R51: export row visible without expanding more', (tester) async {
    await pumpMe(tester, {
      'selected_book_id': 'pep-ps-3',
      'learned_ids': <String>['pep-ps-3-1'],
    }, size: const Size(390, 844));
    expect(find.byKey(const ValueKey('me_export_row')), findsOneWidget);
    expect(find.byKey(const ValueKey('export_progress')), findsOneWidget);
    expect(find.text('复制或分享给家长 · 老师'), findsOneWidget);
    expect(find.text('朗读口音'), findsNothing);
    expect(find.text('单元 · 口音 · 统计'), findsOneWidget);
    expect(find.textContaining('导出 ·'), findsNothing);
  });

  testWidgets('R51: export empty progress shows empty hint', (tester) async {
    await pumpMe(tester, {
      'selected_book_id': 'pep-ps-3',
      'learned_ids': <String>[],
      'wrong_ids': <String>[],
    });
    expect(find.text('人教版PEP · 三年级'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('export_progress')));
    await tester.tap(find.byKey(const ValueKey('export_progress')));
    await tester.pump();
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const ValueKey('export_preview')).evaluate().isNotEmpty) break;
    }
    expect(find.byKey(const ValueKey('export_preview')), findsOneWidget);
    expect(find.byKey(const ValueKey('export_empty_hint')), findsOneWidget);
    expect(find.textContaining('还没有已学或错词'), findsOneWidget);
    expect(find.byKey(const ValueKey('export_copy')), findsOneWidget);
  });
}