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

  testWidgets(
    'capture r36 catalog narrow-light (hj-ox-7a-2024)',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'selected_book_id': 'hj-ox-7a-2024',
      });

      tester.view.physicalSize = const Size(390, 920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final store = await ProgressStore.open();
      await tester.pumpWidget(
        MaterialApp(
          theme: withCjk(AppTheme.light()),
          home: Scaffold(
            body: RepaintBoundary(
              key: const ValueKey('shot_root'),
              child: BooksScreen(
                store: store,
                repo: WordbookRepository(),
                selectedBookId: 'hj-ox-7a-2024',
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

      final list = find.byType(Scrollable);
      expect(list, findsWidgets);
      var found = false;
      for (var i = 0; i < 16; i++) {
        if (find.textContaining('2024六三').evaluate().isNotEmpty ||
            find.textContaining('沪教牛津 · 七年级上（2024）').evaluate().isNotEmpty) {
          found = true;
          break;
        }
        await tester.drag(list.first, const Offset(0, -280));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(found, isTrue, reason: 'hj-ox-7a-2024 card not found');

      final label = find.textContaining('2024六三');
      if (label.evaluate().isNotEmpty) {
        await tester.ensureVisible(label.first);
        await tester.pump(const Duration(milliseconds: 200));
      }

      await tester.runAsync(() async {
        final boundary = tester.renderObject(find.byKey(const ValueKey('shot_root')))
            as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1.5);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final out = File('docs/shots/r36-catalog-narrow-light.png');
        await out.parent.create(recursive: true);
        await out.writeAsBytes(bytes!.buffer.asUint8List());
      });
    },
    skip: !update,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
