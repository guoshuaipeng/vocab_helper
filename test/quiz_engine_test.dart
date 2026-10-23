import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_helper/models/word.dart';
import 'package:vocab_helper/screens/quiz_screen.dart';
import 'package:vocab_helper/services/progress_store.dart';
import 'package:vocab_helper/services/quiz_engine.dart';
import 'package:vocab_helper/services/word_speaker.dart';
import 'package:vocab_helper/services/wordbook_repository.dart';

List<Word> sampleBook() => const [
      Word(id: 'b-1', word: 'apple', meaning: '苹果', unit: 'U1'),
      Word(id: 'b-2', word: 'banana', meaning: '香蕉', unit: 'U1'),
      Word(id: 'b-3', word: 'cat', meaning: '猫', unit: 'U1'),
      Word(id: 'b-4', word: 'dog', meaning: '狗', unit: 'U1'),
      Word(id: 'b-5', word: 'egg', meaning: '鸡蛋', unit: 'U2'),
      Word(id: 'b-6', word: 'fish', meaning: '鱼', unit: 'U2'),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuizEngine', () {
    test('buildQuestion prefers same-unit distractors and scores correctly', () {
      final book = sampleBook();
      final target = book.first;
      final q = QuizEngine.buildQuestion(
        target: target,
        bookWords: book,
        random: Random(42),
      );
      expect(q, isNotNull);
      expect(q!.options.length, 4);
      expect(q.options.where((w) => w.id == target.id).length, 1);
      expect(q.isCorrect(q.correctIndex), isTrue);
      expect(q.isCorrect((q.correctIndex + 1) % 4), isFalse);
      final distractors = q.options.where((w) => w.id != target.id);
      expect(distractors.every((w) => w.unit == 'U1'), isTrue);
    });

    test('buildQuestion fills from book when unit has fewer than 4 words', () {
      final book = sampleBook();
      final target = book.firstWhere((w) => w.id == 'b-5');
      final q = QuizEngine.buildQuestion(
        target: target,
        bookWords: book,
        random: Random(7),
      );
      expect(q, isNotNull);
      expect(q!.options.length, 4);
      expect(q.options.any((w) => w.id == 'b-6'), isTrue);
      expect(q.options.any((w) => w.unit == 'U1'), isTrue);
    });

    test('buildSession covers unit pool', () {
      final book = sampleBook();
      final pool = QuizEngine.poolForUnit(bookWords: book, unitFilter: 'U1');
      expect(pool.length, 4);
      final session = QuizEngine.buildSession(
        pool: pool,
        bookWords: book,
        random: Random(1),
      );
      expect(session.length, 4);
    });

    test('poolForUnit null or empty means whole book', () {
      final book = sampleBook();
      expect(QuizEngine.poolForUnit(bookWords: book, unitFilter: null).length, 6);
      expect(QuizEngine.poolForUnit(bookWords: book, unitFilter: '').length, 6);
    });
  });

  group('QuizScreen scoring', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({'selected_book_id': 'demo'});
    });

    testWidgets('wrong tap adds to wrong book; correct removes', (tester) async {
      final store = await ProgressStore.open();
      await store.markWrong('b-2'); // will be removed when answered correctly
      final book = sampleBook();

      final qWrong = QuizQuestion(
        target: book[0],
        options: [book[1], book[0], book[2], book[3]],
        correctIndex: 1,
      );
      final qRight = QuizQuestion(
        target: book[1],
        options: [book[0], book[1], book[2], book[3]],
        correctIndex: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: QuizScreen(
            store: store,
            repo: WordbookRepository(),
            mode: QuizMode.unit,
            speaker: FakeWordSpeaker(),
            seedQuestions: [qWrong, qRight],
            seedBookTitle: '测试词书',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('苹果'), findsOneWidget);

      // Wrong: tap banana
      await tester.tap(find.text('banana'));
      await tester.pumpAndSettle();
      expect(find.textContaining('正解'), findsOneWidget);
      expect(store.wrongIds().contains('b-1'), isTrue);

      await tester.tap(find.text('下一题'));
      await tester.pumpAndSettle();

      expect(find.text('香蕉'), findsOneWidget);
      expect(store.wrongIds().contains('b-2'), isTrue);

      // Correct: tap banana (target of qRight)
      await tester.tap(find.text('banana'));
      await tester.pumpAndSettle();
      expect(find.text('答对了！'), findsOneWidget);
      expect(store.wrongIds().contains('b-2'), isFalse);
      expect(store.wrongIds().contains('b-1'), isTrue);
    });
  });
}
