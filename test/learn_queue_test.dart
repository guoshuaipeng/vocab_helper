import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/services/progress_store.dart';

/// Mirrors LearnScreen queue: due (old→new) then never-learned.
List<String> buildLearnQueueIds(
  ProgressStore store,
  List<String> scopedIds, {
  DateTime? now,
}) {
  final learned = store.learnedIds();
  final due = <String>[];
  final fresh = <String>[];
  for (final id in scopedIds) {
    if (!learned.contains(id)) {
      fresh.add(id);
    } else if (store.isReviewDue(id, now: now)) {
      due.add(id);
    }
  }
  due.sort((a, b) => (store.reviewAt(a) ?? '').compareTo(store.reviewAt(b) ?? ''));
  return [...due, ...fresh];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('learn queue: due first then new; not-due omitted', () async {
    final store = await ProgressStore.open();
    final day0 = DateTime(2026, 10, 20);
    final day1 = DateTime(2026, 10, 21);
    final today = DateTime(2026, 10, 24);

    await store.markLearned('b-due-old', now: day0); // due 10-21
    await store.markLearned('b-due-new', now: day1); // due 10-22
    await store.markLearned('b-fresh-learned', now: today); // due tomorrow, not in queue

    final q = buildLearnQueueIds(
      store,
      ['b-new-1', 'b-due-new', 'b-due-old', 'b-fresh-learned', 'b-new-2'],
      now: today,
    );
    expect(q, ['b-due-old', 'b-due-new', 'b-new-1', 'b-new-2']);
  });
}
