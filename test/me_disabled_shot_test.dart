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
    required double scrollDy,
  }) async {
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-3',
      'daily_goal': 20,
      'learned_ids': ['pep-ps-3-1'],
      'today_count': 1,
      'streak_days': 2,
      'today_date': ProgressStore.dateKey(DateTime.now()),
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
        key: ValueKey(outName),
        theme: withCjk(theme),
        home: Scaffold(
          body: RepaintBoundary(
            key: const ValueKey('shot_root'),
            child: MeScreen(
              key: ValueKey('me_$outName'),
              store: store,
              repo: WordbookRepository(),
              speaker: FakeWordSpeaker()..voiceAvailable = true,
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
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    final list = find.byType(Scrollable);
    if (list.evaluate().isNotEmpty) {
      await tester.drag(list.first, Offset(0, scrollDy));
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(find.text('自测当前单元'), findsOneWidget);

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

  testWidgets('capture me-disabled screenshots', (tester) async {
    await capture(
      tester,
      size: const Size(390, 920),
      theme: AppTheme.dark(),
      outName: 'me-disabled-narrow-dark.png',
      scrollDy: -420,
    );
    await capture(
      tester,
      size: const Size(900, 700),
      theme: AppTheme.dark(),
      outName: 'me-disabled-contrast.png',
      scrollDy: -200,
    );
  }, skip: !update);
}
