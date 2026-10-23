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
import 'package:vocab_helper/services/wordbook_repository.dart';
import 'package:vocab_helper/services/word_speaker.dart';
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
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    SharedPreferences.setMockInitialValues(prefs);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
            speaker: FakeWordSpeaker()..voiceAvailable = true,
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

  testWidgets('capture r39 wrong-book screenshots', (tester) async {
    await pumpMe(
      tester,
      size: const Size(390, 844),
      theme: AppTheme.light(),
      outName: 'r39-entry-narrow-light.png',
      prefs: wrongPrefs(),
    );
    final entry = find.byKey(const ValueKey('me_wrong_book_entry'));
    await tester.scrollUntilVisible(entry, 200, scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(milliseconds: 100));
    await saveShot(tester, 'r39-entry-narrow-light.png');

    for (final cfg in [
      (const Size(390, 844), AppTheme.light(), 'r39-sheet-narrow-light.png'),
      (const Size(390, 844), AppTheme.dark(), 'r39-sheet-narrow-dark.png'),
      (const Size(1000, 900), AppTheme.light(), 'r39-sheet-wide-light.png'),
      (const Size(1000, 900), AppTheme.dark(), 'r39-sheet-wide-dark.png'),
    ]) {
      await pumpMe(tester, size: cfg.$1, theme: cfg.$2, outName: cfg.$3, prefs: wrongPrefs());
      final e = find.byKey(const ValueKey('me_wrong_book_entry'));
      await tester.scrollUntilVisible(e, 200, scrollable: find.byType(Scrollable).first);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(e);
      await tester.pump();
      for (var i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.byKey(const ValueKey('wrong_book_review')).evaluate().isNotEmpty) break;
      }
      expect(find.byKey(const ValueKey('wrong_book_review')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('wrong_book_review')));
      await tester.pump(const Duration(milliseconds: 100));
      await saveShot(tester, cfg.$3);
    }

    await pumpMe(
      tester,
      size: const Size(390, 844),
      theme: AppTheme.light(),
      outName: 'r39-empty-narrow-light.png',
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
    await saveShot(tester, 'r39-empty-narrow-light.png');
  }, skip: !update, timeout: const Timeout(Duration(minutes: 5)));
}