import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/expand_me_more.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/me_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';
import 'package:vocab_helper/theme/app_theme.dart';





void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-3',
      'daily_goal': 20,
      'learned_ids': ['pep-ps-3-1'],
      'today_count': 1,
      'streak_days': 1,
    });
  });

  Future<void> pumpMe(WidgetTester tester, {ThemeData? theme}) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = await ProgressStore.open();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light(),
        home: Scaffold(
          body: MeScreen(
            store: store,
            repo: WordbookRepository(),
            onRefresh: () {},
            onChangeBook: () {},
            onReviewWrong: () {},
            onReviewWrongCurrentUnit: () {},
            onQuizBook: () {},
            onQuizUnit: () {},
            onQuizWrong: () {},
          onStartDueReview: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('自测卡副文案点明看义/看词/听音/拼写，勿写仅四选一', (tester) async {
    await pumpMe(tester);

    await expandMeMore(tester);
    final sub = find.byKey(const ValueKey('me_quiz_card_subtitle'));
    for (var i = 0; i < 16 && sub.evaluate().isEmpty; i++) {
      final list = find.byType(Scrollable);
      if (list.evaluate().isEmpty) break;
      await tester.drag(list.first, const Offset(0, -350));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(sub, findsOneWidget);
    final text = tester.widget<Text>(sub).data ?? '';
    expect(text.contains('看义'), isTrue);
    expect(text.contains('看词'), isTrue);
    expect(text.contains('听音'), isTrue);
    expect(text.contains('拼写'), isTrue);
    expect(text.contains('错词'), isTrue);
    expect(text.contains('四选一'), isFalse);
    expect(find.textContaining('四选一'), findsNothing);
  });
}
