import '../models/word.dart';

/// Assembles browseable wrong-word list for current book (R39).
class WrongBookList {
  WrongBookList._();

  static const listCap = 40;

  /// [wrongIds] may include other books; only ids present in [bookWords] are kept.
  /// Sorted by spelling (case-insensitive). Missing ids skipped.
  static List<Word> assemble(List<Word> bookWords, Iterable<String> wrongIds) {
    final byId = {for (final w in bookWords) w.id: w};
    final out = <Word>[];
    for (final id in wrongIds) {
      final w = byId[id];
      if (w != null) out.add(w);
    }
    out.sort((a, b) => a.word.toLowerCase().compareTo(b.word.toLowerCase()));
    return out;
  }

  /// Words shown in UI (capped) and how many more exist beyond [listCap].
  static ({List<Word> shown, int more}) truncate(List<Word> all, {int cap = listCap}) {
    if (all.length <= cap) return (shown: all, more: 0);
    return (shown: all.take(cap).toList(), more: all.length - cap);
  }
}