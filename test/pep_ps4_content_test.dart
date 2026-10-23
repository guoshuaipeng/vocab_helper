import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('pep-ps-4 >=220 words; new-word phonetic>=85% example>=70%; units present', () async {
    final raw = await rootBundle.loadString('assets/wordbooks/pep-ps-4.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    expect((data['source'] as String?) ?? '', contains('扩充'));
    final words = (data['words'] as List).cast<Map<String, dynamic>>();
    expect(words.length, greaterThanOrEqualTo(220));

    final withUnit = words.where((w) => ((w['unit'] as String?) ?? '').trim().isNotEmpty).length;
    expect(withUnit, words.length);

    final units = <String>{};
    for (final w in words) {
      units.add((w['unit'] as String).trim());
    }
    expect(units.length, greaterThanOrEqualTo(6), reason: 'units=$units');

    final neu = words.where((w) {
      final id = w['id'] as String;
      final n = int.tryParse(id.split('-').last) ?? 0;
      return n >= 101;
    }).toList();
    expect(neu.length, greaterThan(100));
    final ph = neu.where((w) => ((w['phonetic'] as String?) ?? '').trim().isNotEmpty).length;
    final ex = neu.where((w) => ((w['example'] as String?) ?? '').trim().isNotEmpty).length;
    expect(ph / neu.length, greaterThanOrEqualTo(0.85), reason: 'phonetic $ph/${neu.length}');
    expect(ex / neu.length, greaterThanOrEqualTo(0.70), reason: 'example $ex/${neu.length}');

    for (final w in neu.where((w) => ((w['phonetic'] as String?) ?? '').isNotEmpty).take(20)) {
      final p = (w['phonetic'] as String).trim();
      expect(p.startsWith('/'), isTrue, reason: '${w['word']}');
      expect(p.endsWith('/'), isTrue, reason: '${w['word']}');
    }

    final seen = <String>{};
    for (final w in words) {
      final key = '${(w['word'] as String).toLowerCase()}|${w['unit']}';
      expect(seen.contains(key), isFalse, reason: 'dup $key');
      seen.add(key);
    }
  });

  test('catalog pep-ps-4 wordCount and sourceLabel', () async {
    final raw = await rootBundle.loadString('assets/wordbooks/catalog.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final books = (data['books'] as List).cast<Map<String, dynamic>>();
    final b = books.firstWhere((e) => e['id'] == 'pep-ps-4');
    expect((b['wordCount'] as num).toInt(), greaterThanOrEqualTo(220));
    expect((b['sourceLabel'] as String?) ?? '', contains('扩充'));
  });
}
