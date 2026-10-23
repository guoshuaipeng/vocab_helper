import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/books_screen.dart';
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
      'selected_book_id': 'pep-ps-4',
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
            child: BooksScreen(
              store: store,
              repo: WordbookRepository(),
              selectedBookId: 'pep-ps-4',
              onChangeBook: () {},
              onBookSelected: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Ensure pep-ps-4 card text is in view
    final label = find.textContaining('扩充词表');
    expect(label, findsWidgets);
    await tester.ensureVisible(label.first);
    await tester.pump(const Duration(milliseconds: 200));

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

  testWidgets(
    'capture r27 catalog screenshots',
    (tester) async {
      await capture(
        tester,
        size: const Size(390, 920),
        theme: AppTheme.light(),
        outName: 'r27-catalog-narrow-light.png',
      );
      await capture(
        tester,
        size: const Size(390, 920),
        theme: AppTheme.dark(),
        outName: 'r27-catalog-narrow-dark.png',
      );
      await capture(
        tester,
        size: const Size(1000, 920),
        theme: AppTheme.light(),
        outName: 'r27-catalog-wide-light.png',
      );
      await capture(
        tester,
        size: const Size(1000, 920),
        theme: AppTheme.dark(),
        outName: 'r27-catalog-wide-dark.png',
      );
    },
    skip: !update,
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets('pep-ps-4 card shows expanded count and sourceLabel', (tester) async {
    SharedPreferences.setMockInitialValues({'selected_book_id': 'pep-ps-4'});
    tester.view.physicalSize = const Size(390, 920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = await ProgressStore.open();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: BooksScreen(
            store: store,
            repo: WordbookRepository(),
            selectedBookId: 'pep-ps-4',
            onChangeBook: () {},
            onBookSelected: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    // Scroll a bit — ListView may not lay out far children until scrolled.
    final list = find.byType(Scrollable);
    expect(list, findsWidgets);
    var found = false;
    for (var i = 0; i < 12; i++) {
      if (find.textContaining('扩充词表').evaluate().isNotEmpty &&
          find.textContaining('共 243 词').evaluate().isNotEmpty) {
        found = true;
        break;
      }
      await tester.drag(list.first, const Offset(0, -280));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(found, isTrue, reason: 'pep-ps-4 card with 扩充词表 / 243 not found after scroll');
  });
}
