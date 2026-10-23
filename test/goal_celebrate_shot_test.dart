import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/models/word.dart';
import 'package:vocab_helper/screens/me_screen.dart';
import 'package:vocab_helper/screens/quiz_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/quiz_engine.dart';
import 'package:vocab_helper/services/word_speaker.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';
import 'package:vocab_helper/theme/app_theme.dart';
import 'package:vocab_helper/widgets/goal_celebrate_banner.dart';

Future<void> loadCjkFont() async {
  final bytes = await File(r'C:\Windows\Fonts\Deng.ttf').readAsBytes();
  final data = ByteData.sublistView(Uint8List.fromList(bytes));
  await (FontLoader('ShotCJK')..addFont(Future.value(data))).load();
}

ThemeData withCjk(ThemeData base) => base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: 'ShotCJK'),
      primaryTextTheme: base.primaryTextTheme.apply(fontFamily: 'ShotCJK'),
    );

Future<ProgressStore> openStore(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  for (final e in values.entries) {
    final v = e.value;
    if (v is String) {
      await prefs.setString(e.key, v);
    } else if (v is int) {
      await prefs.setInt(e.key, v);
    } else if (v is bool) {
      await prefs.setBool(e.key, v);
    } else if (v is List<String>) {
      await prefs.setStringList(e.key, v);
    }
  }
  if (!values.containsKey('goal_celebrated_ymd')) {
    await prefs.remove('goal_celebrated_ymd');
  }
  return ProgressStore(prefs);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final update = Platform.environment['UPDATE_SHOTS'] == '1';

  setUpAll(() async {
    if (update) await loadCjkFont();
  });

  Future<void> dump(WidgetTester tester, String outName) async {
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

  Future<void> captureMe(
    WidgetTester tester, {
    required Size size,
    required ThemeData theme,
    required Brightness brightness,
    required String outName,
  }) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
    final today = ProgressStore.dateKey(DateTime.now());
    final store = await openStore({
      'selected_book_id': 'pep-ps-4',
      'daily_goal': 20,
      'today_count': 20,
      'today_date': today,
      'day_count_$today': 20,
      'streak_days': 3,
    });
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

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
            child: MeScreen(
              store: store,
              repo: WordbookRepository(),
              onRefresh: () {},
              onChangeBook: () {},
              onReviewWrong: () {},
              onReviewWrongCurrentUnit: () {},
              onQuizBook: () {},
              onQuizUnit: () {},
              onQuizWrong: () {},
              onStartDueReview: () {},
              speaker: FakeWordSpeaker()..voiceAvailable = true,
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await dump(tester, outName);
  }

  Future<void> captureBanner(
    WidgetTester tester, {
    required Size size,
    required ThemeData theme,
    required Brightness brightness,
    required String outName,
  }) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
    final today = ProgressStore.dateKey(DateTime.now());
    final store = await openStore({
      'selected_book_id': 'pep-ps-4',
      'quiz_variant': 'meaning',
      'daily_goal': 5,
      'today_count': 5,
      'today_date': today,
    });
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    final themed = withCjk(theme);
    final questions = [
      QuizQuestion(
        target: Word(id: 'a', word: 'apple', meaning: '苹果', unit: 'U1'),
        options: [
          Word(id: 'a', word: 'apple', meaning: '苹果', unit: 'U1'),
          Word(id: 'b', word: 'pear', meaning: '梨', unit: 'U1'),
          Word(id: 'c', word: 'banana', meaning: '香蕉', unit: 'U1'),
          Word(id: 'd', word: 'grape', meaning: '葡萄', unit: 'U1'),
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
              seedBookTitle: '人教版PEP · 四年级',
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    // Force-show banner for shot (already at goal; rising edge already passed).
    showGoalCelebratedBanner(tester.element(find.byType(QuizScreen)), count: 5, goal: 5, autoHide: Duration.zero);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await dump(tester, outName);
    final quizCtx = tester.element(find.byType(QuizScreen));
    ScaffoldMessenger.of(quizCtx).hideCurrentMaterialBanner();
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('capture r33 goal celebrate screenshots', (tester) async {
    await captureMe(
      tester,
      size: const Size(390, 920),
      theme: AppTheme.light(),
      brightness: Brightness.light,
      outName: 'r33-me-done-narrow-light.png',
    );
    await captureMe(
      tester,
      size: const Size(390, 920),
      theme: AppTheme.dark(),
      brightness: Brightness.dark,
      outName: 'r33-me-done-narrow-dark.png',
    );
    await captureMe(
      tester,
      size: const Size(900, 700),
      theme: AppTheme.light(),
      brightness: Brightness.light,
      outName: 'r33-me-done-wide-light.png',
    );
    await captureMe(
      tester,
      size: const Size(900, 700),
      theme: AppTheme.dark(),
      brightness: Brightness.dark,
      outName: 'r33-me-done-wide-dark.png',
    );
    await captureBanner(
      tester,
      size: const Size(390, 920),
      theme: AppTheme.light(),
      brightness: Brightness.light,
      outName: 'r33-banner-narrow-light.png',
    );
    await captureBanner(
      tester,
      size: const Size(390, 920),
      theme: AppTheme.dark(),
      brightness: Brightness.dark,
      outName: 'r33-banner-narrow-dark.png',
    );
  }, skip: !update);
}
