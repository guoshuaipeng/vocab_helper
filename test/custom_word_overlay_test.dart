import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/models/word.dart';
import 'package:vocab_helper/services/custom_word_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('addWords persists and skips duplicate spelling', () async {
    SharedPreferences.setMockInitialValues({});
    final overlay = await CustomWordOverlay.open();
    final a = Word(
      id: CustomWordOverlay.newId('b1', 'zebra'),
      word: 'zebra',
      meaning: '斑马',
      unit: 'Unit X',
    );
    final n1 = await overlay.addWords('b1', [a]);
    expect(n1, 1);
    final n2 = await overlay.addWords('b1', [
      Word(
        id: CustomWordOverlay.newId('b1', 'zebra'),
        word: 'Zebra',
        meaning: '又一只',
        unit: 'Unit Y',
      ),
    ]);
    expect(n2, 0);
    final list = await overlay.wordsForBook('b1');
    expect(list.length, 1);
    expect(list.first.meaning, '斑马');
    expect(list.first.unit, 'Unit X');
  });
}
