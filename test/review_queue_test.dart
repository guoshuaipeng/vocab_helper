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
}
