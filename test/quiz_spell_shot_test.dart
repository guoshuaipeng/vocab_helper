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

  Future<void> capture(
    WidgetTester tester, {
    required Size size,
    required ThemeData theme,
    required String outName,
    double keyboardInset = 0,
    String typed = '',
  }) async {
    SharedPreferences.setMockInitialValues({
      'quiz_variant': 'spell',
      'daily_goal': 5,
      'selected_book_id': 'pep-ps-3',
    });
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewInsets = FakeViewPadding(bottom: keyboardInset);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    final store = await ProgressStore.open();
    final questions = [
      QuizQuestion(
        target: w('a', 'apple', '苹果'),
        options: [w('a', 'apple', '苹果'), w('b', 'pear', '梨'), w('c', 'banana', '香蕉')],
        correctIndex: 0,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: withCjk(theme),
        home: RepaintBoundary(
          key: const ValueKey('shot_root'),
          child: Stack(
            children: [
              QuizScreen(
                store: store,
                repo: WordbookRepository(),
                mode: QuizMode.book,
                speaker: FakeWordSpeaker(),
                seedQuestions: questions,
                seedBookTitle: '人教版 · 三年级上',
              ),
              if (keyboardInset > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: keyboardInset,
                  child: Container(
                    color: const Color(0xFFD1D5DB),
                    alignment: Alignment.center,
                    child: const Text('键盘', style: TextStyle(fontSize: 18, color: Color(0xFF4B5563))),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
    expect(find.byKey(const ValueKey('quiz_spell_input')), findsOneWidget);
    if (typed.isNotEmpty) {
      await tester.enterText(find.byKey(const ValueKey('quiz_spell_input')), typed);
      await tester.pump();
    }
    if (keyboardInset > 0) {
      await tester.tap(find.byKey(const ValueKey('quiz_spell_input')));
      await tester.pump();
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
    'capture r26 spell screenshots',
    (tester) async {
      await capture(
        tester,
        size: const Size(390, 844),
        theme: AppTheme.light(),
        outName: 'r26-narrow-light.png',
        typed: 'app',
      );
      await capture(
        tester,
        size: const Size(390, 844),
        theme: AppTheme.dark(),
        outName: 'r26-narrow-dark.png',
        typed: 'app',
      );
      await capture(
        tester,
        size: const Size(1000, 844),
        theme: AppTheme.light(),
        outName: 'r26-wide-light.png',
        typed: 'app',
      );
      await capture(
        tester,
        size: const Size(1000, 844),
        theme: AppTheme.dark(),
        outName: 'r26-wide-dark.png',
        typed: 'app',
      );
      await capture(
        tester,
        size: const Size(390, 844),
        theme: AppTheme.light(),
        outName: 'r26-narrow-keyboard.png',
        typed: 'ap',
        keyboardInset: 320,
      );
    },
    skip: !update,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
