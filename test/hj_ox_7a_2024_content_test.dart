import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('hj-ox-7a-2024: 330 words, 8 units, no empty meaning, count matches', () async {
    final raw = await rootBundle.loadString('assets/wordbooks/hj-ox-7a-2024.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    expect(data['id'], 'hj-ox-7a-2024');
    expect((data['title'] as String?) ?? '', contains('2024'));
    expect((data['source'] as String?) ?? '', contains('纸质课本'));

    final words = (data['words'] as List).cast<Map<String, dynamic>>();
    final declared = (data['wordCount'] as num).toInt();
    expect(words.length, declared);
    expect(words.length, 330);
    expect(words.length, greaterThanOrEqualTo(300));

    final units = <String>{};
    for (final w in words) {
      final meaning = ((w['meaning'] as String?) ?? '').trim();
      expect(meaning.isNotEmpty, isTrue, reason: 'empty meaning ${w['id']} ${w['word']}');
      final unit = ((w['unit'] as String?) ?? '').trim();
      expect(unit.isNotEmpty, isTrue, reason: 'empty unit ${w['id']}');
      units.add(unit);
    }
    expect(units.length, 8, reason: 'units=$units');
    for (var i = 1; i <= 8; i++) {
      expect(units.contains('Unit $i'), isTrue, reason: 'missing Unit $i');
    }

    final seen = <String>{};
    for (final w in words) {
      final key = '${(w['word'] as String).toLowerCase()}|${w['unit']}';
      expect(seen.contains(key), isFalse, reason: 'dup $key');
      seen.add(key);
    }
  });

  test('catalog hj-ox-7a-2024 wordCount and sourceLabel; hj-jh-7 marked 精选', () async {
    final raw = await rootBundle.loadString('assets/wordbooks/catalog.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final books = (data['books'] as List).cast<Map<String, dynamic>>();

    final ox = books.firstWhere((e) => e['id'] == 'hj-ox-7a-2024');
    expect((ox['wordCount'] as num).toInt(), 330);
    expect((ox['sourceLabel'] as String?) ?? '', contains('2024六三'));
    expect((ox['title'] as String?) ?? '', contains('七年级上'));

    final sel = books.firstWhere((e) => e['id'] == 'hj-jh-7');
    expect((sel['title'] as String?) ?? '', contains('精选'));
  });
}
