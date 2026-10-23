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
}