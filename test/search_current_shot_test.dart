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

  Future<void> capture(
    WidgetTester tester, {
    required Size size,
    required ThemeData theme,
    required String outName,
  }) async {
    SharedPreferences.setMockInitialValues({'selected_book_id': 'pep-ps-3'});
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
            body: BooksScreen(
              key: ValueKey('books_$outName'),
              store: store,
              repo: WordbookRepository(),
              selectedBookId: 'pep-ps-3',
              onChangeBook: () {},
              onBookSelected: () {},
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    final title = find.textContaining('三年级');
    expect(title, findsWidgets);
    await tester.ensureVisible(title.first);
    await tester.pump();
    await tester.tap(title.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('已经是这本'), findsOneWidget);

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

  testWidgets(
    'capture search-current screenshots',
    (tester) async {
      await capture(tester, size: const Size(390, 920), theme: AppTheme.light(), outName: 'search-current-narrow-light.png');
      await capture(tester, size: const Size(390, 920), theme: AppTheme.dark(), outName: 'search-current-narrow-dark.png');
      await capture(tester, size: const Size(1000, 920), theme: AppTheme.light(), outName: 'search-current-wide.png');
    },
    skip: !update,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
