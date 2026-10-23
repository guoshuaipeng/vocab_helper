import 'package:flutter_test/flutter_test.dart';
import 'package:vocab_helper/models/word.dart';
import 'package:vocab_helper/services/ocr_word_extract.dart';

void main() {
  test('extractEnglishTokens filters stopwords, digits, short, dupes', () {
    const raw = '''
Unit 1 Hello!
apple Apple APPLE
a the is 12 xx
friend-ship can't
go
''';
    final tokens = extractEnglishTokens(raw);
    expect(tokens.map((t) => t.toLowerCase()), containsAll(['hello', 'apple', "can't"]));
    expect(tokens.any((t) => t.toLowerCase() == 'the'), isFalse);
    expect(tokens.where((t) => t.toLowerCase() == 'apple').length, 1);
    expect(tokens.any((t) => t == '12'), isFalse);
  });

  test('matchTokensToBook marks inBook vs newWord', () {
    final book = [
      const Word(id: '1', word: 'apple', meaning: '苹果'),
      const Word(id: '2', word: 'friend', meaning: '朋友'),
    ];
    final cands = matchTokensToBook(['Apple', 'banana', 'friend'], book);
    expect(cands.length, 3);
    expect(cands[0].kind, OcrMatchKind.inBook);
    expect(cands[0].meaning, '苹果');
    expect(cands[0].selected, isFalse);
    expect(cands[1].kind, OcrMatchKind.newWord);
    expect(cands[1].selected, isTrue);
    expect(cands[1].canLearn, isFalse);
    expect(cands[2].kind, OcrMatchKind.inBook);
  });
}

