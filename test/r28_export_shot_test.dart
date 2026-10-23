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

  Future<void> capture(
    WidgetTester tester, {
    required Size size,
    required ThemeData theme,
    required String outName,
    required bool openSheet,
  }) async {
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-3',
      'learned_ids': ['pep-ps-3-1', 'pep-ps-3-2'],
      'wrong_ids': ['pep-ps-3-3'],
      'streak_days': 4,
      'daily_goal': 20,
      'today_count': 3,
    });
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
        home: RepaintBoundary(
          key: const ValueKey('shot_root'),
          child: Scaffold(
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
      ),
    );
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const ValueKey('export_progress')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('export_progress')));
    await tester.pump();

    if (openSheet) {
      await tester.tap(find.byKey(const ValueKey('export_progress')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('导出进度'), findsOneWidget);
    }

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

  testWidgets(
    'capture r28 export screenshots',
    (tester) async {
      await capture(tester, size: const Size(390, 920), theme: AppTheme.light(), outName: 'r28-export-narrow-light.png', openSheet: true);
      await capture(tester, size: const Size(390, 920), theme: AppTheme.dark(), outName: 'r28-export-narrow-dark.png', openSheet: true);
      await capture(tester, size: const Size(1000, 920), theme: AppTheme.light(), outName: 'r28-export-wide-light.png', openSheet: true);
      await capture(tester, size: const Size(1000, 920), theme: AppTheme.dark(), outName: 'r28-export-wide-dark.png', openSheet: true);
      await capture(tester, size: const Size(390, 920), theme: AppTheme.light(), outName: 'r28-me-button-narrow-light.png', openSheet: false);
    },
    skip: !update,
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
