import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/books_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';
import 'package:vocab_helper/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('books screen marks recommended', (tester) async {
    SharedPreferences.setMockInitialValues({
      'selected_book_id': WordbookRepository.recommendedBookId,
    });
    final store = await ProgressStore.open();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: BooksScreen(
          store: store,
          repo: WordbookRepository(),
          selectedBookId: WordbookRepository.recommendedBookId,
          onChangeBook: () {},
          onBookSelected: () {},
        ),
      ),
    ));
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byType(ListView).evaluate().isNotEmpty) break;
    }
    expect(find.byType(ListView), findsOneWidget);
    final badge = find.byKey(const ValueKey('books_recommended'));
    await tester.scrollUntilVisible(badge, 400, scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(milliseconds: 100));
    expect(badge, findsOneWidget);
    expect(find.textContaining('推荐'), findsWidgets);
  });
}