import 'dart:async';

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

  // Both scenarios in one testWidgets — separate testWidgets back-to-back flake
  // on Setup rebuild (hint missing) under this suite's prefs/surface lifecycle.
  testWidgets('Setup preselects recommend; pep-ps-3 selection is kept', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // --- existing pep-ps-3 is kept (not forced to recommend) ---
    SharedPreferences.setMockInitialValues({'selected_book_id': 'pep-ps-3'});
    var store = await ProgressStore.open();
    expect(store.selectedBookId(), 'pep-ps-3');
    final doneKeep = Completer<void>();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: SetupScreen(
        store: store,
        repo: WordbookRepository(),
        onDone: doneKeep.complete,
      ),
    ));
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const ValueKey('setup_recommend_hint')), findsOneWidget);
    expect(find.byKey(const ValueKey('setup_book_recommended')), findsNothing);
    await tester.ensureVisible(find.text('开始学习'));
    await tester.tap(find.text('开始学习'));
    await doneKeep.future.timeout(const Duration(seconds: 2));
    await tester.pump();
    expect(store.selectedBookId(), 'pep-ps-3');
    expect(store.selectedBookId(), isNot(WordbookRepository.recommendedBookId));

    // --- no selection preselects recommended 2024 book ---
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    SharedPreferences.setMockInitialValues({});
    store = await ProgressStore.open();
    expect(store.selectedBookId(), isNull);
    final donePre = Completer<void>();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: SetupScreen(
        store: store,
        repo: WordbookRepository(),
        onDone: donePre.complete,
      ),
    ));
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const ValueKey('setup_recommend_hint')), findsOneWidget);
    expect(find.byKey(const ValueKey('setup_book_recommended')), findsOneWidget);
    await tester.ensureVisible(find.text('开始学习'));
    await tester.tap(find.text('开始学习'));
    await donePre.future.timeout(const Duration(seconds: 2));
    await tester.pump();
    expect(store.selectedBookId(), WordbookRepository.recommendedBookId);
  });
}
