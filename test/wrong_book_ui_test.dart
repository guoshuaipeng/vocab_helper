import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/me_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpMe(WidgetTester tester, Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    final store = await ProgressStore.open();
    await tester.pumpWidget(
      MaterialApp(
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
          ),
        ),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('opens wrong book sheet with sorted words', (tester) async {
    await pumpMe(tester, {
      'selected_book_id': 'pep-ps-3',
      'wrong_ids': ['pep-ps-3-3', 'pep-ps-3-1', 'other-x'],
      'daily_goal': 20,
      'today_count': 0,
      'streak_days': 0,
      'today_date': ProgressStore.dateKey(DateTime.now()),
    });
    await tester.ensureVisible(find.byKey(const ValueKey('me_wrong_book_entry')));
    await tester.tap(find.byKey(const ValueKey('me_wrong_book_entry')));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const ValueKey('wrong_book_list')), findsOneWidget);
    expect(find.byKey(const ValueKey('wrong_book_review')), findsOneWidget);
    expect(find.byKey(const ValueKey('wrong_book_quiz')), findsOneWidget);
  });

  testWidgets('empty wrong book shows learn-new CTA', (tester) async {
    await pumpMe(tester, {
      'selected_book_id': 'pep-ps-3',
      'wrong_ids': <String>[],
      'daily_goal': 20,
      'today_count': 0,
      'streak_days': 0,
      'today_date': ProgressStore.dateKey(DateTime.now()),
    });
    await tester.ensureVisible(find.byKey(const ValueKey('me_wrong_book_entry')));
    await tester.tap(find.byKey(const ValueKey('me_wrong_book_entry')));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const ValueKey('wrong_book_empty')), findsOneWidget);
    expect(find.byKey(const ValueKey('wrong_book_learn_new')), findsOneWidget);
  });
}