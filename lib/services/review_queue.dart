import '../models/word.dart';

/// Filter wrong-book words; [unitFilter] null/empty = whole book.
List<Word> filterWrongWords({
  required List<Word> words,
  required Set<String> wrongIds,
  String? unitFilter,
}) {
  Iterable<Word> list = words.where((w) => wrongIds.contains(w.id));
  if (unitFilter != null && unitFilter.isNotEmpty) {
    list = list.where((w) => w.unit == unitFilter);
  }
  return list.toList();
}

/// Session review queue: unknown words are re-queued to the end.
class ReviewQueue {
  ReviewQueue(List<Word> initial) : _queue = List<Word>.from(initial);

  final List<Word> _queue;
  final Set<String> _knownIds = {};

  Word? get current => _queue.isEmpty ? null : _queue.first;
  int get remaining => _queue.length;
  int get knownCount => _knownIds.length;
  bool get isEmpty => _queue.isEmpty;

  void markKnown() {
    if (_queue.isEmpty) return;
    final w = _queue.removeAt(0);
    _knownIds.add(w.id);
  }

  void markUnknown() {
    if (_queue.isEmpty) return;
    final w = _queue.removeAt(0);
    _queue.add(w);
  }
}

/// Build self-test pool: optional unit ∩ optional wrong-only (R32).
List<Word> buildQuizPool({
  required List<Word> bookWords,
  required Set<String> wrongIds,
  String? unitFilter,
  bool wrongOnly = false,
}) {
  Iterable<Word> list = bookWords;
  if (unitFilter != null && unitFilter.isNotEmpty) {
    list = list.where((w) => w.unit == unitFilter);
  }
  if (wrongOnly) {
    list = list.where((w) => wrongIds.contains(w.id));
  }
  return list.toList();
}

