import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/learn_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('flip card and mark known/unknown', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.open();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LearnScreen(store: store)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('点按卡片看中文'), findsOneWidget);

    await tester.tap(find.byType(Card));
    await tester.pumpAndSettle();
    expect(find.text('点按卡片可翻回'), findsOneWidget);

    await tester.tap(find.text('不认识'));
    await tester.pumpAndSettle();
    expect(find.textContaining('剩余'), findsOneWidget);

    await tester.tap(find.text('认识'));
    await tester.pumpAndSettle();
    expect(find.textContaining('本轮认识'), findsOneWidget);
  });
}
