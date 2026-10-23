import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/learn_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/word_speaker.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';
import 'package:vocab_helper/theme/app_theme.dart';

Future<void> loadCjkFont() async {
  final bytes = await File(r'C:\Windows\Fonts\Deng.ttf').readAsBytes();
  final data = ByteData.sublistView(Uint8List.fromList(bytes));
  await (FontLoader('ShotCJK')..addFont(Future.value(data))).load();
}

Future<void> loadMaterialIconsFont() async {
  final path =
      r'C:\Users\user\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf';
  final bytes = await File(path).readAsBytes();
  final data = ByteData.sublistView(Uint8List.fromList(bytes));
  await (FontLoader('MaterialIcons')..addFont(Future.value(data))).load();
}

ThemeData withCjk(ThemeData base) => base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: 'ShotCJK'),
      primaryTextTheme: base.primaryTextTheme.apply(fontFamily: 'ShotCJK'),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadCjkFont();
    await loadMaterialIconsFont();
  });

  Future<void> pumpLearn(
    WidgetTester tester, {
    required ThemeData theme,
    required String keyTag,
  }) async {
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-3',
      'daily_goal': 20,
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    final store = await ProgressStore.open();
    await tester.pumpWidget(
      MaterialApp(
        key: ValueKey('app_$keyTag'),
        theme: withCjk(theme),
        builder: (context, child) => RepaintBoundary(
          key: const ValueKey('shot_root'),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          appBar: AppBar(title: const Text('单词小助手')),
          body: LearnScreen(
            key: ValueKey('learn_$keyTag'),
            store: store,
            repo: WordbookRepository(),
            bookId: 'pep-ps-3',
            onNeedSetup: () {},
            speaker: FakeWordSpeaker(),
            onStartQuiz: () {},
            onLearnNew: () {},
            onReviewWrongAll: () {},
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 40));
    });
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      if (find.byKey(const ValueKey('learn_flash_card')).evaluate().isNotEmpty) break;
    }
    expect(find.byKey(const ValueKey('learn_flash_card')), findsOneWidget);
  }

  Future<void> saveShot(WidgetTester tester, String outName) async {
    await tester.runAsync(() async {
      final boundary = tester.renderObject(find.byKey(const ValueKey('shot_root')))
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final out = File('docs/shots/$outName');
      await out.parent.create(recursive: true);
      await out.writeAsBytes(bytes!.buffer.asUint8List());
    });
  }

  testWidgets('R48 unit first in overflow + persistent chrome + shots', (tester) async {
    await pumpLearn(tester, theme: AppTheme.light(), keyTag: 'r48_light');

    await tester.tap(find.byKey(const ValueKey('learn_overflow_menu')));
    await tester.pumpAndSettle();

    final unitBtn = find.byKey(const ValueKey('unit_picker_button'));
    final learnBtn = find.byKey(const ValueKey('today_task_learn'));
    expect(unitBtn, findsOneWidget);
    expect(learnBtn, findsOneWidget);
    expect(tester.getTopLeft(unitBtn).dy, lessThan(tester.getTopLeft(learnBtn).dy));

    await saveShot(tester, 'r48-overflow-narrow-light.png');

    await tester.tap(unitBtn);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('unit_picker_row_第1组')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('unit_filter_hint')), findsOneWidget);
    expect(find.textContaining('已筛选 · 第1组'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byKey(const ValueKey('learn_known')), findsOneWidget);
    expect(find.byKey(const ValueKey('learn_unknown')), findsOneWidget);
    expect(find.textContaining('第1组'), findsWidgets);

    await saveShot(tester, 'r48-filtered-narrow-light.png');

    await tester.tap(find.byKey(const ValueKey('learn_overflow_menu')));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('unit_picker_button'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const ValueKey('today_task_learn'))).dy),
    );
    // dismiss sheet
    Navigator.of(tester.element(find.text('更多练习'))).pop();
    await tester.pumpAndSettle();

    await pumpLearn(tester, theme: AppTheme.dark(), keyTag: 'r48_dark');
    await tester.tap(find.byKey(const ValueKey('learn_overflow_menu')));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('unit_picker_button'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const ValueKey('today_task_learn'))).dy),
    );
    await saveShot(tester, 'r48-overflow-narrow-dark.png');
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
