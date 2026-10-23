import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/learn_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/word_speaker.dart';
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
    bool pressed = false,
  }) async {
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-3',
      'daily_goal': 20,
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
            body: LearnScreen(
              key: ValueKey('learn_$outName'),
              store: store,
              repo: WordbookRepository(),
              bookId: 'pep-ps-3',
              onNeedSetup: () {},
              speaker: FakeWordSpeaker(),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const ValueKey('learn_known')), findsOneWidget);

    TestGesture? gesture;
    if (pressed) {
      gesture = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('learn_known'))));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
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

    if (gesture != null) {
      // Cancel (do not up) so FilledButton onPressed / flash timer is not armed.
      await gesture.cancel();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets(
    'capture learn-scale screenshots',
    (tester) async {
      await capture(tester, size: const Size(390, 920), theme: AppTheme.light(), outName: 'learn-scale-narrow-light.png');
      await capture(tester, size: const Size(390, 920), theme: AppTheme.dark(), outName: 'learn-scale-narrow-dark.png');
      await capture(tester, size: const Size(390, 920), theme: AppTheme.light(), outName: 'learn-scale-pressed.png', pressed: true);
    },
    skip: !update,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
