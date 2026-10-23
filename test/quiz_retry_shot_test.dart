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

List<QuizQuestion> twoQuestions() => [
      QuizQuestion(
        target: w('a', 'apple', '苹果'),
        options: [
          w('a', 'apple', '苹果'),
          w('b', 'pear', '梨'),
          w('c', 'banana', '香蕉'),
          w('d', 'grape', '葡萄'),
        ],
        correctIndex: 0,
      ),
      QuizQuestion(
        target: w('b', 'pear', '梨'),
        options: [
          w('b', 'pear', '梨'),
          w('a', 'apple', '苹果'),
          w('c', 'banana', '香蕉'),
          w('d', 'grape', '葡萄'),
        ],
        correctIndex: 0,
      ),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final update = Platform.environment['UPDATE_SHOTS'] == '1';

  setUpAll(() async {
    if (update) await loadCjkFont();
  });

  Future<void> reachEndWithWrong(WidgetTester tester) async {
    // miss first (tap pear instead of apple), then correct second
    final buttons = find.byType(OutlinedButton);
    expect(buttons, findsWidgets);
    await tester.tap(buttons.at(1)); // wrong
    await tester.pump();
    await tester.tap(find.text('下一题'));
    await tester.pump();
    final buttons2 = find.byType(OutlinedButton);
    await tester.tap(buttons2.at(0)); // correct pear
    await tester.pump();
    await tester.tap(find.text('查看结果'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.textContaining('本轮自测完成'), findsOneWidget);
    expect(find.text('错题再练'), findsOneWidget);
  }

  Future<void> capture(
    WidgetTester tester, {
    required Size size,
    required ThemeData theme,
    required Brightness brightness,
    required String outName,
    required bool allCorrect,
    bool enterRetry = false,
  }) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    SharedPreferences.setMockInitialValues({
      'quiz_variant': 'meaning',
      'daily_goal': 5,
      'selected_book_id': 'pep-ps-3',
    });
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    final store = await ProgressStore.open();
    final themed = withCjk(theme);
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
              speaker: FakeWordSpeaker(),
              seedQuestions: twoQuestions(),
              seedBookTitle: '人教版 · 三年级上',
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }

    if (allCorrect) {
      await tester.tap(find.text('apple'));
      await tester.pump();
      await tester.tap(find.text('下一题'));
      await tester.pump();
      await tester.tap(find.text('pear'));
      await tester.pump();
      await tester.tap(find.text('查看结果'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.text('错题再练'), findsNothing);
      expect(find.text('回学习'), findsOneWidget);
    } else {
      await reachEndWithWrong(tester);
      if (enterRetry) {
        await tester.tap(find.byKey(const ValueKey('quiz_end_wrong_retry')));
        await tester.pump();
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 40));
        }
        expect(find.byKey(const ValueKey('quiz_retry_badge')), findsOneWidget);
      }
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
    'capture r35 screenshots',
    (tester) async {
      // end with wrongs — 4 themes
      await capture(tester,
          size: const Size(390, 920),
          theme: AppTheme.light(),
          brightness: Brightness.light,
          outName: 'r35-end-wrong-narrow-light.png',
          allCorrect: false);
      await capture(tester,
          size: const Size(390, 920),
          theme: AppTheme.dark(),
          brightness: Brightness.dark,
          outName: 'r35-end-wrong-narrow-dark.png',
          allCorrect: false);
      await capture(tester,
          size: const Size(1000, 920),
          theme: AppTheme.light(),
          brightness: Brightness.light,
          outName: 'r35-end-wrong-wide-light.png',
          allCorrect: false);
      await capture(tester,
          size: const Size(1000, 920),
          theme: AppTheme.dark(),
          brightness: Brightness.dark,
          outName: 'r35-end-wrong-wide-dark.png',
          allCorrect: false);
      // end all correct (no 错题再练)
      await capture(tester,
          size: const Size(390, 920),
          theme: AppTheme.light(),
          brightness: Brightness.light,
          outName: 'r35-end-ok-narrow-light.png',
          allCorrect: true);
      // retry in progress
      await capture(tester,
          size: const Size(390, 920),
          theme: AppTheme.light(),
          brightness: Brightness.light,
          outName: 'r35-retry-narrow-light.png',
          allCorrect: false,
          enterRetry: true);
    },
    skip: !update,
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
