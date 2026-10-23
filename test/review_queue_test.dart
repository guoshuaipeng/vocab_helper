import 'package:flutter_test/flutter_test.dart';
import 'package:vocab_helper/models/word.dart';
import 'package:vocab_helper/services/review_queue.dart';

void main() {
  test('markKnown removes word and counts', () {
    final q = ReviewQueue([
      const Word(id: '1', word: 'a', meaning: '啊'),
      const Word(id: '2', word: 'b', meaning: '呗'),
    ]);
    q.markKnown();
    expect(q.remaining, 1);
    expect(q.knownCount, 1);
    expect(q.current?.id, '2');
  });

  test('markUnknown requeues to end', () {
    final q = ReviewQueue([
      const Word(id: '1', word: 'a', meaning: '啊'),
      const Word(id: '2', word: 'b', meaning: '呗'),
    ]);
    q.markUnknown();
    expect(q.remaining, 2);
    expect(q.current?.id, '2');
    expect(q.knownCount, 0);
  });

  test('filterWrongWords all wrong ids', () {
    final words = [
      const Word(id: 'a-1', word: 'cat', meaning: '猫', unit: 'U1'),
      const Word(id: 'a-2', word: 'dog', meaning: '狗', unit: 'U1'),
      const Word(id: 'a-3', word: 'bird', meaning: '鸟', unit: 'U2'),
    ];
    final out = filterWrongWords(words: words, wrongIds: {'a-1', 'a-3', 'x'});
    expect(out.map((w) => w.id).toList(), ['a-1', 'a-3']);
  });

  test('filterWrongWords scopes to unit', () {
    final words = [
      const Word(id: 'a-1', word: 'cat', meaning: '猫', unit: 'U1'),
      const Word(id: 'a-2', word: 'dog', meaning: '狗', unit: 'U1'),
      const Word(id: 'a-3', word: 'bird', meaning: '鸟', unit: 'U2'),
    ];
    final out = filterWrongWords(
      words: words,
      wrongIds: {'a-1', 'a-2', 'a-3'},
      unitFilter: 'U2',
    );
    expect(out.map((w) => w.id).toList(), ['a-3']);
  });

  test('filterWrongWords empty unit means all', () {
    final words = [
      const Word(id: 'a-1', word: 'cat', meaning: '猫', unit: 'U1'),
      const Word(id: 'a-3', word: 'bird', meaning: '鸟', unit: 'U2'),
    ];
    final out = filterWrongWords(words: words, wrongIds: {'a-1', 'a-3'}, unitFilter: '');
    expect(out.length, 2);
  });
}
