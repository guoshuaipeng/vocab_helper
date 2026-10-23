import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/services/progress_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('dueReviewEntriesForBook filters current book, sorts earlier due first', () async {
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-3',
      'learned_ids': [
        'pep-ps-3-2',
        'pep-ps-3-1',
        'pep-ps-3-3',
        'other-book-1',
      ],
      'review_at_pep-ps-3-1': '2026-10-20',
      'review_at_pep-ps-3-2': '2026-10-10',
      'review_at_pep-ps-3-3': '2099-01-01', // not due
      'review_at_other-book-1': '2026-01-01',
    });
    final store = await ProgressStore.open();
    final now = DateTime(2026, 10, 23);
    expect(store.dueReviewCountForBook('pep-ps-3', now: now), 2);
    final entries = store.dueReviewEntriesForBook('pep-ps-3', now: now);
    expect(entries.map((e) => e.id).toList(), ['pep-ps-3-2', 'pep-ps-3-1']);
    expect(entries.first.at, '2026-10-10');
  });

  test('same-day due sorts by id then caller may sort by word', () async {
    SharedPreferences.setMockInitialValues({
      'learned_ids': ['pep-ps-3-b', 'pep-ps-3-a'],
      'review_at_pep-ps-3-a': '2026-10-01',
      'review_at_pep-ps-3-b': '2026-10-01',
    });
    final store = await ProgressStore.open();
    final entries = store.dueReviewEntriesForBook('pep-ps-3', now: DateTime(2026, 10, 23));
    expect(entries.map((e) => e.id).toList(), ['pep-ps-3-a', 'pep-ps-3-b']);
  });
}
