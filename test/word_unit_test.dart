import 'package:flutter_test/flutter_test.dart';
import 'package:vocab_helper/models/word.dart';

void main() {
  test('withUnits chunks when missing unit labels', () {
    final words = [
      for (var i = 1; i <= 20; i++) Word(id: 'b-$i', word: 'w$i', meaning: '义$i'),
    ];
    final book = WordBook(
      id: 'b',
      version: '测',
      grade: '一',
      title: '测',
      source: 't',
      words: words,
    ).withUnits(chunkSize: 15);
    expect(book.unitNames(), ['第1组', '第2组']);
    expect(book.words.where((w) => w.unit == '第1组').length, 15);
    expect(book.words.where((w) => w.unit == '第2组').length, 5);
  });

  test('withUnits keeps existing unit labels', () {
    final book = WordBook(
      id: 'b',
      version: '测',
      grade: '一',
      title: '测',
      source: 't',
      words: const [
        Word(id: '1', word: 'a', meaning: '啊', unit: 'Unit 1'),
        Word(id: '2', word: 'b', meaning: '呗', unit: 'Unit 2'),
      ],
    ).withUnits();
    expect(book.unitNames(), ['Unit 1', 'Unit 2']);
  });
}