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

  testWidgets('know/unknown wrapped in AnimatedScale 0.98 on press', (tester) async {
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
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.byKey(const ValueKey('learn_known')), findsOneWidget);
    expect(find.byKey(const ValueKey('learn_unknown')), findsOneWidget);

    final scales = find.byType(AnimatedScale);
    expect(scales, findsWidgets);

    // Press known: scale goes to 0.98
    final gesture = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('learn_known'))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    AnimatedScale? pressed;
    for (final e in scales.evaluate()) {
      final w = e.widget as AnimatedScale;
      if (w.scale == 0.98) {
        pressed = w;
        break;
      }
    }
    expect(pressed, isNotNull, reason: 'expected AnimatedScale 0.98 while pressed');
    expect(pressed!.duration, const Duration(milliseconds: 150));

    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
  });
}
