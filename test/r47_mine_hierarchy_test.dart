import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/me_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/word_speaker.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';
import 'package:vocab_helper/theme/app_theme.dart';
import 'support/expand_me_more.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('R47 hierarchy: hero+actions first; more collapsed; keys kept', (tester) async {
    final today = ProgressStore.dateKey(DateTime.now());
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-3',
      'daily_goal': 20,
      'learned_ids': ['pep-ps-3-1'],
      'wrong_ids': ['pep-ps-3-2'],
      'today_count': 5,
      'streak_days': 2,
      'today_date': today,
      'day_count_$today': 5,
    });
    tester.view.physicalSize = const Size(390, 844);
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
            speaker: FakeWordSpeaker()..voiceAvailable = true,
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

    // A1: hero visible; accent not on first screen
    expect(find.byKey(const ValueKey('me_hero')), findsOneWidget);
    expect(find.byKey(const ValueKey('me_today_goal_count')), findsOneWidget);
    expect(find.byKey(const ValueKey('me_due_review')), findsOneWidget);
    expect(find.text('朗读口音'), findsNothing);

    // A2: actions + teal quiz + wrong entry
    expect(find.byKey(const ValueKey('me_actions')), findsOneWidget);
    expect(find.byKey(const ValueKey('me_wrong_book_entry')), findsOneWidget);
    expect(find.text('自测本词书'), findsOneWidget);
    expect(find.byKey(const ValueKey('me_quiz_wrong_pool')), findsOneWidget);

    // A3: export visible (R51); more still collapsed for accent/unit
    expect(find.byKey(const ValueKey('me_more_section'), skipOffstage: false), findsOneWidget);
    expect(find.byKey(const ValueKey('export_progress')), findsOneWidget);
    expect(find.byKey(const ValueKey('me_export_row')), findsOneWidget);
    expect(find.text('朗读口音'), findsNothing);
    await expandMeMore(tester);
    expect(find.byKey(const ValueKey('me_unit_progress')), findsOneWidget);
    expect(find.text('朗读口音'), findsOneWidget);
    expect(find.byKey(const ValueKey('me_stats_summary'), skipOffstage: false), findsOneWidget);
  });
}
