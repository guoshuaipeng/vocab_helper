import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/word.dart';

/// Local overlay of user-added words per wordbook (R37).
/// Does not mutate asset JSON; merged at load time.
class CustomWordOverlay {
  CustomWordOverlay(this._prefs);

  final SharedPreferences _prefs;

  static const _prefix = 'custom_words_';

  static Future<CustomWordOverlay> open() async {
    final prefs = await SharedPreferences.getInstance();
    return CustomWordOverlay(prefs);
  }

  String _key(String bookId) => '$_prefix$bookId';

  Future<List<Word>> wordsForBook(String bookId) async {
    final raw = _prefs.getString(_key(bookId));
    if (raw == null || raw.isEmpty) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final e in list) Word.fromJson(e as Map<String, dynamic>),
    ];
  }

  /// Append [words] (skip if same id already present). Returns added count.
  Future<int> addWords(String bookId, List<Word> words) async {
    if (words.isEmpty) return 0;
    final existing = await wordsForBook(bookId);
    final ids = existing.map((w) => w.id).toSet();
    final spellings = {
      for (final w in existing) w.word.toLowerCase(),
    };
    final merged = [...existing];
    var added = 0;
    for (final w in words) {
      if (ids.contains(w.id)) continue;
      if (spellings.contains(w.word.toLowerCase())) continue;
      merged.add(w);
      ids.add(w.id);
      spellings.add(w.word.toLowerCase());
      added++;
    }
    if (added > 0) {
      await _prefs.setString(
        _key(bookId),
        jsonEncode([for (final w in merged) w.toJson()]),
      );
    }
    return added;
  }

  /// Build a stable custom word id.
  static String newId(String bookId, String spelling) {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final safe = spelling.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return 'custom-$bookId-$safe-$stamp';
  }
}
