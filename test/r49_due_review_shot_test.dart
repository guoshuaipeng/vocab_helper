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

  Future<void> pumpMe(
    WidgetTester tester, {
    required Size size,
    required ThemeData theme,
    required String outName,
    required Map<String, Object> prefs,
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
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

  Map<String, Object> duePrefs() => {
        'selected_book_id': 'pep-ps-3',
        'learned_ids': ['pep-ps-3-1', 'pep-ps-3-2', 'pep-ps-3-3'],
        'review_at_pep-ps-3-1': '2026-10-01',
        'review_at_pep-ps-3-2': '2026-10-05',
        'review_at_pep-ps-3-3': '2026-10-08',
        'daily_goal': 20,
        'today_count': 2,
        'streak_days': 3,
        'today_date': ProgressStore.dateKey(DateTime.now()),
      };

  Map<String, Object> emptyPrefs() => {
        'selected_book_id': 'pep-ps-3',
        'learned_ids': ['pep-ps-3-1'],
        'review_at_pep-ps-3-1': '2099-06-01',
        'daily_goal': 20,
        'today_count': 0,
        'streak_days': 0,
        'today_date': ProgressStore.dateKey(DateTime.now()),
      };

  testWidgets('capture r49 due-review start screenshots', (tester) async {
    await pumpMe(
      tester,
      size: const Size(390, 920),
      theme: AppTheme.light(),
      outName: 'r49-hero-due-narrow-light.png',
      prefs: duePrefs(),
    );
    expect(find.byKey(const ValueKey('me_due_go')), findsOneWidget);
    expect(find.byKey(const ValueKey('me_due_action')), findsOneWidget);
    await saveShot(tester, 'r49-hero-due-narrow-light.png');

    for (final cfg in [
      (const Size(390, 920), AppTheme.light(), 'r49-sheet-narrow-light.png'),
      (const Size(390, 920), AppTheme.dark(), 'r49-sheet-narrow-dark.png'),
    ]) {
      await pumpMe(tester, size: cfg.$1, theme: cfg.$2, outName: cfg.$3, prefs: duePrefs());
      await tester.tap(find.byKey(const ValueKey('me_due_review')));
      await tester.pump();
      for (var i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.byKey(const ValueKey('due_review_start')).evaluate().isNotEmpty) break;
      }
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('到期复习'), findsOneWidget);
      expect(find.byKey(const ValueKey('due_review_subtitle')), findsOneWidget);
      expect(find.byKey(const ValueKey('due_review_start')), findsOneWidget);
      final startY = tester.getTopLeft(find.byKey(const ValueKey('due_review_start'))).dy;
      final listY = tester.getTopLeft(find.byKey(const ValueKey('due_review_list'))).dy;
      expect(startY < listY, isTrue);
      await saveShot(tester, cfg.$3);
    }

    await pumpMe(
      tester,
      size: const Size(390, 920),
      theme: AppTheme.light(),
      outName: 'r49-empty-narrow-light.png',
      prefs: emptyPrefs(),
    );
    await tester.tap(find.byKey(const ValueKey('me_due_review')));
    await tester.pump();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const ValueKey('due_review_empty')).evaluate().isNotEmpty) break;
    }
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('due_review_empty')), findsOneWidget);
    expect(find.byKey(const ValueKey('due_review_empty_hint')), findsOneWidget);
    await saveShot(tester, 'r49-empty-narrow-light.png');
  }, skip: !update, timeout: const Timeout(Duration(minutes: 5)));
}
