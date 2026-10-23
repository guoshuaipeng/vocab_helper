import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('pep-ps-3 phonetic ≥90% and example ≥80%', () async {
    final raw = await rootBundle.loadString('assets/wordbooks/pep-ps-3.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final words = (data['words'] as List).cast<Map<String, dynamic>>();
    expect(words.length, greaterThanOrEqualTo(100));

    final withPh = words.where((w) => ((w['phonetic'] as String?) ?? '').trim().isNotEmpty).length;
    final withEx = words.where((w) => ((w['example'] as String?) ?? '').trim().isNotEmpty).length;
    final phRatio = withPh / words.length;
    final exRatio = withEx / words.length;

    expect(phRatio, greaterThanOrEqualTo(0.90), reason: 'phonetic $withPh/${words.length}');
    expect(exRatio, greaterThanOrEqualTo(0.80), reason: 'example $withEx/${words.length}');

    // Sample: phonetic uses /…/
    final sample = words.where((w) => ((w['phonetic'] as String?) ?? '').isNotEmpty).take(20);
    for (final w in sample) {
      final ph = (w['phonetic'] as String).trim();
      expect(ph.startsWith('/'), isTrue, reason: '${w['word']} phonetic=$ph');
      expect(ph.endsWith('/'), isTrue, reason: '${w['word']} phonetic=$ph');
    }
  });
}
