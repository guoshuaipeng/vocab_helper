import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/models/word.dart';
import 'package:vocab_helper/screens/me_screen.dart';
import 'package:vocab_helper/screens/quiz_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/quiz_engine.dart';
import 'package:vocab_helper/services/word_speaker.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';

Word w(String id, String word, String meaning) =>
    Word(id: id, word: word, meaning: meaning, unit: 'U1');

Future<ProgressStore> openFresh(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  final store = await ProgressStore.open();
  final prefs = await SharedPreferences.getInstance();
  for (final e in values.entries) {
    final v = e.value;
    if (v is String) {
      await prefs.setString(e.key, v);
    } else if (v is int) {
      await prefs.setInt(e.key, v);
    } else if (v is bool) {
      await prefs.setBool(e.key, v);
    } else if (v is List<String>) {
      await prefs.setStringList(e.key, v);
    }
  }
  // Drop celebrate unless explicitly set.
  if (!values.containsKey('goal_celebrated_ymd')) {
    await prefs.remove('goal_celebrated_ymd');
  }
  return ProgressStore(prefs);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('rising edge celebrates once per day', () async {
    final day = DateTime(2026, 10, 23);
    SharedPreferences.setMockInitialValues({
      'daily_goal': 5,
      'today_date': ProgressStore.dateKey(day),
      'today_count': 4,
    });
    final store = await ProgressStore.open();
    expect(await store.bumpTodayCount(now: day), isTrue);
    expect(store.todayCount(now: day), 5);
    expect(store.goalCelebratedYmd(), ProgressStore.dateKey(day));
    expect(await store.bumpTodayCount(now: day), isFalse);
    expect(store.todayCount(now: day), 6);
  });

  test('already at goal on start does not celebrate without rising edge', () async {
    final day = DateTime(2026, 10, 23);
    SharedPreferences.setMockInitialValues({
      'daily_goal': 5,
      'today_date': ProgressStore.dateKey(day),
      'today_count': 5,
      'goal_celebrated_ymd': ProgressStore.dateKey(day),
    });
    final store = await ProgressStore.open();
    expect(await store.bumpTodayCount(now: day), isFalse);
  });

  test('cross day allows celebrate again', () async {
    final d1 = DateTime(2026, 10, 23);
    final d2 = DateTime(2026, 10, 24);
    SharedPreferences.setMockInitialValues({
      'daily_goal': 5,
      'today_date': ProgressStore.dateKey(d1),
      'today_count': 5,
      'goal_celebrated_ymd': ProgressStore.dateKey(d1),
    });
    final store = await ProgressStore.open();
    expect(await store.bumpTodayCount(now: d2), isFalse);
    for (var i = 0; i < 3; i++) {
      expect(await store.bumpTodayCount(now: d2), isFalse);
    }
    expect(await store.bumpTodayCount(now: d2), isTrue);
    expect(store.goalCelebratedYmd(), ProgressStore.dateKey(d2));
  });

  testWidgets('quiz correct crossing goal shows banner once', (tester) async {
    final today = ProgressStore.dateKey(DateTime.now());
    final store = await openFresh({
      'selected_book_id': 'pep-ps-4',
      'quiz_variant': 'meaning',
      'daily_goal': 5,
      'today_count': 4,
      'today_date': today,
    });
    expect(store.todayCount(), 4);
    expect(store.goalCelebratedYmd(), isNull);
    final questions = [
      QuizQuestion(
        target: w('a', 'apple', '苹果'),
        options: [
          w('a', 'apple', '苹果'),
          w('b', 'pear', '梨'),
          w('c', 'banana', '香蕉'),
          w('d', 'grape', '葡萄'),
        ],
        correctIndex: 0,
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: QuizScreen(
          store: store,
          repo: WordbookRepository(),
          mode: QuizMode.book,
          speaker: FakeWordSpeaker()..voiceAvailable = true,
          seedQuestions: questions,
          seedBookTitle: '测试',
        ),
      ),
    );
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.tap(find.text('apple'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('goal_celebrate_banner')), findsOneWidget);
    expect(find.byKey(const ValueKey('goal_celebrate_title')), findsOneWidget);
    expect(find.textContaining('今日目标达成'), findsOneWidget);
    expect(find.textContaining('已学 5 / 5'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('goal_celebrate_continue')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('me page shows 今日已完成 when met', (tester) async {
    final today = ProgressStore.dateKey(DateTime.now());
    final store = await openFresh({
      'selected_book_id': 'pep-ps-4',
      'daily_goal': 8,
      'today_count': 8,
      'today_date': today,
      'day_count_$today': 8,
    });
    await tester.pumpWidget(
      MaterialApp(
        home: MeScreen(
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
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.textContaining('今日已完成 · 8/8'), findsOneWidget);
    expect(find.byKey(const ValueKey('me_today_goal_status')), findsOneWidget);
  });
}
