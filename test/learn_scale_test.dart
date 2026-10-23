import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/learn_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/word_speaker.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';
import 'package:vocab_helper/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('unknown press scale; known elastic stretch Transform', (tester) async {
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-3',
      'daily_goal': 20,
    });
    tester.view.physicalSize = const Size(390, 920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = await ProgressStore.open();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: LearnScreen(
            store: store,
            repo: WordbookRepository(),
            bookId: 'pep-ps-3',
            onNeedSetup: () {},
            speaker: FakeWordSpeaker(),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 40));
    });
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const ValueKey('learn_known')).evaluate().isNotEmpty) break;
    }

    expect(find.byKey(const ValueKey('learn_known')), findsOneWidget);
    expect(find.byKey(const ValueKey('learn_unknown')), findsOneWidget);

    // 不认识: still soft AnimatedScale press.
    final scales = find.byType(AnimatedScale);
    expect(scales, findsWidgets);
    final gUnknown = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('learn_unknown'))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(
      scales.evaluate().any((e) => (e.widget as AnimatedScale).scale == 0.98),
      isTrue,
      reason: 'unknown should press-scale to 0.98',
    );
    await gUnknown.up();
    await tester.pump();

    // 认识: elastic Transform stretches (sy > 1) mid animation.
    await tester.tap(find.byKey(const ValueKey('learn_known')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final transforms = find.byType(Transform);
    var stretched = false;
    for (final e in transforms.evaluate()) {
      final m = (e.widget as Transform).transform;
      final sy = m.entry(1, 1);
      if (sy > 1.05) {
        stretched = true;
        break;
      }
    }
    expect(stretched, isTrue, reason: 'known thumb should elongate (sy>1)');
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pump(const Duration(milliseconds: 300));
  });
}
