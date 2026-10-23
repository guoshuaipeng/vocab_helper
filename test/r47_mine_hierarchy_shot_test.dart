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

Future<void> expandMeMore(WidgetTester tester) async {
  final more = find.byKey(const ValueKey('me_more_section'));
  expect(more, findsOneWidget);
  await tester.ensureVisible(more);
  final export = find.byKey(const ValueKey('export_progress'));
  if (export.evaluate().isNotEmpty) {
    try {
      if (tester.getSize(export).height > 1) return;
    } catch (_) {}
  }
  await tester.tap(more);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final update = Platform.environment['UPDATE_SHOTS'] == '1';

  setUpAll(() async {
    if (update) await loadCjkFont();
  });

  Future<void> capture(
    WidgetTester tester, {
    required ThemeData theme,
    required String outName,
    required bool expandMore,
  }) async {
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-3',
      'daily_goal': 20,
      'learned_ids': ['pep-ps-3-1', 'pep-ps-3-2'],
      'wrong_ids': ['pep-ps-3-3'],
      'today_count': 4,
      'streak_days': 3,
      'today_date': ProgressStore.dateKey(DateTime.now()),
      'day_count_${ProgressStore.dateKey(DateTime.now())}': 4,
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await ProgressStore.open();
    await tester.pumpWidget(MaterialApp(
      theme: withCjk(theme),
      builder: (context, child) => RepaintBoundary(
        key: const ValueKey('shot_root'),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: MeScreen(
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
          onPhotoVocab: () {},
        ),
      ),
    ));
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const ValueKey('me_hero')), findsOneWidget);
    expect(find.byKey(const ValueKey('me_actions')), findsOneWidget);
    expect(find.byKey(const ValueKey('me_more_section')), findsOneWidget);
    // Accent must not steal first screen when collapsed.
    expect(find.text('朗读口音'), findsNothing);
    if (expandMore) {
      await expandMeMore(tester);
      expect(find.text('朗读口音'), findsOneWidget);
      expect(find.byKey(const ValueKey('export_progress')), findsOneWidget);
      expect(find.byKey(const ValueKey('me_stats_summary')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('me_stats_summary')));
      await tester.pump(const Duration(milliseconds: 100));
    }
    if (update) {
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
  }

  testWidgets('r47_hero_narrow_light', (tester) async {
    await capture(tester, theme: AppTheme.light(), outName: 'r47-hero-narrow-light.png', expandMore: false);
  });

  testWidgets('r47_hero_narrow_dark', (tester) async {
    await capture(tester, theme: AppTheme.dark(), outName: 'r47-hero-narrow-dark.png', expandMore: false);
  });

  testWidgets('r47_more_expanded_narrow_light', (tester) async {
    await capture(
      tester,
      theme: AppTheme.light(),
      outName: 'r47-more-expanded-narrow-light.png',
      expandMore: true,
    );
  });
}
