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
  final file = File(r'C:\Windows\Fonts\Deng.ttf');
  final bytes = await file.readAsBytes();
  final data = ByteData.sublistView(Uint8List.fromList(bytes));
  final loader = FontLoader('ShotCJK')..addFont(Future.value(data));
  await loader.load();
}

ThemeData withCjk(ThemeData base) {
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'ShotCJK'),
    primaryTextTheme: base.primaryTextTheme.apply(fontFamily: 'ShotCJK'),
  );
}

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
  }) async {
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-3',
      'daily_goal': 20,
      'learned_ids': ['pep-ps-3-1', 'pep-ps-3-2'],
      'today_count': 2,
      'streak_days': 3,
      'today_date': ProgressStore.dateKey(DateTime.now()),
    });

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = await ProgressStore.open();
    await tester.pumpWidget(
      MaterialApp(
        theme: withCjk(theme),
        home: Scaffold(
          body: RepaintBoundary(
            key: const ValueKey('shot_root'),
            child: MeScreen(
              key: ValueKey(outName),
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
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Scroll so 学习自测 card is in view
    final list = find.byType(Scrollable);
    if (list.evaluate().isNotEmpty) {
      await tester.drag(list.first, const Offset(0, -280));
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(find.byKey(const ValueKey('me_quiz_card_subtitle')), findsOneWidget);

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

  testWidgets('capture me-quiz-copy screenshots', (tester) async {
    await capture(
      tester,
      size: const Size(390, 920),
      theme: AppTheme.light(),
      outName: 'me-quiz-copy-narrow-light.png',
    );
    await capture(
      tester,
      size: const Size(390, 920),
      theme: AppTheme.dark(),
      outName: 'me-quiz-copy-narrow-dark.png',
    );
    await capture(
      tester,
      size: const Size(900, 700),
      theme: AppTheme.light(),
      outName: 'me-quiz-copy-wide.png',
    );
  }, skip: !update);
}
