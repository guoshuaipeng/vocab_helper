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

  testWidgets('narrow portrait: flash card tall; no segmented; compact tasks', (tester) async {
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-3',
      'daily_goal': 20,
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = await ProgressStore.open();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          appBar: AppBar(title: const Text('单词小助手')),
          body: LearnScreen(
            store: store,
            repo: WordbookRepository(),
            bookId: 'pep-ps-3',
            onNeedSetup: () {},
            speaker: FakeWordSpeaker(),
            onStartQuiz: () {},
            onLearnNew: () {},
          ),
        ),
      ),
    );
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      if (find.byKey(const ValueKey('learn_flash_card')).evaluate().isNotEmpty) break;
    }

    expect(find.byKey(const ValueKey('learn_flash_card')), findsOneWidget);
    expect(find.byType(SegmentedButton<String>), findsNothing);
    expect(find.byKey(const ValueKey('today_task_learn')), findsOneWidget);
    expect(find.byKey(const ValueKey('unit_picker_button')), findsOneWidget);

    final cardH = tester.getSize(find.byKey(const ValueKey('learn_flash_card'))).height;
    expect(cardH, greaterThan(844 * 0.40));
    expect(tester.takeException(), isNull);
  });

  Future<void> capture(
    WidgetTester tester, {
    required Size size,
    required ThemeData theme,
    required String outName,
  }) async {
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-3',
      'daily_goal': 20,
      'unit_filter_pep-ps-3': '第1组',
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
      ),
    );
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const ValueKey('learn_flash_card')), findsOneWidget);
    expect(find.byKey(const ValueKey('learn_known')), findsOneWidget);
    expect(tester.takeException(), isNull);

    final card = tester.getSize(find.byKey(const ValueKey('learn_flash_card')));
    expect(card.height, greaterThan(size.height * 0.40),
        reason: 'flash card too short on $outName: ${card.height} vs ${size.height}');

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
    'capture learn-layout screenshots',
    (tester) async {
      await capture(tester, size: const Size(390, 844), theme: AppTheme.light(), outName: 'learn-layout-narrow-light.png');
      await capture(tester, size: const Size(390, 844), theme: AppTheme.dark(), outName: 'learn-layout-narrow-dark.png');
      await capture(tester, size: const Size(1024, 768), theme: AppTheme.light(), outName: 'learn-layout-wide-light.png');
      await capture(tester, size: const Size(1024, 768), theme: AppTheme.dark(), outName: 'learn-layout-wide-dark.png');
    },
    skip: !update,
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
