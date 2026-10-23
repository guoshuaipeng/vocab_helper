import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/me_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';
import 'package:vocab_helper/theme/app_theme.dart';

Future<void> loadCjkFont() async {
  final bytes = await File(r'C:\Windows\Fonts\Deng.ttf').readAsBytes();
  final data = ByteData.sublistView(Uint8List.fromList(bytes));
  await (FontLoader('ShotCJK')..addFont(Future.value(data))).load();
}

ThemeData withCjk(ThemeData base) => base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: 'ShotCJK'),
      primaryTextTheme: base.primaryTextTheme.apply(fontFamily: 'ShotCJK'),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final update = Platform.environment['UPDATE_SHOTS'] == '1';

  setUpAll(() async {
    if (update) await loadCjkFont();
  });

  Future<void> pumpMe(
    WidgetTester tester, {
    required Size size,
    required ThemeData theme,
    required String outName,
    required Map<String, Object> prefs,
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final store = await ProgressStore.open();
    await tester.pumpWidget(
      MaterialApp(
        key: ValueKey('app_$outName'),
        theme: withCjk(theme),
        builder: (context, child) => RepaintBoundary(
          key: const ValueKey('shot_root'),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: MeScreen(
            key: ValueKey('me_$outName'),
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
  }

  Future<void> saveShot(WidgetTester tester, String outName) async {
    await tester.runAsync(() async {
      final boundary =
          tester.renderObject(find.byKey(const ValueKey('shot_root'))) as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final out = File('docs/shots/$outName');
      await out.parent.create(recursive: true);
      await out.writeAsBytes(bytes!.buffer.asUint8List());
    });
  }

  Map<String, Object> duePrefs() => {
        'selected_book_id': 'pep-ps-3',
        'learned_ids': ['pep-ps-3-1', 'pep-ps-3-2', 'pep-ps-3-3'],
        'review_at_pep-ps-3-1': '2026-10-01',
        'review_at_pep-ps-3-2': '2026-10-05',
        'review_at_pep-ps-3-3': '2026-10-08',
        'daily_goal': 20,
        'today_count': 2,
        'streak_days': 3,
        'today_date': ProgressStore.dateKey(DateTime.now()),
      };

  Map<String, Object> emptyPrefs() => {
        'selected_book_id': 'pep-ps-3',
        'learned_ids': ['pep-ps-3-1'],
        'review_at_pep-ps-3-1': '2099-06-01',
        'daily_goal': 20,
        'today_count': 0,
        'streak_days': 0,
        'today_date': ProgressStore.dateKey(DateTime.now()),
      };

  testWidgets('capture r29 due-review screenshots', (tester) async {
    // entry narrow light
    await pumpMe(
      tester,
      size: const Size(390, 920),
      theme: AppTheme.light(),
      outName: 'r29-entry-narrow-light.png',
      prefs: duePrefs(),
    );
    await saveShot(tester, 'r29-entry-narrow-light.png');

    for (final cfg in [
      (const Size(390, 920), AppTheme.light(), 'r29-sheet-narrow-light.png'),
      (const Size(390, 920), AppTheme.dark(), 'r29-sheet-narrow-dark.png'),
      (const Size(1000, 900), AppTheme.light(), 'r29-sheet-wide-light.png'),
      (const Size(1000, 900), AppTheme.dark(), 'r29-sheet-wide-dark.png'),
    ]) {
      await pumpMe(tester, size: cfg.$1, theme: cfg.$2, outName: cfg.$3, prefs: duePrefs());
      await tester.tap(find.byKey(const ValueKey('me_due_review')));
      await tester.pump();
      for (var i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('开始复习').evaluate().isNotEmpty) break;
      }
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.text('到期复习'), findsOneWidget);
      expect(find.text('开始复习'), findsOneWidget);
      await saveShot(tester, cfg.$3);
    }

    // empty state
    await pumpMe(
      tester,
      size: const Size(390, 920),
      theme: AppTheme.light(),
      outName: 'r29-empty-narrow-light.png',
      prefs: emptyPrefs(),
    );
    await tester.tap(find.byKey(const ValueKey('me_due_review')));
    await tester.pump();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const ValueKey('due_review_empty')).evaluate().isNotEmpty) break;
    }
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('due_review_empty')), findsOneWidget);
    await saveShot(tester, 'r29-empty-narrow-light.png');
  }, skip: !update, timeout: const Timeout(Duration(minutes: 5)));
}
