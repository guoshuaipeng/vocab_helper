import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/models/word.dart';
import 'package:vocab_helper/screens/quiz_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/quiz_engine.dart';
import 'package:vocab_helper/services/word_speaker.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';
import 'package:vocab_helper/theme/app_theme.dart';

Word w(String id, String word, String meaning) =>
    Word(id: id, word: word, meaning: meaning, unit: 'U1');

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

  Future<void> captureInProgress(
    WidgetTester tester, {
    required Size size,
    required ThemeData theme,
    required Brightness brightness,
    required String outName,
  }) async {
    SharedPreferences.setMockInitialValues({
      'quiz_variant': 'word',
      'daily_goal': 5,
      'selected_book_id': 'pep-ps-4',
    });
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
    final questions = [
      QuizQuestion(
        target: w('a', 'apple', '苹果'),
        options: [
          w('a', 'apple', '苹果'),
          w('b', 'book', '书本'),
          w('c', 'desk', '桌子'),
          w('d', 'water', '水'),
        ],
        correctIndex: 0,
      ),
    ];

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
              mode: QuizMode.book,
              speaker: FakeWordSpeaker()..voiceAvailable = true,
              seedQuestions: questions,
              seedBookTitle: '人教版 · 四年级',
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const ValueKey('prompt_word')), findsOneWidget);
    expect(find.byKey(const ValueKey('prompt_word_text')), findsOneWidget);

    // Answer correctly so teal CTA + correct-option border are visible (A1).
    final optionButtons = find.byType(OutlinedButton);
    expect(optionButtons, findsWidgets);
    await tester.tap(optionButtons.at(0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text('答对了！'), findsOneWidget);

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

  Future<void> captureEnd(
    WidgetTester tester, {
    required Size size,
    required ThemeData theme,
    required Brightness brightness,
    required String outName,
  }) async {
    SharedPreferences.setMockInitialValues({
      'quiz_variant': 'word',
      'daily_goal': 5,
      'selected_book_id': 'pep-ps-4',
    });
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
    final questions = [
      QuizQuestion(
        target: w('a', 'apple', '苹果'),
        options: [
          w('a', 'apple', '苹果'),
          w('b', 'book', '书本'),
          w('c', 'desk', '桌子'),
          w('d', 'water', '水'),
        ],
        correctIndex: 0,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        key: ValueKey('app_$outName'),
        theme: themed,
        darkTheme: themed,
        themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
        home: ColoredBox(
          color: themed.colorScheme.surface,
          child: RepaintBoundary(
            key: const ValueKey('shot_root'),
            child: QuizScreen(
              key: ValueKey('quiz_$outName'),
              store: store,
              repo: WordbookRepository(),
              mode: QuizMode.book,
              speaker: FakeWordSpeaker()..voiceAvailable = true,
              seedQuestions: questions,
              seedBookTitle: '人教版 · 四年级',
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    final buttons = find.byType(OutlinedButton);
    expect(buttons, findsWidgets);
    await tester.tap(buttons.at(0));
    await tester.pump();
    await tester.tap(find.text('查看结果'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.textContaining('本轮自测完成'), findsOneWidget);
    expect(find.byKey(const ValueKey('quiz_end_rate')), findsOneWidget);
    expect(find.byKey(const ValueKey('quiz_end_back')), findsOneWidget);

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

  testWidgets('capture r45 quiz chrome screenshots', (tester) async {
    await captureInProgress(
      tester,
      size: const Size(390, 920),
      theme: AppTheme.light(),
      brightness: Brightness.light,
      outName: 'r45-narrow-light.png',
    );
    await captureInProgress(
      tester,
      size: const Size(390, 920),
      theme: AppTheme.dark(),
      brightness: Brightness.dark,
      outName: 'r45-narrow-dark.png',
    );
    await captureEnd(
      tester,
      size: const Size(390, 920),
      theme: AppTheme.light(),
      brightness: Brightness.light,
      outName: 'r45-end-narrow-light.png',
    );
  }, skip: !update, timeout: const Timeout(Duration(minutes: 3)));
}
