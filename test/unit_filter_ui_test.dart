import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/learn_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/word_speaker.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-3',
      'daily_goal': 20,
    });
  });

  Future<void> pumpLearn(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = await ProgressStore.open();
    await tester.pumpWidget(
      MaterialApp(
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
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 40));
    });
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      if (find.byKey(const ValueKey('learn_overflow_menu')).evaluate().isNotEmpty) {
        break;
      }
    }
  }

  testWidgets('compact unit picker via overflow; sheet lists units; quiet hint', (tester) async {
    await pumpLearn(tester);

    expect(find.byKey(const ValueKey('unit_picker_button')), findsNothing);
    expect(find.text('第1组'), findsNothing);
    expect(find.byKey(const ValueKey('learn_known')), findsOneWidget);
    expect(find.byKey(const ValueKey('learn_unknown')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('learn_overflow_menu')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('unit_picker_button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('unit_picker_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('unit_picker_list')), findsOneWidget);
    expect(find.byKey(const ValueKey('unit_picker_all')), findsOneWidget);
    expect(find.text('第1组'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('unit_picker_row_第1组')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('unit_picker_list')), findsNothing);
    expect(find.byKey(const ValueKey('unit_filter_hint')), findsOneWidget);
    expect(find.textContaining('已筛选 · 第1组'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byKey(const ValueKey('learn_known')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
