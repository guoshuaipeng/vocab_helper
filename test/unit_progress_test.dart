import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/models/word.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/unit_progress.dart';

Word _w(String id, String? unit) => Word(
      id: id,
      word: id,
      meaning: 'm',
      unit: unit,
    );

WordBook _book(List<Word> words) => WordBook(
      id: 'b1',
      version: 'v',
      grade: 'g',
      title: 'Test Book',
      wordCount: words.length,
      source: '',
      words: words,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('aggregates learned/total/wrong per unit; natural order; 未分 last', () async {
    SharedPreferences.setMockInitialValues({
      'learned_ids': ['b1-1', 'b1-2', 'b1-10'],
      'wrong_ids': ['b1-2', 'b1-u'],
    });
    final store = await ProgressStore.open();
    final book = _book([
      _w('b1-1', 'Unit 1'),
      _w('b1-2', 'Unit 1'),
      _w('b1-3', 'Unit 2'),
      _w('b1-10', 'Unit 10'),
      _w('b1-u', null),
      _w('b1-u2', ''),
    ]);
    final s = buildUnitProgress(book: book, store: store);
    expect(s.hasAnyUnit, isTrue);
    expect(s.rows.map((r) => r.unit).toList(), ['Unit 1', 'Unit 2', 'Unit 10', kUngroupedUnitLabel]);
    final u1 = s.rows.firstWhere((r) => r.unit == 'Unit 1');
    expect(u1.learned, 2);
    expect(u1.total, 2);
    expect(u1.wrong, 1);
    expect(u1.isComplete, isTrue);
    final u2 = s.rows.firstWhere((r) => r.unit == 'Unit 2');
    expect(u2.learned, 0);
    expect(u2.total, 1);
    expect(u2.wrong, 0);
    final ug = s.rows.last;
    expect(ug.isUngrouped, isTrue);
    expect(ug.total, 2);
    expect(ug.wrong, 1);
    expect(s.learned, 3);
    expect(s.total, 6);
    expect(s.wrong, 2);
  });

  test('all-empty units → hasAnyUnit false and no rows', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.open();
    final book = _book([_w('a', null), _w('b', '')]);
    final s = buildUnitProgress(book: book, store: store);
    expect(s.hasAnyUnit, isFalse);
    expect(s.rows, isEmpty);
    expect(s.total, 2);
  });

  test('compareUnitNames puts 未分 last and numbers in order', () {
    final names = ['Unit 10', 'Unit 2', kUngroupedUnitLabel, 'Unit 1'];
    names.sort(compareUnitNames);
    expect(names, ['Unit 1', 'Unit 2', 'Unit 10', kUngroupedUnitLabel]);
  });
}
