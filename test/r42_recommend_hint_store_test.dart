import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/services/progress_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('recommend hint hidden only for today ymd', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.open();
    final now = DateTime(2026, 10, 23);
    expect(store.isRecommendHintHiddenToday(now: now), isFalse);
    await store.dismissRecommendHintForToday(now: now);
    expect(store.isRecommendHintHiddenToday(now: now), isTrue);
    expect(store.isRecommendHintHiddenToday(now: DateTime(2026, 10, 24)), isFalse);
  });
}
