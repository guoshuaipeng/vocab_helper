import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/word.dart';

class WordbookRepository {
  List<WordBookMeta>? _catalog;
  final Map<String, WordBook> _cache = {};

  Future<List<WordBookMeta>> loadCatalog() async {
    if (_catalog != null) return _catalog!;
    final raw = await rootBundle.loadString('assets/wordbooks/catalog.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    _catalog = (map['books'] as List<dynamic>)
        .map((e) => WordBookMeta.fromJson(e as Map<String, dynamic>))
        .toList();
    return _catalog!;
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

  List<String> versionsOf(List<WordBookMeta> catalog) {
    return catalog.map((e) => e.version).toSet().toList();
  }

  List<WordBookMeta> booksOf(List<WordBookMeta> catalog, String version) {
    return catalog.where((e) => e.version == version).toList();
  }
}