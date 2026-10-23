import '../models/word.dart';

/// One searchable row: a word inside a catalog book.
class CrossBookSearchHit {
  const CrossBookSearchHit({
    required this.meta,
    required this.word,
  });

  final WordBookMeta meta;
  final Word word;
}

class _IndexEntry {
  _IndexEntry({
    required this.meta,
    required this.word,
    required this.wordLower,
    required this.meaningLower,
  });

  final WordBookMeta meta;
  final Word word;
  final String wordLower;
  final String meaningLower;
}

/// In-memory cross-book search index (session only; no persistence).
///
/// Match: English lowercase substring OR Chinese meaning substring.
/// Order: current book first → version → grade → word → bookId; truncate [limit].
class CrossBookSearchIndex {
  final List<_IndexEntry> _entries = [];
  bool _ready = false;
  bool _building = false;
  int _generation = 0;

  bool get isReady => _ready;
  bool get isBuilding => _building;
  int get entryCount => _entries.length;
  int get generation => _generation;

  void clear() {
    _entries.clear();
    _ready = false;
    _building = false;
    _generation++;
  }

  /// Build from catalog via [loadBook]. Null/throw → skip that book.
  Future<void> build({
    required List<WordBookMeta> catalog,
    required Future<WordBook?> Function(WordBookMeta meta) loadBook,
  }) async {
    final gen = ++_generation;
    _building = true;
    _ready = false;
    _entries.clear();

    final built = <_IndexEntry>[];
    for (final meta in catalog) {
      if (gen != _generation) return;
      WordBook? book;
      try {
        book = await loadBook(meta);
      } catch (_) {
        book = null;
      }
      if (book == null) continue;
      for (final w in book.words) {
        built.add(_IndexEntry(
          meta: meta,
          word: w,
          wordLower: w.word.toLowerCase(),
          meaningLower: w.meaning.toLowerCase(),
        ));
      }
    }

    if (gen != _generation) return;
    _entries
      ..clear()
      ..addAll(built);
    _ready = true;
    _building = false;
  }

  /// Seed synchronously (unit tests).
  void replaceWithBooks(List<WordBook> books, List<WordBookMeta> catalog) {
    final byId = {for (final m in catalog) m.id: m};
    _entries.clear();
    for (final book in books) {
      final meta = byId[book.id];
      if (meta == null) continue;
      for (final w in book.words) {
        _entries.add(_IndexEntry(
          meta: meta,
          word: w,
          wordLower: w.word.toLowerCase(),
          meaningLower: w.meaning.toLowerCase(),
        ));
      }
    }
    _ready = true;
    _building = false;
    _generation++;
  }

  List<CrossBookSearchHit> query(
    String raw, {
    String? currentBookId,
    int limit = 40,
  }) {
    final q = raw.trim().toLowerCase();
    if (q.isEmpty || !_ready) return const [];

    final hits = <CrossBookSearchHit>[];
    for (final e in _entries) {
      if (e.wordLower.contains(q) || e.meaningLower.contains(q)) {
        hits.add(CrossBookSearchHit(meta: e.meta, word: e.word));
      }
    }

    hits.sort((a, b) {
      final aCur = a.meta.id == currentBookId ? 0 : 1;
      final bCur = b.meta.id == currentBookId ? 0 : 1;
      if (aCur != bCur) return aCur.compareTo(bCur);
      final v = a.meta.version.compareTo(b.meta.version);
      if (v != 0) return v;
      final g = a.meta.grade.compareTo(b.meta.grade);
      if (g != 0) return g;
      final w = a.word.word.toLowerCase().compareTo(b.word.word.toLowerCase());
      if (w != 0) return w;
      return a.meta.id.compareTo(b.meta.id);
    });

    if (hits.length <= limit) return hits;
    return hits.sublist(0, limit);
  }
}
