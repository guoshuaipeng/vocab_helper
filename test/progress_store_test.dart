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

  test('autoSpeak defaults false', () async {
    final store = await ProgressStore.open();
    expect(store.autoSpeak(), isFalse);
    await store.setAutoSpeak(true);
    expect(store.autoSpeak(), isTrue);
  });
}