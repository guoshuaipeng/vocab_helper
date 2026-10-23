import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/learn_screen.dart';
import 'package:vocab_helper/services/word_speaker.dart';
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

  testWidgets('r42_shot_learn_narrow_dark', (tester) async {
    SharedPreferences.setMockInitialValues({'selected_book_id': 'pep-ps-3'});
    final store = await ProgressStore.open();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: withCjk(AppTheme.dark()),
      builder: (context, child) => RepaintBoundary(
        key: const ValueKey('shot_root'),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: LearnScreen(
          store: store,
          repo: WordbookRepository(),
          bookId: 'pep-ps-3',
          onNeedSetup: () {},
          onChangeBook: () {},
          speaker: FakeWordSpeaker(),
        ),
      ),
    ));
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const ValueKey('learn_recommend_switch_hint')), findsOneWidget);
    if (update) {
      await tester.runAsync(() async {
        final boundary =
            tester.renderObject(find.byKey(const ValueKey('shot_root'))) as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1.5);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final out = File('docs/shots/r42-learn-narrow-dark.png');
        await out.parent.create(recursive: true);
        await out.writeAsBytes(bytes!.buffer.asUint8List());
      });
    }
  });
}
