import 'package:flutter_test/flutter_test.dart';
import 'package:vocab_helper/models/word.dart';
import 'package:vocab_helper/services/progress_export.dart';

Word w(String id, String word, String meaning) =>
    Word(id: id, word: word, meaning: meaning, unit: 'U1');

void main() {
  test('build sorts lists and fills header fields', () {
    final text = ProgressExport.build(
      bookTitle: 'PEP 3',
      date: DateTime(2026, 10, 23),
      totalCount: 100,
      streak: 3,
      learned: [w('a-2', 'zebra', 'zebra-m'), w('a-1', 'apple', 'apple-m')],
      wrong: [w('a-3', 'cat', 'cat-m')],
    );
    expect(text, contains('单词小助手'));
    expect(text, contains('词书：PEP 3'));
    expect(text, contains('2026-10-23'));
    expect(text, contains('已学：2/100'));
    expect(text, contains('错词：1'));
    expect(text, contains('连续学习：3 天'));
    expect(text, contains('【已学单词】'));
    // lexical order apple before zebra
    final learnedBlock = text.split('【错词】').first;
    expect(learnedBlock.indexOf('apple'), lessThan(learnedBlock.indexOf('zebra')));
    expect(text, contains('apple — apple-m'));
    expect(text, contains('cat — cat-m'));
  });

  test('empty lists show placeholder', () {
    final text = ProgressExport.build(
      bookTitle: 'X',
      date: DateTime(2026, 1, 2),
      totalCount: 10,
      streak: 0,
      learned: const [],
      wrong: const [],
    );
    expect(text, contains('已学：0/10'));
    expect(text, contains('（暂无）'));
  });

  test('wordsInSet filters by id', () {
    final book = [w('b-1', 'a', 'A'), w('b-2', 'b', 'B')];
    final got = ProgressExport.wordsInSet(book, {'b-2'});
    expect(got.map((e) => e.id).toList(), ['b-2']);
  });
}
