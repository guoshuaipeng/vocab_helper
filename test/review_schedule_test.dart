import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/services/progress_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('daysForStage buckets 1/3/7/14/30', () {
    expect(ProgressStore.daysForStage(0), 1);
    expect(ProgressStore.daysForStage(1), 3);
    expect(ProgressStore.daysForStage(2), 7);
    expect(ProgressStore.daysForStage(3), 14);
    expect(ProgressStore.daysForStage(4), 30);
    expect(ProgressStore.daysForStage(99), 30);
  });

  test('labelForStage kid-friendly copy', () {
    expect(ProgressStore.labelForStage(0), '明天复习');
    expect(ProgressStore.labelForStage(1), '3天后');
    expect(ProgressStore.labelForStage(2), '约一周');
    expect(ProgressStore.labelForStage(3), '约两周');
    expect(ProgressStore.labelForStage(4), '约一个月');
    expect(ProgressStore.nextReviewHintForStage(0), '下次 · 明天复习');
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

  test('first known after unknown stays 1-day bucket', () async {
    final store = await ProgressStore.open();
    await store.markWrong('b-1', now: DateTime(2026, 10, 23));
    await store.markLearned('b-1', now: DateTime(2026, 10, 23));
    expect(store.reviewStage('b-1'), 0);
    expect(store.reviewAt('b-1'), '2026-10-24');
  });

  test('stages advance 1/3/7/14/30 and cap at 4', () async {
    final store = await ProgressStore.open();
    await store.markLearned('b-1', now: DateTime(2026, 10, 1)); // stage0 +1
    expect(store.reviewStage('b-1'), 0);
    expect(store.reviewAt('b-1'), '2026-10-02');
    await store.markLearned('b-1', now: DateTime(2026, 10, 2)); // stage1 +3
    expect(store.reviewStage('b-1'), 1);
    expect(store.reviewAt('b-1'), '2026-10-05');
    await store.markLearned('b-1', now: DateTime(2026, 10, 5)); // stage2 +7
    expect(store.reviewStage('b-1'), 2);
    expect(store.reviewAt('b-1'), '2026-10-12');
    await store.markLearned('b-1', now: DateTime(2026, 10, 12)); // stage3 +14
    expect(store.reviewStage('b-1'), 3);
    expect(store.reviewAt('b-1'), '2026-10-26');
    await store.markLearned('b-1', now: DateTime(2026, 10, 26)); // stage4 +30
    expect(store.reviewStage('b-1'), 4);
    expect(store.reviewAt('b-1'), '2026-11-25');
    await store.markLearned('b-1', now: DateTime(2026, 11, 25)); // stay 4 +30
    expect(store.reviewStage('b-1'), 4);
    expect(store.reviewAt('b-1'), '2026-12-25');
  });

  test('legacy stage 3 maps onto new 14-day bucket on next known', () async {
    SharedPreferences.setMockInitialValues({
      'learned_ids': ['b-1'],
      'review_stage_b-1': 3,
      'review_at_b-1': '2026-10-20',
    });
    final store = await ProgressStore.open();
    expect(store.reviewStage('b-1'), 3);
    await store.markLearned('b-1', now: DateTime(2026, 10, 20));
    expect(store.reviewStage('b-1'), 4);
    expect(store.reviewAt('b-1'), '2026-11-19');
    expect(ProgressStore.daysForStage(3), 14);
  });

  test('reviewNextHintEnabled defaults true and can disable', () async {
    final store = await ProgressStore.open();
    expect(store.reviewNextHintEnabled(), isTrue);
    await store.setReviewNextHintEnabled(false);
    expect(store.reviewNextHintEnabled(), isFalse);
  });
}
