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
    String typed = '',
  }) async {
    SharedPreferences.setMockInitialValues({
      'quiz_variant': 'dictation',
      'daily_goal': 5,
      'selected_book_id': 'pep-ps-3',
    });
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = await ProgressStore.open();
    final questions = [
      QuizQuestion(
        target: w('a', 'apple', '苹果'),
        options: [
          w('a', 'apple', '苹果'),
          w('b', 'pear', '梨'),
          w('c', 'banana', '香蕉'),
        ],
        correctIndex: 0,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: withCjk(theme),
        home: RepaintBoundary(
          key: const ValueKey('shot_root'),
          child: QuizScreen(
            store: store,
            repo: WordbookRepository(),
            mode: QuizMode.book,
            speaker: FakeWordSpeaker(),
            seedQuestions: questions,
            seedBookTitle: '人教版 · 三年级上',
          ),
        ),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
    expect(find.byKey(const ValueKey('quiz_dictation_input')), findsOneWidget);
    if (typed.isNotEmpty) {
      await tester.enterText(find.byKey(const ValueKey('quiz_dictation_input')), typed);
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
    'capture r34 dictation screenshots',
    (tester) async {
      await capture(
        tester,
        size: const Size(390, 844),
        theme: AppTheme.light(),
        outName: 'r34-narrow-light.png',
        typed: 'app',
      );
      await capture(
        tester,
        size: const Size(390, 844),
        theme: AppTheme.dark(),
        outName: 'r34-narrow-dark.png',
        typed: 'app',
      );
      await capture(
        tester,
        size: const Size(1000, 844),
        theme: AppTheme.light(),
        outName: 'r34-wide-light.png',
        typed: 'app',
      );
      await capture(
        tester,
        size: const Size(1000, 844),
        theme: AppTheme.dark(),
        outName: 'r34-wide-dark.png',
        typed: 'app',
      );
      await capture(
        tester,
        size: const Size(390, 844),
        theme: AppTheme.light(),
        outName: 'r34-narrow-input.png',
        typed: 'ap',
      );
    },
    skip: !update,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
