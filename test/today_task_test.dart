import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/screens/learn_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/word_speaker.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'selected_book_id': 'pep-ps-3',
      'daily_goal': 20,
    });
  });

  Future<void> pumpLearn(
    WidgetTester tester, {
    required ProgressStore store,
    VoidCallback? onLearn,
    VoidCallback? onWrong,
    VoidCallback? onQuiz,
  }) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LearnScreen(
            store: store,
            repo: WordbookRepository(),
            bookId: 'pep-ps-3',
            onNeedSetup: () {},
            speaker: FakeWordSpeaker(),
            onLearnNew: onLearn,
            onReviewWrongAll: onWrong,
            onStartQuiz: onQuiz,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    for (var i = 0; i < 30; i++) {
      if (find.byKey(const ValueKey('today_task_learn')).evaluate().isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('今日任务 three keys; quiz/learn tap; wrong disabled when empty', (tester) async {
    final store = await ProgressStore.open();
    var learnTaps = 0;
    var wrongTaps = 0;
    var quizTaps = 0;

    await pumpLearn(
      tester,
      store: store,
      onLearn: () => learnTaps++,
      onWrong: () => wrongTaps++,
      onQuiz: () => quizTaps++,
    );

    expect(find.byKey(const ValueKey('today_task_learn')), findsOneWidget);
    expect(find.byKey(const ValueKey('today_task_wrong')), findsOneWidget);
    expect(find.byKey(const ValueKey('today_task_quiz')), findsOneWidget);
    expect(find.text('学新词'), findsOneWidget);
    expect(find.text('复习错词'), findsOneWidget);
    expect(find.text('测一测'), findsOneWidget);
    expect(find.textContaining('暂无错词'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('today_task_quiz')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(quizTaps, 1);

    await tester.tap(find.byKey(const ValueKey('today_task_wrong')));
    await tester.pump();
    expect(wrongTaps, 0);

    await tester.tap(find.byKey(const ValueKey('today_task_learn')));
    await tester.pump();
    expect(learnTaps, 1);
  });

  test('wrongCountForBook drives 复习错词 enablement data', () async {
    final store = await ProgressStore.open();
    expect(store.wrongCountForBook('pep-ps-3'), 0);
    await store.markWrong('pep-ps-3-1');
    expect(store.wrongCountForBook('pep-ps-3'), 1);
    await store.removeWrong('pep-ps-3-1');
    expect(store.wrongCountForBook('pep-ps-3'), 0);
  });
}
