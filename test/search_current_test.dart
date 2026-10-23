import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/books_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';
import 'package:vocab_helper/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tapping current book shows already-this snackbar', (tester) async {
    SharedPreferences.setMockInitialValues({'selected_book_id': 'pep-ps-3'});
    tester.view.physicalSize = const Size(390, 920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = await ProgressStore.open();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: BooksScreen(
            store: store,
            repo: WordbookRepository(),
            selectedBookId: 'pep-ps-3',
            onChangeBook: () {},
            onBookSelected: () {},
          ),
        ),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Find a selected card / list tile and tap it.
    // Catalog cards: look for check icon or selected styling ? tap by scrolling to pep title.
    final title = find.textContaining('三年级');
    expect(title, findsWidgets);
    await tester.ensureVisible(title.first);
    await tester.pump();
    await tester.tap(title.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('已经是这本'), findsOneWidget);
    // No switch dialog
    expect(find.textContaining('切换到这本'), findsNothing);
  });
}
