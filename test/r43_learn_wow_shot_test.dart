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
    bool reveal = false,
    bool openOverflow = false,
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
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });

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
          appBar: AppBar(title: const Text('单词小助手')),
          body: LearnScreen(
            key: ValueKey('learn_$outName'),
            store: store,
            repo: WordbookRepository(),
            bookId: 'pep-ps-3',
            onNeedSetup: () {},
            speaker: FakeWordSpeaker(),
            onStartQuiz: () {},
            onLearnNew: () {},
            onReviewWrongAll: () {},
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 40));
    });
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      if (find.byKey(const ValueKey('learn_flash_card')).evaluate().isNotEmpty) break;
    }
    expect(find.byKey(const ValueKey('learn_flash_card')), findsOneWidget);

    if (reveal) {
      await tester.tap(find.byKey(const ValueKey('learn_wow_reveal_hint')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('learn_wow_meaning')), findsOneWidget);
    }
    if (openOverflow) {
      await tester.tap(find.byKey(const ValueKey('learn_overflow_menu')));
      await tester.pumpAndSettle();
      expect(find.text('更多练习'), findsOneWidget);
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
    'capture r43 learn wow shots',
    (tester) async {
      await capture(tester,
          size: const Size(390, 844),
          theme: AppTheme.light(),
          outName: 'r43-narrow-light.png');
      await capture(tester,
          size: const Size(390, 844),
          theme: AppTheme.light(),
          outName: 'r43-narrow-light-revealed.png',
          reveal: true);
      await capture(tester,
          size: const Size(390, 844),
          theme: AppTheme.dark(),
          outName: 'r43-narrow-dark.png');
      await capture(tester,
          size: const Size(1024, 700),
          theme: AppTheme.light(),
          outName: 'r43-wide.png');
      await capture(tester,
          size: const Size(390, 844),
          theme: AppTheme.light(),
          outName: 'r43-overflow.png',
          openOverflow: true);
    },
    skip: !update,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
