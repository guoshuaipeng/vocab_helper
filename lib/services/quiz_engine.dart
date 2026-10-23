import 'dart:math';

import '../models/word.dart';

/// One multiple-choice item: Chinese prompt, four English options.
class QuizQuestion {
  const QuizQuestion({
    required this.target,
    required this.options,
    required this.correctIndex,
  });

  final Word target;
  final List<Word> options;
  final int correctIndex;

  String get promptMeaning => target.meaning;

  bool isCorrect(int selectedIndex) => selectedIndex == correctIndex;
}

/// Pure helpers for building and scoring 「看中文选英文」 questions.
class QuizEngine {
  QuizEngine._();

  /// Build one question for [target]. Prefer same-unit distractors; fill from [bookWords].
  /// Returns null if fewer than 2 distinct English options can be formed.
  static QuizQuestion? buildQuestion({
    required Word target,
    required List<Word> bookWords,
    Random? random,
  }) {
    final rng = random ?? Random();
    final unit = (target.unit ?? '').trim();

    final sameUnit = bookWords
        .where((w) => w.id != target.id && (w.unit ?? '') == unit && unit.isNotEmpty)
        .toList();
    final others = bookWords.where((w) => w.id != target.id).toList();

    final distractors = <Word>[];
    final usedIds = <String>{target.id};
    final usedSpellings = <String>{target.word.toLowerCase()};

    void takeFrom(List<Word> pool, int need) {
      final shuffled = List<Word>.from(pool)..shuffle(rng);
      for (final w in shuffled) {
        if (distractors.length >= need) break;
        final key = w.word.toLowerCase();
        if (usedIds.contains(w.id) || usedSpellings.contains(key)) continue;
        usedIds.add(w.id);
        usedSpellings.add(key);
        distractors.add(w);
      }
    }

    takeFrom(sameUnit, 3);
    takeFrom(others, 3);
    if (distractors.isEmpty) return null;

    // Prefer 4 options; allow 2–3 when the book is tiny.
    final optionCount = (distractors.length + 1).clamp(2, 4);
    final picked = distractors.take(optionCount - 1).toList();
    final options = <Word>[target, ...picked]..shuffle(rng);
    final correctIndex = options.indexWhere((w) => w.id == target.id);
    return QuizQuestion(target: target, options: options, correctIndex: correctIndex);
  }

  /// Build a session: one question per word in [pool], order shuffled.
  static List<QuizQuestion> buildSession({
    required List<Word> pool,
    required List<Word> bookWords,
    Random? random,
  }) {
    final rng = random ?? Random();
    final targets = List<Word>.from(pool)..shuffle(rng);
    final out = <QuizQuestion>[];
    for (final t in targets) {
      final q = buildQuestion(target: t, bookWords: bookWords, random: rng);
      if (q != null) out.add(q);
    }
    return out;
  }

  /// Words to quiz for current-unit / whole-book mode.
  static List<Word> poolForUnit({
    required List<Word> bookWords,
    String? unitFilter,
  }) {
    if (unitFilter == null || unitFilter.isEmpty) {
      return List<Word>.from(bookWords);
    }
    return bookWords.where((w) => w.unit == unitFilter).toList();
  }
}
