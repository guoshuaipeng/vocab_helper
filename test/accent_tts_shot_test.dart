import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/expand_me_more.dart';
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
    required ThemeData theme,
    required Brightness brightness,
    required String outName,
  }) async {
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-3',
      'daily_goal': 20,
      'learned_ids': ['pep-ps-3-1'],
      'today_count': 1,
      'streak_days': 1,
      'today_date': ProgressStore.dateKey(DateTime.now()),
    });
    tester.view.physicalSize = const Size(390, 920);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final store = await ProgressStore.open();
    final speaker = FakeWordSpeaker()..voiceAvailable = false;
    final themed = withCjk(theme);
    await tester.pumpWidget(
      MaterialApp(
        key: ValueKey(outName),
        theme: themed,
        darkTheme: themed,
        themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
        home: Scaffold(
          backgroundColor: themed.colorScheme.surface,
          body: RepaintBoundary(
            key: const ValueKey('shot_root'),
            child: ColoredBox(
              color: themed.colorScheme.surface,
              child: MeScreen(
              key: ValueKey('me_$outName'),
              store: store,
              repo: WordbookRepository(),
              speaker: speaker,
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
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    for (var i = 0; i < 20; i++) {
      await expandMeMore(tester);
      if (find.byKey(const ValueKey('me_accent_tts_hint')).evaluate().isNotEmpty) break;
      final list = find.byType(Scrollable);
      if (list.evaluate().isEmpty) break;
      await tester.drag(list.first, const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await expandMeMore(tester);
    expect(find.byKey(const ValueKey('me_accent_tts_hint')), findsOneWidget);
    // Bring accent card fully into view (hint near bottom of card).
    final list = find.byType(Scrollable);
    if (list.evaluate().isNotEmpty) {
      await tester.drag(list.first, const Offset(0, -280));
      await tester.pump(const Duration(milliseconds: 200));
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

  testWidgets('capture accent-tts missing-voice screenshots', (tester) async {
    await capture(tester, theme: AppTheme.light(), brightness: Brightness.light, outName: 'accent-tts-light.png');
    await capture(tester, theme: AppTheme.dark(), brightness: Brightness.dark, outName: 'accent-tts-dark.png');
  }, skip: !update);
}
