import 'package:flutter_test/flutter_test.dart';
import 'package:vocab_helper/models/word.dart';
import 'package:vocab_helper/services/review_queue.dart';

void main() {
  test('learn queue flip path stays consistent', () {
    final q = ReviewQueue([
      const Word(id: '1', word: 'apple', meaning: '苹果'),
      const Word(id: '2', word: 'book', meaning: '书'),
    ]);
    expect(q.current?.word, 'apple');
    q.markUnknown();
    expect(q.current?.word, 'book');
    q.markKnown();
    expect(q.current?.word, 'apple');
  });
}