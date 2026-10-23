import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/me_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';
import 'package:vocab_helper/services/word_speaker.dart';
import 'package:vocab_helper/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProgressStore> pumpMe(WidgetTester tester, Map<String, Object> prefs) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    SharedPreferences.setMockInitialValues(prefs);
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await ProgressStore.open();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: MeScreen(
            store: store,
            repo: WordbookRepository(),
            onRefresh: () {},
            onChangeBook: () {},
            onReviewWrong: () {},
            onReviewWrongCurrentUnit: () {},
            onQuizBook: () {},
            onQuizUnit: () {},
            onQuizWrong: () {},
            onStartDueReview: () {},
            speaker: FakeWordSpeaker()..voiceAvailable = true,
          ),
        ),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    return store;
  }

  Future<void> openWrongSheet(WidgetTester tester) async {
    final entry = find.byKey(const ValueKey('me_wrong_book_entry'));
    await tester.scrollUntilVisible(entry, 200, scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(entry);
    await tester.pump();
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const ValueKey('wrong_book_list')).evaluate().isNotEmpty ||
          find.byKey(const ValueKey('wrong_book_empty')).evaluate().isNotEmpty) {
        break;
      }
    }
  }

  testWidgets('opens wrong book sheet with sorted words', (tester) async {
    final store = await pumpMe(tester, {
      'selected_book_id': 'pep-ps-3',
      'wrong_ids': ['pep-ps-3-3', 'pep-ps-3-1', 'other-x'],
      'daily_goal': 20,
      'today_count': 0,
      'streak_days': 0,
      'today_date': ProgressStore.dateKey(DateTime.now()),
    });
    expect(store.wrongCountForBook('pep-ps-3'), 2);
    await openWrongSheet(tester);
    expect(find.byKey(const ValueKey('wrong_book_list')), findsOneWidget);
    expect(find.byKey(const ValueKey('wrong_book_subtitle')), findsOneWidget);
    expect(find.byKey(const ValueKey('wrong_book_quiz')), findsOneWidget);
    expect(find.byKey(const ValueKey('wrong_book_review')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const ValueKey('wrong_book_quiz')), matching: find.text('测这些')), findsOneWidget);
  });

  testWidgets('empty wrong book shows learn-new CTA', (tester) async {
    final store = await pumpMe(tester, {
      'selected_book_id': 'pep-ps-3',
      'daily_goal': 20,
      'today_count': 0,
      'streak_days': 0,
      'today_date': ProgressStore.dateKey(DateTime.now()),
    });
    expect(store.wrongCountForBook('pep-ps-3'), 0);
    await openWrongSheet(tester);
    expect(find.byKey(const ValueKey('wrong_book_empty')), findsOneWidget);
    expect(find.byKey(const ValueKey('wrong_book_learn_new')), findsOneWidget);
  });
}