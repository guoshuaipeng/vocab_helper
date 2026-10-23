import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/word.dart';
import 'cross_book_search.dart';
import 'custom_word_overlay.dart';

class WordbookRepository {
  /// Default follow-along book (R40): 沪教牛津 2024 七上.
  static const recommendedBookId = 'hj-ox-7a-2024';

  List<WordBookMeta>? _catalog;
  final Map<String, WordBook> _cache = {};
  final CrossBookSearchIndex searchIndex = CrossBookSearchIndex();
  Future<void>? _indexBuild;

  /// Optional R37 overlay; set from app boot.
  CustomWordOverlay? overlay;

  Future<List<WordBookMeta>> loadCatalog() async {
    if (_catalog != null) return _catalog!;
    final raw = await rootBundle.loadString('assets/wordbooks/catalog.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    _catalog = (map['books'] as List<dynamic>)
        .map((e) => WordBookMeta.fromJson(e as Map<String, dynamic>))
        .toList();
    return _catalog!;
  }

  /// Force catalog reload and rebuild search index (R24).
  Future<List<WordBookMeta>> reloadCatalog() async {
    _catalog = null;
    searchIndex.clear();
    final c = await loadCatalog();
    await ensureSearchIndex();
    return c;
  }

  Future<WordBook> loadBook(String id) async {
    WordBook base;
    if (_cache.containsKey(id)) {
      base = _cache[id]!;
    } else {
      final catalog = await loadCatalog();
      final meta = catalog.firstWhere(
        (b) => b.id == id,
        orElse: () => throw StateError('词书不存在：$id'),
      );
      final raw = await rootBundle.loadString('assets/wordbooks/${meta.file}');
      base = WordBook.fromJson(jsonDecode(raw) as Map<String, dynamic>).withUnits();
      _cache[id] = base;
    }
    final extra = await overlay?.wordsForBook(id) ?? const <Word>[];
    return base.mergedWith(extra);
  }

  /// Drop cached base so next load picks up asset changes (overlay always fresh).
  void invalidateBookCache(String id) => _cache.remove(id);

  /// Start or await background index build after catalog is ready.
  Future<void> ensureSearchIndex() {
    if (searchIndex.isReady) return Future.value();
    return _indexBuild ??= _buildSearchIndex();
  }

  Future<void> _buildSearchIndex() async {
    try {
      final catalog = await loadCatalog();
      await searchIndex.build(
        catalog: catalog,
        loadBook: (meta) async {
          try {
            return await loadBook(meta.id);
          } catch (_) {
            return null;
          }
        },
      );
    } finally {
      _indexBuild = null;
    }
  }

  List<CrossBookSearchHit> search(
    String query, {
    String? currentBookId,
    int limit = 40,
  }) {
    return searchIndex.query(
      query,
      currentBookId: currentBookId,
      limit: limit,
    );
  }

  List<String> versionsOf(List<WordBookMeta> catalog) {
    return catalog.map((e) => e.version).toSet().toList();
  }

  List<WordBookMeta> booksOf(List<WordBookMeta> catalog, String version) {
    return catalog.where((e) => e.version == version).toList();
  }
}
