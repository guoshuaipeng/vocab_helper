import 'package:flutter_test/flutter_test.dart';
import 'package:vocab_helper/models/word.dart';
import 'package:vocab_helper/services/wrong_book_list.dart';

void main() {
  Word w(String id, String word, {String meaning = '义', String? unit}) => Word(
        id: id,
        word: word,
        meaning: meaning,
        unit: unit,
      );

  test('assemble filters to book words, sorts alpha, skips missing ids', () {
    final book = [
      w('pep-ps-3-2', 'banana', unit: 'U2'),
      w('pep-ps-3-1', 'Apple', unit: 'U1'),
      w('pep-ps-3-3', 'cat', unit: 'U1'),
    ];
    final wrong = ['pep-ps-3-3', 'pep-ps-3-1', 'pep-ps-3-missing', 'other-book-1'];
    final list = WrongBookList.assemble(book, wrong);
    expect(list.map((e) => e.word.toLowerCase()).toList(), ['apple', 'cat']);
    expect(list.map((e) => e.id).toList(), ['pep-ps-3-1', 'pep-ps-3-3']);
  });

  test('truncate reports more beyond cap', () {
    final all = [for (var i = 0; i < 45; i++) w('id-$i', 'w$i')];
    final t = WrongBookList.truncate(all, cap: 40);
    expect(t.shown.length, 40);
    expect(t.more, 5);
    final small = WrongBookList.truncate(all.take(3).toList(), cap: 40);
    expect(small.shown.length, 3);
    expect(small.more, 0);
  });
}