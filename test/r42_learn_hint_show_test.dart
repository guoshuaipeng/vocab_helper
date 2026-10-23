import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/learn_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/word_speaker.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';
import 'package:vocab_helper/theme/app_theme.dart';

Future<void> pumpLearn(WidgetTester tester, ProgressStore store, String bookId, {VoidCallback? onChangeBook}) async {
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
          bookId: bookId,
          onNeedSetup: () {},
          onChangeBook: onChangeBook ?? () {},
          speaker: FakeWordSpeaker(),
        ),
      ),
    ),
  );
  for (var i = 0; i < 80; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.byKey(const ValueKey('learn_flash_card')).evaluate().isNotEmpty ||
        find.byKey(const ValueKey('learn_recommend_switch_hint')).evaluate().isNotEmpty) {
      await tester.pump();
      return;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('R1 learn: pep-ps-3 shows hint', (tester) async {
    SharedPreferences.setMockInitialValues({'selected_book_id': 'pep-ps-3'});
    final store = await ProgressStore.open();
    await pumpLearn(tester, store, 'pep-ps-3');
    expect(find.byKey(const ValueKey('learn_recommend_switch_hint')), findsOneWidget);
    expect(find.text('跟课推荐 · 去切换'), findsOneWidget);
    expect(find.byKey(const ValueKey('learn_recommend_hint_dismiss')), findsOneWidget);
  });
}
