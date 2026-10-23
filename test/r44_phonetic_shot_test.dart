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
  }) async {
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'hj-ox-7a-2024',
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
            bookId: 'hj-ox-7a-2024',
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
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      if (find.byKey(const ValueKey('learn_flash_card')).evaluate().isNotEmpty) break;
    }
    expect(find.byKey(const ValueKey('learn_flash_card')), findsOneWidget);
    // Unrevealed: first word guitar should show IPA under the lemma.
    expect(find.text('guitar'), findsWidgets);
    expect(find.textContaining('/'), findsWidgets);

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
    'capture r44 hj-ox phonetic unrevealed shots',
    (tester) async {
      await capture(
        tester,
        size: const Size(390, 844),
        theme: AppTheme.light(),
        outName: 'r44-narrow-light-phonetic.png',
      );
      await capture(
        tester,
        size: const Size(390, 844),
        theme: AppTheme.dark(),
        outName: 'r44-narrow-dark-phonetic.png',
      );
    },
    skip: !update,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
