import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/setup_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';
import 'package:vocab_helper/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('recommendedBookId is 沪教牛津 2024 七上', () {
    expect(WordbookRepository.recommendedBookId, 'hj-ox-7a-2024');
  });

  testWidgets('no selection preselects recommended 2024 book', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.open();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: SetupScreen(store: store, repo: WordbookRepository(), onDone: () {}),
    ));
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const ValueKey('setup_recommend_hint')), findsOneWidget);
    expect(find.byKey(const ValueKey('setup_book_recommended')), findsOneWidget);
    await tester.ensureVisible(find.text('开始学习'));
    await tester.tap(find.text('开始学习'));
    await tester.pump();
    expect(store.selectedBookId(), WordbookRepository.recommendedBookId);
  });
}