import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/quiz_screen.dart';
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

/// SharedPreferences.setMockInitialValues does not refresh an already-opened
/// in-memory store across captures in one testWidgets — sync explicitly.
Future<ProgressStore> openStoreWithWrongIds(List<String> wrongIds) async {
  SharedPreferences.setMockInitialValues({
    'selected_book_id': 'pep-ps-4',
    'quiz_variant': 'word',
    'daily_goal': 8,
    'wrong_ids': wrongIds,
  });
  final store = await ProgressStore.open();
  final want = wrongIds.toSet();
  for (final id in store.wrongIds().toList()) {
    if (!want.contains(id)) await store.removeWrong(id);
  }
  for (final id in want) {
    await store.markWrong(id);
  }
  await store.setQuizVariant('word');
  return store;
}

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
    required Brightness brightness,
    required String outName,
    required bool wrongOnly,
    List<String> wrongIds = const [
      'pep-ps-4-1',
      'pep-ps-4-2',
      'pep-ps-4-3',
      'pep-ps-4-4',
      'pep-ps-4-5',
      'pep-ps-4-6',
    ],
    bool showEmptySnackBar = false,
  }) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    final store = await openStoreWithWrongIds(wrongIds);
    expect(store.wrongIds().length, wrongIds.length,
        reason: 'shot $outName must use exact wrong count');

    final themed = withCjk(theme);
    await tester.pumpWidget(
      MaterialApp(
        theme: themed,
        darkTheme: themed,
        themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
        home: ColoredBox(
          color: themed.colorScheme.surface,
          child: RepaintBoundary(
            key: const ValueKey('shot_root'),
            child: QuizScreen(
              store: store,
              repo: WordbookRepository(),
              mode: wrongOnly ? QuizMode.wrong : QuizMode.book,
              speaker: FakeWordSpeaker()..voiceAvailable = true,
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    if (!wrongOnly && wrongIds.isNotEmpty) {
      await tester.tap(find.byKey(const ValueKey('quiz_pool_wrong')));
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }
    if (showEmptySnackBar) {
      expect(find.text('只测错词'), findsOneWidget);
      expect(find.textContaining('只测错词 ·'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('quiz_pool_wrong')));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.textContaining('还没有错词，先去学或自测'), findsOneWidget);
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

  testWidgets('capture r32 wrong-pool screenshots', (tester) async {
    await capture(
      tester,
      size: const Size(390, 920),
      theme: AppTheme.light(),
      brightness: Brightness.light,
      outName: 'r32-wrong-pool-narrow-light.png',
      wrongOnly: true,
    );
    await capture(
      tester,
      size: const Size(390, 920),
      theme: AppTheme.dark(),
      brightness: Brightness.dark,
      outName: 'r32-wrong-pool-narrow-dark.png',
      wrongOnly: true,
    );
    await capture(
      tester,
      size: const Size(900, 700),
      theme: AppTheme.light(),
      brightness: Brightness.light,
      outName: 'r32-wrong-pool-wide-light.png',
      wrongOnly: true,
    );
    await capture(
      tester,
      size: const Size(900, 700),
      theme: AppTheme.dark(),
      brightness: Brightness.dark,
      outName: 'r32-wrong-pool-wide-dark.png',
      wrongOnly: true,
    );
    // Real wrong-count=0: Chip「只测错词」+ SnackBar after tap.
    await capture(
      tester,
      size: const Size(390, 920),
      theme: AppTheme.light(),
      brightness: Brightness.light,
      outName: 'r32-wrong-pool-empty-narrow-light.png',
      wrongOnly: false,
      wrongIds: const [],
      showEmptySnackBar: true,
    );
  }, skip: !update);
}
