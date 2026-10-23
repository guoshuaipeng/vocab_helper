import '../models/word.dart';

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
