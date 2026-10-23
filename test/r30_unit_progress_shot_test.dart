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

  Map<String, Object> prefs() => {
        'selected_book_id': 'pep-ps-4',
        'learned_ids': [
          'pep-ps-4-1',
          'pep-ps-4-2',
          'pep-ps-4-3',
          'pep-ps-4-21',
        ],
        'wrong_ids': ['pep-ps-4-2', 'pep-ps-4-22'],
        'daily_goal': 20,
        'today_count': 3,
        'streak_days': 2,
        'today_date': ProgressStore.dateKey(DateTime.now()),
      };

  Future<void> pumpMe(
    WidgetTester tester, {
    required Size size,
    required ThemeData theme,
    required Brightness brightness,
  }) async {
    SharedPreferences.setMockInitialValues(prefs());
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final store = await ProgressStore.open();
    final themed = withCjk(theme);
    await tester.pumpWidget(
      MaterialApp(
        theme: themed,
        darkTheme: themed,
        themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
        builder: (context, child) => ColoredBox(
          color: themed.colorScheme.surface,
          child: RepaintBoundary(
            key: const ValueKey('shot_root'),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
        home: Scaffold(
          backgroundColor: themed.colorScheme.surface,
          body: MeScreen(
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
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
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

  Future<void> openSheet(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const ValueKey('me_unit_progress')));
    await tester.tap(find.byKey(const ValueKey('me_unit_progress')));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const ValueKey('unit_progress_list')), findsOneWidget);
  }

  testWidgets('capture r30 unit-progress screenshots', (tester) async {
    // entry narrow light
    await pumpMe(
      tester,
      size: const Size(390, 920),
      theme: AppTheme.light(),
      brightness: Brightness.light,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
    await tester.pump(const Duration(milliseconds: 200));
    await saveShot(tester, 'r30-entry-narrow-light.png');

    // sheet narrow light
    await openSheet(tester);
    await saveShot(tester, 'r30-sheet-narrow-light.png');

    // sheet narrow dark
    await pumpMe(
      tester,
      size: const Size(390, 920),
      theme: AppTheme.dark(),
      brightness: Brightness.dark,
    );
    await openSheet(tester);
    await saveShot(tester, 'r30-sheet-narrow-dark.png');

    // sheet wide light
    await pumpMe(
      tester,
      size: const Size(900, 700),
      theme: AppTheme.light(),
      brightness: Brightness.light,
    );
    await openSheet(tester);
    await saveShot(tester, 'r30-sheet-wide-light.png');

    // sheet wide dark
    await pumpMe(
      tester,
      size: const Size(900, 700),
      theme: AppTheme.dark(),
      brightness: Brightness.dark,
    );
    await openSheet(tester);
    await saveShot(tester, 'r30-sheet-wide-dark.png');
  }, skip: !update);
}
