import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/me_screen.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final update = Platform.environment['UPDATE_SHOTS'] == '1';

  setUpAll(() async {
    if (update) await loadCjkFont();
  });

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

  Map<String, Object> wrongPrefs() => {
        'selected_book_id': 'pep-ps-3',
        'wrong_ids': ['pep-ps-3-3', 'pep-ps-3-1', 'pep-ps-3-2'],
        'daily_goal': 20,
        'today_count': 2,
        'streak_days': 3,
        'today_date': ProgressStore.dateKey(DateTime.now()),
      };

  Map<String, Object> emptyPrefs() => {
        'selected_book_id': 'pep-ps-3',
        'daily_goal': 20,
        'today_count': 0,
        'streak_days': 0,
        'today_date': ProgressStore.dateKey(DateTime.now()),
      };

  Future<void> pumpMe(
    WidgetTester tester, {
    required Size size,
    required ThemeData theme,
    required String outName,
    required Map<String, Object> prefs,
  }) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    SharedPreferences.setMockInitialValues(prefs);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await ProgressStore.open();
    final themed = withCjk(theme);
    await tester.pumpWidget(
      MaterialApp(
        key: ValueKey('app_$outName'),
        theme: themed,
        darkTheme: themed,
        themeMode: theme.brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
        builder: (context, child) => RepaintBoundary(
          key: const ValueKey('shot_root'),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: MeScreen(
            key: ValueKey('me_$outName'),
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
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<ProgressStore> openWrongQuizStore(List<String> wrongIds) async {
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

  Future<void> captureLockedQuiz(
    WidgetTester tester, {
    required Size size,
    required ThemeData theme,
    required Brightness brightness,
    required String outName,
  }) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    const ids = [
      'pep-ps-4-1',
      'pep-ps-4-2',
      'pep-ps-4-3',
      'pep-ps-4-4',
    ];
    final store = await openWrongQuizStore(ids);
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
              mode: QuizMode.wrong,
              speaker: FakeWordSpeaker()..voiceAvailable = true,
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const ValueKey('quiz_pool_locked')).evaluate().isNotEmpty) break;
    }
    expect(find.byKey(const ValueKey('quiz_pool_locked')), findsOneWidget);
    await saveShot(tester, outName);
  }

  testWidgets('capture r46 wrong→quiz loop screenshots', (tester) async {
    // Sheet with words — primary 测这些
    await pumpMe(
      tester,
      size: const Size(390, 844),
      theme: AppTheme.light(),
      outName: 'r46-sheet-narrow-light.png',
      prefs: wrongPrefs(),
    );
    final entry = find.byKey(const ValueKey('me_wrong_book_entry'));
    await tester.scrollUntilVisible(entry, 200, scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(entry);
    await tester.pump();
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const ValueKey('wrong_book_quiz')).evaluate().isNotEmpty) break;
    }
    expect(find.byKey(const ValueKey('wrong_book_quiz')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const ValueKey('wrong_book_quiz')), matching: find.text('测这些')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('wrong_book_quiz')));
    await tester.pump(const Duration(milliseconds: 100));
    await saveShot(tester, 'r46-sheet-narrow-light.png');

    // Empty sheet
    await pumpMe(
      tester,
      size: const Size(390, 844),
      theme: AppTheme.light(),
      outName: 'r46-sheet-empty-narrow-light.png',
      prefs: emptyPrefs(),
    );
    final e2 = find.byKey(const ValueKey('me_wrong_book_entry'));
    await tester.scrollUntilVisible(e2, 200, scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(e2);
    await tester.pump();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const ValueKey('wrong_book_empty')).evaluate().isNotEmpty) break;
    }
    expect(find.byKey(const ValueKey('wrong_book_empty')), findsOneWidget);
    expect(find.byKey(const ValueKey('wrong_book_learn_new')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('wrong_book_learn_new')));
    await tester.pump(const Duration(milliseconds: 100));
    await saveShot(tester, 'r46-sheet-empty-narrow-light.png');

    // Locked quiz light + dark
    await captureLockedQuiz(
      tester,
      size: const Size(390, 844),
      theme: AppTheme.light(),
      brightness: Brightness.light,
      outName: 'r46-quiz-locked-narrow-light.png',
    );
    await captureLockedQuiz(
      tester,
      size: const Size(390, 844),
      theme: AppTheme.dark(),
      brightness: Brightness.dark,
      outName: 'r46-quiz-locked-narrow-dark.png',
    );
  }, skip: !update, timeout: const Timeout(Duration(minutes: 5)));
}
