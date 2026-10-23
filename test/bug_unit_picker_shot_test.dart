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

  Future<void> pumpLearn(WidgetTester tester, {String? unit}) async {
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-3',
      'daily_goal': 20,
      if (unit != null) 'unit_filter_pep-ps-3': unit,
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = await ProgressStore.open();
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('shot_root'),
        child: MaterialApp(
          theme: withCjk(AppTheme.light()),
          home: Scaffold(
            body: LearnScreen(
              store: store,
              repo: WordbookRepository(),
              bookId: 'pep-ps-3',
              onNeedSetup: () {},
              speaker: FakeWordSpeaker(),
              onStartQuiz: () {},
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      if (find.byKey(const ValueKey('unit_picker_button')).evaluate().isNotEmpty) break;
    }
  }

  Future<void> save(WidgetTester tester, String outName) async {
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
    'capture compact unit picker + sheet',
    (tester) async {
      await pumpLearn(tester, unit: '第1组');
      expect(find.byKey(const ValueKey('unit_picker_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('learn_known')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await save(tester, 'bug-unit-picker-compact-narrow-light.png');

      await tester.tap(find.byKey(const ValueKey('unit_picker_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('unit_picker_list')), findsOneWidget);
      await save(tester, 'bug-unit-picker-sheet-narrow-light.png');
    },
    skip: !update,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
