import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/services/progress_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('daysForStage buckets 1/3/7/7', () {
    expect(ProgressStore.daysForStage(0), 1);
    expect(ProgressStore.daysForStage(1), 3);
    expect(ProgressStore.daysForStage(2), 7);
    expect(ProgressStore.daysForStage(3), 7);
    expect(ProgressStore.daysForStage(99), 7);
  });

  test('addDaysToDateKey', () {
    expect(ProgressStore.addDaysToDateKey('2026-10-23', 1), '2026-10-24');
    expect(ProgressStore.addDaysToDateKey('2026-10-31', 1), '2026-11-01');
  });

  test('first known schedules +1 day; not due same day', () async {
    final store = await ProgressStore.open();
    final day0 = DateTime(2026, 10, 23);
    await store.markLearned('b-1', now: day0);
    expect(store.learnedIds().contains('b-1'), isTrue);
    expect(store.reviewStage('b-1'), 0);
    expect(store.reviewAt('b-1'), '2026-10-24');
    expect(store.isReviewDue('b-1', now: day0), isFalse);
    expect(store.inLearnQueue('b-1', now: day0), isFalse);
    expect(store.isReviewDue('b-1', now: DateTime(2026, 10, 24)), isTrue);
    expect(store.inLearnQueue('b-1', now: DateTime(2026, 10, 24)), isTrue);
  });

  test('second known advances to +3 day bucket', () async {
    final store = await ProgressStore.open();
    await store.markLearned('b-1', now: DateTime(2026, 10, 23));
    await store.markLearned('b-1', now: DateTime(2026, 10, 24));
    expect(store.reviewStage('b-1'), 1);
    expect(store.reviewAt('b-1'), '2026-10-27');
  });

  test('unknown resets to 1-day bucket', () async {
    final store = await ProgressStore.open();
    await store.markLearned('b-1', now: DateTime(2026, 10, 23));
    await store.markLearned('b-1', now: DateTime(2026, 10, 24));
    await store.markWrong('b-1', now: DateTime(2026, 10, 25));
    expect(store.wrongIds().contains('b-1'), isTrue);
    expect(store.reviewStage('b-1'), 0);
    expect(store.reviewAt('b-1'), '2026-10-26');
  });

  test('clearLearnedForBook removes review keys', () async {
    final store = await ProgressStore.open();
    await store.markLearned('pep-ps-3-1', now: DateTime(2026, 10, 23));
    await store.markLearned('other-1', now: DateTime(2026, 10, 23));
    expect(store.reviewAt('pep-ps-3-1'), isNotNull);
    final removed = await store.clearLearnedForBook('pep-ps-3');
    expect(removed, 1);
    expect(store.reviewAt('pep-ps-3-1'), isNull);
    expect(store.reviewStage('pep-ps-3-1'), isNull);
    expect(store.reviewAt('other-1'), isNotNull);
  });

  test('dueReviewCountForBook', () async {
    final store = await ProgressStore.open();
    await store.markLearned('pep-ps-3-1', now: DateTime(2026, 10, 23));
    expect(store.dueReviewCountForBook('pep-ps-3', now: DateTime(2026, 10, 23)), 0);
    expect(store.dueReviewCountForBook('pep-ps-3', now: DateTime(2026, 10, 24)), 1);
  });
}
