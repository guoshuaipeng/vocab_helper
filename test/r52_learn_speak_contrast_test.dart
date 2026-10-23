import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/learn_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/word_speaker.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';
import 'package:vocab_helper/theme/app_theme.dart';

/// R52 B02 — learn flashcard speak contrast. One testWidgets (prefs singleton).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpLearn(
    WidgetTester tester, {
    ThemeData? theme,
    Size size = const Size(390, 844),
  }) async {
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-3',
      'daily_goal': 20,
    });
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;

    final store = await ProgressStore.open();
    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        theme: theme ?? AppTheme.light(),
        home: Scaffold(
          appBar: AppBar(title: const Text('单词小助手')),
          body: LearnScreen(
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
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const ValueKey('learn_flash_card')).evaluate().isNotEmpty) {
        break;
      }
    }
    expect(find.byKey(const ValueKey('learn_flash_card')), findsOneWidget);
  }

  Color? speakFg(WidgetTester tester) {
    final iconFinder = find.descendant(
      of: find.byKey(const ValueKey('flashcard_speak')),
      matching: find.byIcon(Icons.volume_up),
    );
    expect(iconFinder, findsOneWidget);
    return IconTheme.of(tester.element(iconFinder)).color;
  }

  testWidgets('R52 speak onSurface + light disc; hotkey independent of flip', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final light = AppTheme.light();
    await pumpLearn(tester, theme: light);

    final speak = find.byKey(const ValueKey('flashcard_speak'));
    expect(speak, findsOneWidget);

    final btn = tester.widget<IconButton>(speak);
    expect(btn.onPressed, isNotNull);
    expect(btn.style, isNotNull, reason: 'styleFrom must set ButtonStyle');

    final fg = speakFg(tester);
    expect(fg, isNotNull);
    expect(fg, light.colorScheme.onSurface, reason: 'A1 idle speak = onSurface');
    expect(
      fg,
      isNot(light.colorScheme.onSurfaceVariant),
      reason: 'must leave weak onSurfaceVariant',
    );

    final bg = btn.style!.backgroundColor!.resolve(<WidgetState>{})!;
    expect(bg.a, closeTo(0.55, 0.02), reason: 'A3 light disc alpha');

    expect(find.byKey(const ValueKey('learn_wow_reveal_hint')), findsOneWidget);
    await tester.tap(speak);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('learn_wow_reveal_hint')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final dark = AppTheme.dark();
    await pumpLearn(tester, theme: dark);
    final fgDark = speakFg(tester);
    expect(fgDark, dark.colorScheme.onSurface);
    expect(fgDark, isNot(dark.colorScheme.onSurfaceVariant));
  });
}
