import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/setup_screen.dart';
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

  Future<void> saveShot(WidgetTester tester, String outName) async {
    if (!update) return;
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

  Future<void> captureSetup(
    WidgetTester tester, {
    required Size size,
    required ThemeData theme,
    required String outName,
  }) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await ProgressStore.open();
    await tester.pumpWidget(MaterialApp(
      key: ValueKey('app_$outName'),
      theme: withCjk(theme),
      builder: (context, child) => RepaintBoundary(
        key: const ValueKey('shot_root'),
        child: ColoredBox(
          color: theme.scaffoldBackgroundColor,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: SetupScreen(
        key: ValueKey('setup_$outName'),
        store: store,
        repo: WordbookRepository(),
        onDone: () {},
      ),
    ));
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const ValueKey('setup_recommend_hint')), findsOneWidget);
    expect(find.byKey(const ValueKey('setup_book_recommended')), findsOneWidget);
    await saveShot(tester, outName);
  }

  testWidgets('capture r40 setup preselect 4 variants', (tester) async {
    await captureSetup(
      tester,
      size: const Size(390, 844),
      theme: AppTheme.light(),
      outName: 'r40-setup-preselect-narrow-light.png',
    );
    await captureSetup(
      tester,
      size: const Size(390, 844),
      theme: AppTheme.dark(),
      outName: 'r40-setup-preselect-narrow-dark.png',
    );
    await captureSetup(
      tester,
      size: const Size(900, 700),
      theme: AppTheme.light(),
      outName: 'r40-setup-preselect-wide-light.png',
    );
    await captureSetup(
      tester,
      size: const Size(900, 700),
      theme: AppTheme.dark(),
      outName: 'r40-setup-preselect-wide-dark.png',
    );
  });
}
