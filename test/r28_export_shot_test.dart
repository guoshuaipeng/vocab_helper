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

  void mockClipboard() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') return null;
        if (call.method == 'Clipboard.getData') return <String, dynamic>{'text': ''};
        return null;
      },
    );
  }

  Future<void> pumpMe(
    WidgetTester tester, {
    required Size size,
    required ThemeData theme,
    required String outName,
  }) async {
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-3',
      'learned_ids': ['pep-ps-3-1', 'pep-ps-3-2'],
      'wrong_ids': ['pep-ps-3-3'],
      'streak_days': 4,
      'daily_goal': 20,
      'today_count': 3,
      'today_date': ProgressStore.dateKey(DateTime.now()),
    });
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    final store = await ProgressStore.open();
    // builder wraps navigator (incl. modal routes) inside RepaintBoundary
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
          ),
        ),
      ),
    );
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const ValueKey('export_progress')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('export_progress')));
    await tester.pump();
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

  Future<void> openExportSheet(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('export_progress')));
    await tester.pump(); // start async load
    // wait until sheet title appears, then settle animation
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('导出进度').evaluate().isNotEmpty) break;
    }
    expect(find.text('导出进度'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('export_preview')), findsOneWidget);
    expect(find.text('复制全部'), findsOneWidget);
    expect(find.text('分享'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('export_copy')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'capture r28 export screenshots',
    (tester) async {
      await pumpMe(
        tester,
        size: const Size(390, 920),
        theme: AppTheme.light(),
        outName: 'r28-me-button-narrow-light.png',
      );
      await saveShot(tester, 'r28-me-button-narrow-light.png');

      for (final cfg in [
        (const Size(390, 920), AppTheme.light(), 'r28-export-narrow-light.png'),
        (const Size(390, 920), AppTheme.dark(), 'r28-export-narrow-dark.png'),
        (const Size(1000, 920), AppTheme.light(), 'r28-export-wide-light.png'),
        (const Size(1000, 920), AppTheme.dark(), 'r28-export-wide-dark.png'),
      ]) {
        await pumpMe(tester, size: cfg.$1, theme: cfg.$2, outName: cfg.$3);
        await openExportSheet(tester);
        await saveShot(tester, cfg.$3);
      }

      mockClipboard();
      await pumpMe(
        tester,
        size: const Size(390, 920),
        theme: AppTheme.light(),
        outName: 'r28-export-copy-snackbar.png',
      );
      await openExportSheet(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('export_copy')));
      await tester.tap(find.byKey(const ValueKey('export_copy')));
      await tester.pump();
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('已复制到剪贴板').evaluate().isNotEmpty) break;
      }
      expect(find.text('已复制到剪贴板'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      await saveShot(tester, 'r28-export-copy-snackbar.png');
    },
    skip: !update,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
