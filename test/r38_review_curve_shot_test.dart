import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/learn_screen.dart';
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

  Future<void> captureLearn(
    WidgetTester tester, {
    required Size size,
    required ThemeData theme,
    required String outName,
  }) async {
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-3',
      'daily_goal': 50,
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
        key: ValueKey('app_$outName'),
        theme: withCjk(theme),
        home: RepaintBoundary(
          key: const ValueKey('shot_root'),
          child: Scaffold(
            body: LearnScreen(
              key: ValueKey('learn_$outName'),
              store: store,
              repo: WordbookRepository(),
              bookId: 'pep-ps-3',
              onNeedSetup: () {},
              speaker: FakeWordSpeaker(),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.tap(find.byKey(const ValueKey('learn_known')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    expect(find.byKey(const ValueKey('review_next_hint')), findsOneWidget);
    await saveShot(tester, outName);
  }

  Future<void> captureMe(
    WidgetTester tester, {
    required Size size,
    required ThemeData theme,
    required String outName,
  }) async {
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-3',
      'daily_goal': 20,
      'learned_ids': ['pep-ps-3-1', 'pep-ps-3-2'],
      'review_at_pep-ps-3-1': '2026-10-01',
      'review_at_pep-ps-3-2': '2026-10-05',
      'today_count': 3,
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
        key: ValueKey('app_$outName'),
        theme: withCjk(theme),
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
            speaker: FakeWordSpeaker(),
          ),
        ),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const ValueKey('me_review_curve_hint')), findsOneWidget);
    await saveShot(tester, outName);
  }

  testWidgets(
    'capture r38 review curve screenshots',
    (tester) async {
      await captureLearn(
        tester,
        size: const Size(390, 920),
        theme: AppTheme.light(),
        outName: 'r38-hint-narrow-light.png',
      );
      await captureLearn(
        tester,
        size: const Size(390, 920),
        theme: AppTheme.dark(),
        outName: 'r38-hint-narrow-dark.png',
      );
      await captureLearn(
        tester,
        size: const Size(900, 700),
        theme: AppTheme.light(),
        outName: 'r38-hint-wide-light.png',
      );
      await captureLearn(
        tester,
        size: const Size(900, 700),
        theme: AppTheme.dark(),
        outName: 'r38-hint-wide-dark.png',
      );
      await captureMe(
        tester,
        size: const Size(390, 920),
        theme: AppTheme.light(),
        outName: 'r38-me-narrow-light.png',
      );
      await captureMe(
        tester,
        size: const Size(390, 920),
        theme: AppTheme.dark(),
        outName: 'r38-me-narrow-dark.png',
      );
    },
    skip: !update,
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
