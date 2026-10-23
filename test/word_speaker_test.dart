import 'package:flutter_test/flutter_test.dart';
import 'package:vocab_helper/services/word_speaker.dart';

void main() {
  test('FakeWordSpeaker records speak and stop', () async {
    final s = FakeWordSpeaker();
    await s.speak('apple');
    await s.speak('book');
    await s.stop();
    expect(s.spoken, ['apple', 'book']);
    expect(s.stopped, isTrue);
  });

  test('FakeWordSpeaker ignores blank after trim via caller contract', () async {
    final s = FakeWordSpeaker();
    await s.speak('hi');
    expect(s.spoken.single, 'hi');
  });
}