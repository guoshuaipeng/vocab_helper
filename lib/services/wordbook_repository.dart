import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/word.dart';
import 'cross_book_search.dart';

class WordbookRepository {
  List<WordBookMeta>? _catalog;
  final Map<String, WordBook> _cache = {};
  final CrossBookSearchIndex searchIndex = CrossBookSearchIndex();
  Future<void>? _indexBuild;

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
    if (_cache.containsKey(id)) return _cache[id]!;
    final catalog = await loadCatalog();
    final meta = catalog.firstWhere(
      (b) => b.id == id,
      orElse: () => throw StateError('词书不存在：$id'),
    );
    final raw = await rootBundle.loadString('assets/wordbooks/${meta.file}');
    final book = WordBook.fromJson(jsonDecode(raw) as Map<String, dynamic>).withUnits();
    _cache[id] = book;
    return book;
  }

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
