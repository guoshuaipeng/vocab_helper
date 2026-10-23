import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/learn_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/word_speaker.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';
import 'package:vocab_helper/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('R2 learn: recommended hides hint', (tester) async {
    SharedPreferences.setMockInitialValues({
      'selected_book_id': WordbookRepository.recommendedBookId,
    });
    final store = await ProgressStore.open();
    tester.view.physicalSize = const Size(390, 920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: LearnScreen(
            store: store,
            repo: WordbookRepository(),
            bookId: WordbookRepository.recommendedBookId,
            onNeedSetup: () {},
            onChangeBook: () {},
            speaker: FakeWordSpeaker(),
          ),
        ),
      ),
    );
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const ValueKey('learn_flash_card')).evaluate().isNotEmpty) break;
    }
    expect(find.byKey(const ValueKey('learn_recommend_switch_hint')), findsNothing);
  });
}
