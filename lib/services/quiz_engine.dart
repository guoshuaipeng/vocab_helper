import 'dart:math';

import '../models/word.dart';

/// One multiple-choice item: Chinese prompt + English options.
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

/// Pure helpers for 「看中文选英文」.
enum SpellGrade { empty, correct, wrong }

/// Pure helpers for quiz variants.
class QuizEngine {
  QuizEngine._();

  /// Spelling grade: trim + case-insensitive; empty input is not wrong.
  static SpellGrade gradeSpell({required String input, required String target}) {
    final typed = input.trim();
    if (typed.isEmpty) return SpellGrade.empty;
    if (typed.toLowerCase() == target.trim().toLowerCase()) {
      return SpellGrade.correct;
    }
    return SpellGrade.wrong;
  }

  /// Session size: min(pool, max(5, dailyGoal)).
  static int sessionCap({required int poolSize, required int dailyGoal}) {
    if (poolSize <= 0) return 0;
    final goal = dailyGoal < 1 ? 20 : dailyGoal;
    final cap = max(5, goal);
    return min(poolSize, cap);
  }

  /// Build one question for [target]. Prefer same-unit distractors; fill from [bookWords].
  /// Returns null only when no second distinct spelling exists (single-word pool).
  static QuizQuestion? buildQuestion({
    required Word target,
    required List<Word> bookWords,
    Random? random,
    /// When true, distractors must have distinct Chinese meanings (听音选义 / 看词选义).
    bool listenMode = false,
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
    final usedMeanings = <String>{target.meaning.trim().toLowerCase()};

    void takeFrom(List<Word> pool, int need) {
      final shuffled = List<Word>.from(pool)..shuffle(rng);
      for (final w in shuffled) {
        if (distractors.length >= need) break;
        final key = w.word.toLowerCase();
        final meaningKey = w.meaning.trim().toLowerCase();
        if (usedIds.contains(w.id) || usedSpellings.contains(key)) continue;
        if (listenMode && (meaningKey.isEmpty || usedMeanings.contains(meaningKey))) continue;
        usedIds.add(w.id);
        usedSpellings.add(key);
        usedMeanings.add(meaningKey);
        distractors.add(w);
      }
    }

    takeFrom(sameUnit, 3);
    takeFrom(others, 3);
    if (distractors.isEmpty) {
      // Pool of 1: still return a single-option question for UI empty-hint path.
      return QuizQuestion(target: target, options: [target], correctIndex: 0);
    }

    final optionCount = (distractors.length + 1).clamp(2, 4);
    final picked = distractors.take(optionCount - 1).toList();
    final options = <Word>[target, ...picked]..shuffle(rng);
    final correctIndex = options.indexWhere((w) => w.id == target.id);
    return QuizQuestion(target: target, options: options, correctIndex: correctIndex);
  }

  /// Build a session: shuffle pool, cap by [dailyGoal], one question per target.
  static List<QuizQuestion> buildSession({
    required List<Word> pool,
    required List<Word> bookWords,
    int dailyGoal = 20,
    Random? random,
    bool listenMode = false,
  }) {
    final rng = random ?? Random();
    final targets = List<Word>.from(pool)..shuffle(rng);
    final limit = sessionCap(poolSize: targets.length, dailyGoal: dailyGoal);
    final out = <QuizQuestion>[];
    for (final t in targets.take(limit)) {
      final q = buildQuestion(
        target: t,
        bookWords: bookWords,
        random: rng,
        listenMode: listenMode,
      );
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

  /// R35: maintain this-round wrong ids (first-wrong order; correct removes).
  static List<String> applySessionWrong({
    required List<String> current,
    required String wordId,
    required bool correct,
  }) {
    final next = List<String>.from(current);
    if (correct) {
      next.removeWhere((id) => id == wordId);
    } else if (!next.contains(wordId)) {
      next.add(wordId);
    }
    return next;
  }

  /// R35: stable ordered words for retry (appearance order; missing ids skipped).
  static List<Word> wordsForRetry({
    required List<Word> bookWords,
    required List<String> wrongIdsInOrder,
  }) {
    final byId = {for (final w in bookWords) w.id: w};
    final out = <Word>[];
    final seen = <String>{};
    for (final id in wrongIdsInOrder) {
      if (seen.contains(id)) continue;
      seen.add(id);
      final w = byId[id];
      if (w != null) out.add(w);
    }
    return out;
  }

  /// R35: one question per wrong word, preserve order, no dailyGoal cap.
  static List<QuizQuestion> buildRetrySession({
    required List<Word> wrongWordsInOrder,
    required List<Word> bookWords,
    Random? random,
    bool listenMode = false,
  }) {
    final rng = random ?? Random();
    final out = <QuizQuestion>[];
    for (final t in wrongWordsInOrder) {
      final q = buildQuestion(
        target: t,
        bookWords: bookWords,
        random: rng,
        listenMode: listenMode,
      );
      if (q != null) out.add(q);
    }
    return out;
  }
}
