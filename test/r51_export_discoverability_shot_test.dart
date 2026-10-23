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
  if (!values.containsKey('learned_ids')) {
    await prefs.setStringList('learned_ids', <String>[]);
  }
  if (!values.containsKey('wrong_ids')) {
    await prefs.setStringList('wrong_ids', <String>[]);
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

  Future<void> pumpMe(
    WidgetTester tester, {
    required Size size,
    required ThemeData theme,
    required Map<String, Object> prefs,
  }) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final store = await openStore(prefs);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: withCjk(theme),
        builder: (context, child) => RepaintBoundary(
          key: const ValueKey('shot_root'),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: MeScreen(
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
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> openExport(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const ValueKey('export_progress')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('export_progress')));
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const ValueKey('export_preview')).evaluate().isNotEmpty) break;
    }
    expect(find.byKey(const ValueKey('export_preview')), findsOneWidget);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  }

  testWidgets(
    'capture r51 export discoverability shots',
    (tester) async {
      final today = ProgressStore.dateKey(DateTime.now());
      final withProgress = <String, Object>{
        'selected_book_id': 'pep-ps-3',
        'learned_ids': <String>['pep-ps-3-1'],
        'wrong_ids': <String>['pep-ps-3-2'],
        'streak_days': 2,
        'daily_goal': 20,
        'today_count': 3,
        'today_date': today,
        'day_count_$today': 3,
      };
      final emptyProgress = <String, Object>{
        'selected_book_id': 'pep-ps-3',
        'learned_ids': <String>[],
        'wrong_ids': <String>[],
        'streak_days': 0,
        'daily_goal': 20,
        'today_count': 0,
        'today_date': today,
      };

      await pumpMe(
        tester,
        size: const Size(390, 1000),
        theme: AppTheme.light(),
        prefs: withProgress,
      );
      expect(find.byKey(const ValueKey('export_progress')), findsOneWidget);
      expect(find.text('朗读口音'), findsNothing);
      final scrollables = find.byType(Scrollable);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('me_export_row')),
        120,
        scrollable: scrollables.first,
      );
      await tester.pumpAndSettle();
      await dump(tester, 'r51-export-entry-narrow-light.png');

      await pumpMe(
        tester,
        size: const Size(390, 1000),
        theme: AppTheme.dark(),
        prefs: withProgress,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('me_export_row')),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await dump(tester, 'r51-export-entry-narrow-dark.png');

      await pumpMe(
        tester,
        size: const Size(390, 1100),
        theme: AppTheme.light(),
        prefs: emptyProgress,
      );
      await openExport(tester);
      expect(find.byKey(const ValueKey('export_empty_hint')), findsOneWidget);
      await dump(tester, 'r51-export-empty-sheet-narrow-light.png');

      await pumpMe(
        tester,
        size: const Size(390, 1100),
        theme: AppTheme.light(),
        prefs: withProgress,
      );
      await openExport(tester);
      expect(find.byKey(const ValueKey('export_empty_hint')), findsNothing);
      expect(find.byKey(const ValueKey('export_copy')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('export_copy')));
      await dump(tester, 'r51-export-sheet-narrow-light.png');
    },
    skip: !update,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
