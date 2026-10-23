import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/photo_vocab_screen.dart';
import 'package:vocab_helper/services/custom_word_overlay.dart';
import 'package:vocab_helper/services/ocr_word_extract.dart';
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

  List<OcrWordCandidate> fixtureCands() => [
        OcrWordCandidate(
          spelling: 'apple',
          meaning: '苹果',
          kind: OcrMatchKind.inBook,
          bookWordId: 'x1',
          selected: false,
        ),
        OcrWordCandidate(
          spelling: 'kangaroo',
          meaning: '袋鼠',
          kind: OcrMatchKind.newWord,
          selected: true,
        ),
        OcrWordCandidate(
          spelling: 'notebook',
          meaning: '',
          kind: OcrMatchKind.newWord,
          selected: true,
        ),
      ];

  Future<void> pumpConfirm(
    WidgetTester tester, {
    required Size size,
    required ThemeData theme,
    required String outName,
  }) async {
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-3',
      'daily_goal': 20,
    });
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final store = await ProgressStore.open();
    final repo = WordbookRepository();
    repo.overlay = await CustomWordOverlay.open();
    await tester.pumpWidget(
      MaterialApp(
        key: ValueKey('app_$outName'),
        theme: withCjk(theme),
        home: RepaintBoundary(
          key: const ValueKey('shot_root'),
          child: PhotoVocabScreen(
            key: ValueKey('photo_$outName'),
            store: store,
            repo: repo,
            bookId: 'pep-ps-3',
            initialCandidates: fixtureCands(),
          ),
        ),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const ValueKey('photo_vocab_confirm')), findsOneWidget);
    expect(find.text('kangaroo'), findsOneWidget);
    if (update) await saveShot(tester, outName);
  }

  testWidgets('r37 confirm narrow light', (tester) async {
    await pumpConfirm(
      tester,
      size: const Size(390, 844),
      theme: AppTheme.light(),
      outName: 'r37-confirm-narrow-light.png',
    );
  });

  testWidgets('r37 confirm narrow dark', (tester) async {
    await pumpConfirm(
      tester,
      size: const Size(390, 844),
      theme: AppTheme.dark(),
      outName: 'r37-confirm-narrow-dark.png',
    );
  });

  testWidgets('r37 confirm wide light', (tester) async {
    await pumpConfirm(
      tester,
      size: const Size(900, 700),
      theme: AppTheme.light(),
      outName: 'r37-confirm-wide-light.png',
    );
  });

  testWidgets('r37 source + join flow (paste path logic)', (tester) async {
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-3',
      'daily_goal': 20,
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await ProgressStore.open();
    final repo = WordbookRepository();
    repo.overlay = await CustomWordOverlay.open();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: PhotoVocabScreen(
          store: store,
          repo: repo,
          bookId: 'pep-ps-3',
          initialCandidates: [
            OcrWordCandidate(
              spelling: 'giraffe',
              meaning: '长颈鹿',
              kind: OcrMatchKind.newWord,
              selected: true,
            ),
          ],
        ),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    // Create new unit
    await tester.tap(find.byKey(const ValueKey('photo_vocab_new_unit')));
    await tester.pump();
    await tester.enterText(find.byKey(const ValueKey('photo_vocab_new_unit_field')), '我的拍照');
    await tester.tap(find.byKey(const ValueKey('photo_vocab_join')));
    await tester.pump();
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const ValueKey('photo_vocab_done')), findsOneWidget);
    final overlayWords = await repo.overlay!.wordsForBook('pep-ps-3');
    expect(overlayWords.any((w) => w.word == 'giraffe' && w.unit == '我的拍照'), isTrue);
    expect(store.unitFilterForBook('pep-ps-3'), '我的拍照');
  });
}
