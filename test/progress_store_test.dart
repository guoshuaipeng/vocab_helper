import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/services/progress_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('clearLearnedForBook only removes that book prefix', () async {
    final store = await ProgressStore.open();
    await store.markLearned('hj-ps-3-1');
    await store.markLearned('hj-ps-3-2');
    await store.markLearned('pep-ps-3-1');
    expect(store.learnedCountForBook('hj-ps-3'), 2);
    expect(store.learnedCount(), 3);

    final removed = await store.clearLearnedForBook('hj-ps-3');
    expect(removed, 2);
    expect(store.learnedCountForBook('hj-ps-3'), 0);
    expect(store.learnedIds().contains('pep-ps-3-1'), isTrue);
    expect(store.learnedCount(), 1);
  });

  test('clearLearnedForBook on empty returns 0', () async {
    final store = await ProgressStore.open();
    final removed = await store.clearLearnedForBook('missing-book');
    expect(removed, 0);
  });

  test('dailyGoal defaults and clamps', () async {
    final store = await ProgressStore.open();
    expect(store.dailyGoal(), 20);
    await store.setDailyGoal(3);
    expect(store.dailyGoal(), 5);
    await store.setDailyGoal(500);
    expect(store.dailyGoal(), 200);
    await store.setDailyGoal(30);
    expect(store.dailyGoal(), 30);
    expect(store.todayGoalMet, isFalse);
  });

  test('wrong book add remove and clear by book', () async {
    final store = await ProgressStore.open();
    await store.markWrong('hj-ps-3-1');
    await store.markWrong('hj-ps-3-2');
    await store.markWrong('pep-ps-3-9');
    expect(store.wrongCountForBook('hj-ps-3'), 2);
    expect(store.wrongCount(), 3);

    await store.markLearned('hj-ps-3-1');
    expect(store.wrongIds().contains('hj-ps-3-1'), isFalse);
    expect(store.wrongCountForBook('hj-ps-3'), 1);

    final cleared = await store.clearWrongForBook('hj-ps-3');
    expect(cleared, 1);
    expect(store.wrongIds().contains('pep-ps-3-9'), isTrue);
  });

  test('unit filter per book', () async {
    final store = await ProgressStore.open();
    expect(store.unitFilterForBook('hj-ps-3'), isNull);
    await store.setUnitFilterForBook('hj-ps-3', '第1组');
    expect(store.unitFilterForBook('hj-ps-3'), '第1组');
    await store.setUnitFilterForBook('hj-ps-3', null);
    expect(store.unitFilterForBook('hj-ps-3'), isNull);
  });

  test('ttsAccent defaults to en-US and switches', () async {
    final store = await ProgressStore.open();
    expect(store.ttsAccent(), 'en-US');
    await store.setTtsAccent('en-GB');
    expect(store.ttsAccent(), 'en-GB');
    await store.setTtsAccent('nope');
    expect(store.ttsAccent(), 'en-US');
  });

  test('bumpTodayCount increments without learned', () async {
    final store = await ProgressStore.open();
    expect(store.todayCount(), 0);
    expect(store.learnedCount(), 0);
    await store.bumpTodayCount();
    await store.bumpTodayCount();
    expect(store.todayCount(), 2);
    expect(store.learnedCount(), 0);
  });

  test('autoSpeak defaults false', () async {
    final store = await ProgressStore.open();
    expect(store.autoSpeak(), isFalse);
    await store.setAutoSpeak(true);
    expect(store.autoSpeak(), isTrue);
  });

  test('cross-day archives today_count into day_count_ymd', () async {
    final store = await ProgressStore.open();
    final day1 = DateTime(2026, 10, 20);
    final day2 = DateTime(2026, 10, 21);
    await store.setDailyGoal(5);
    for (var i = 0; i < 5; i++) {
      await store.bumpTodayCount(now: day1);
    }
    expect(store.todayCount(now: day1), 5);
    expect(store.dayCountFor('2026-10-20', now: day1), 5);

    await store.bumpTodayCount(now: day2);
    expect(store.dayCountFor('2026-10-20', now: day2), 5);
    expect(store.todayCount(now: day2), 1);
    expect(store.dayCountFor('2026-10-19', now: day2), isNull);
  });

  test('ensureDayRolled archives without bump', () async {
    final store = await ProgressStore.open();
    final mon = DateTime(2026, 10, 19);
    final tue = DateTime(2026, 10, 20);
    await store.setDailyGoal(10);
    await store.bumpTodayCount(now: mon);
    await store.bumpTodayCount(now: mon);
    await store.ensureDayRolled(now: tue);
    expect(store.dayCountFor('2026-10-19', now: tue), 2);
    expect(store.todayCount(now: tue), 0);
  });

  test('weekCheckIns Mon-Sun boundaries and no fake met', () async {
    final store = await ProgressStore.open();
    await store.setDailyGoal(5);
    final sunday = DateTime(2026, 10, 25);
    final monday = DateTime(2026, 10, 19);
    final tuesday = DateTime(2026, 10, 20);
    for (var i = 0; i < 5; i++) {
      await store.bumpTodayCount(now: monday);
    }
    await store.ensureDayRolled(now: tuesday);
    await store.bumpTodayCount(now: tuesday);
    await store.ensureDayRolled(now: sunday);

    final week = store.weekCheckIns(now: sunday);
    expect(week.length, 7);
    expect(week.first.weekday, 1);
    expect(week.last.weekday, 7);
    expect(week[0].ymd, '2026-10-19');
    expect(week[0].status, CheckInDayStatus.met);
    expect(week[1].ymd, '2026-10-20');
    expect(week[1].status, CheckInDayStatus.missed);
    for (var i = 2; i <= 5; i++) {
      expect(week[i].status, CheckInDayStatus.empty, reason: 'day index $i');
      expect(week[i].count, isNull);
    }
    expect(week[6].status, CheckInDayStatus.todayProgress);
  });

  test('weekCheckIns future days on Monday', () async {
    final store = await ProgressStore.open();
    await store.setDailyGoal(5);
    final monday = DateTime(2026, 10, 19);
    final week = store.weekCheckIns(now: monday);
    expect(week[0].status, CheckInDayStatus.todayProgress);
    for (var i = 1; i < 7; i++) {
      expect(week[i].status, CheckInDayStatus.future);
    }
  });

  test('changing goal does not rewrite archived day_count', () async {
    final store = await ProgressStore.open();
    final day1 = DateTime(2026, 10, 20);
    final day2 = DateTime(2026, 10, 21);
    await store.setDailyGoal(10);
    for (var i = 0; i < 8; i++) {
      await store.bumpTodayCount(now: day1);
    }
    await store.ensureDayRolled(now: day2);
    expect(store.dayCountFor('2026-10-20', now: day2), 8);
    await store.setDailyGoal(5);
    expect(store.dayCountFor('2026-10-20', now: day2), 8);
    final week = store.weekCheckIns(now: day2);
    final cell = week.firstWhere((d) => d.ymd == '2026-10-20');
    expect(cell.status, CheckInDayStatus.met);
  });
}
