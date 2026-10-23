import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/learn_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/word_speaker.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';
import 'package:vocab_helper/theme/app_theme.dart';
import 'package:vocab_helper/widgets/friendly_thumb.dart';

Future<void> _pumpLearn(WidgetTester tester) async {
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
  for (var i = 0; i < 80; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.byKey(const ValueKey('learn_known')).evaluate().isNotEmpty) {
      break;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('friendly thumb asset golden', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: FriendlyThumb(
              key: ValueKey('friendly_thumb_golden'),
              color: Color(0xFF2A9D8F),
              size: 160,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await expectLater(
      find.byKey(const ValueKey('friendly_thumb_golden')),
      matchesGoldenFile('goldens/friendly_thumb_up.png'),
    );
  });

  testWidgets('known flight marks learned; unknown press scale', (tester) async {
    await _pumpLearn(tester);
    expect(find.byKey(const ValueKey('learn_known_thumb_xform')), findsOneWidget);
    expect(find.byKey(const ValueKey('learn_unknown')), findsOneWidget);

    final store = (tester.widget(find.byType(LearnScreen)) as LearnScreen).store;
    final before = store.learnedIds().length;

    await tester.tap(find.byKey(const ValueKey('learn_known')));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(store.learnedIds().length, greaterThan(before));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await _pumpLearn(tester);
    final g = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('learn_unknown'))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(
      find.byType(AnimatedScale).evaluate().any((e) => (e.widget as AnimatedScale).scale == 0.98),
      isTrue,
    );
    await g.cancel();
  });
}
