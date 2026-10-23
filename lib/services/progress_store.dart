import 'package:shared_preferences/shared_preferences.dart';

class ProgressStore {
  ProgressStore(this._prefs);

  final SharedPreferences _prefs;

  static const _kLearned = 'learned_ids';
  static const _kWrong = 'wrong_ids';
  static const _kTodayCount = 'today_count';
  static const _kTodayDate = 'today_date';
  static const _kStreak = 'streak_days';
  static const _kLastActive = 'last_active_date';
  static const _kBookId = 'selected_book_id';
  static const _kDailyGoal = 'daily_goal';
  static const _kUnitFilterPrefix = 'unit_filter_';
  static const _kTtsAccent = 'tts_accent';
  static const _kAutoSpeak = 'auto_speak';
  static const _kQuizVariant = 'quiz_variant';

  static Future<ProgressStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    return ProgressStore(prefs);
  }

  String? selectedBookId() => _prefs.getString(_kBookId);

  Future<void> setSelectedBookId(String id) async {
    await _prefs.setString(_kBookId, id);
  }

  bool get hasSelectedBook => selectedBookId() != null && selectedBookId()!.isNotEmpty;

  String _todayKey() => dateKey();


  static const _kReviewAtPrefix = 'review_at_';
  static const _kReviewStagePrefix = 'review_stage_';

  /// Interval days for stage 0/1/2/3 → 1 / 3 / 7 / 7.
  static int daysForStage(int stage) {
    const days = [1, 3, 7, 7];
    final i = stage.clamp(0, 3);
    return days[i];
  }

  static String dateKey([DateTime? now]) {
    final n = now ?? DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  static String addDaysToDateKey(String ymd, int days) {
    final d = DateTime.tryParse(ymd) ?? DateTime.now();
    final n = d.add(Duration(days: days));
    return dateKey(n);
  }

  String? reviewAt(String wordId) => _prefs.getString('$_kReviewAtPrefix$wordId');

  int? reviewStage(String wordId) => _prefs.getInt('$_kReviewStagePrefix$wordId');

  bool isReviewDue(String wordId, {DateTime? now}) {
    final at = reviewAt(wordId);
    if (at == null || at.isEmpty) return false;
    return at.compareTo(dateKey(now)) <= 0;
  }

  /// Never learned, or learned but due today/overdue.
  bool inLearnQueue(String wordId, {DateTime? now}) {
    if (!learnedIds().contains(wordId)) return true;
    return isReviewDue(wordId, now: now);
  }

  int dueReviewCountForBook(String bookId, {DateTime? now}) {
    final prefix = '$bookId-';
    final today = dateKey(now);
    var n = 0;
    for (final id in learnedIds()) {
      if (!id.startsWith(prefix)) continue;
      final at = reviewAt(id);
      if (at != null && at.compareTo(today) <= 0) n++;
    }
    return n;
  }

  int newWordCountInScope(Iterable<String> wordIds) {
    final learned = learnedIds();
    return wordIds.where((id) => !learned.contains(id)).length;
  }

  Future<void> _setReview(String wordId, {required int stage, required String at}) async {
    await _prefs.setInt('$_kReviewStagePrefix$wordId', stage.clamp(0, 3));
    await _prefs.setString('$_kReviewAtPrefix$wordId', at);
  }

  Future<void> _clearReview(String wordId) async {
    await _prefs.remove('$_kReviewStagePrefix$wordId');
    await _prefs.remove('$_kReviewAtPrefix$wordId');
  }

  /// After 「认识」: first time → stage0 +1d; due again → stage+1 capped, bucket days.
  Future<void> advanceReviewAfterKnown(String wordId, {DateTime? now}) async {
    final today = dateKey(now);
    final cur = reviewStage(wordId);
    if (cur == null) {
      await _setReview(wordId, stage: 0, at: addDaysToDateKey(today, daysForStage(0)));
    } else {
      final next = (cur + 1).clamp(0, 3);
      await _setReview(wordId, stage: next, at: addDaysToDateKey(today, daysForStage(next)));
    }
  }

  /// 「不认识」/自测选错：回 1 天桶.
  Future<void> resetReviewAfterUnknown(String wordId, {DateTime? now}) async {
    final today = dateKey(now);
    await _setReview(wordId, stage: 0, at: addDaysToDateKey(today, daysForStage(0)));
  }



  Set<String> learnedIds() {
    return (_prefs.getStringList(_kLearned) ?? const <String>[]).toSet();
  }

  Set<String> wrongIds() {
    return (_prefs.getStringList(_kWrong) ?? const <String>[]).toSet();
  }

  int learnedCount() => learnedIds().length;

  int wrongCount() => wrongIds().length;

  int learnedCountForBook(String bookId) {
    final prefix = '$bookId-';
    return learnedIds().where((id) => id.startsWith(prefix)).length;
  }

  int wrongCountForBook(String bookId) {
    final prefix = '$bookId-';
    return wrongIds().where((id) => id.startsWith(prefix)).length;
  }

  Future<int> clearLearnedForBook(String bookId) async {
    final prefix = '$bookId-';
    final before = learnedIds();
    final removedIds = before.where((id) => id.startsWith(prefix)).toList();
    final kept = before.where((id) => !id.startsWith(prefix)).toList();
    final removed = removedIds.length;
    await _prefs.setStringList(_kLearned, kept);
    for (final id in removedIds) {
      await _clearReview(id);
    }
    // Also clear orphan review keys for this book prefix
    for (final key in _prefs.getKeys()) {
      if (key.startsWith('$_kReviewAtPrefix$prefix') || key.startsWith('$_kReviewStagePrefix$prefix')) {
        await _prefs.remove(key);
      }
    }
    return removed;
  }

  Future<int> clearWrongForBook(String bookId) async {
    final prefix = '$bookId-';
    final before = wrongIds();
    final kept = before.where((id) => !id.startsWith(prefix)).toList();
    final removed = before.length - kept.length;
    await _prefs.setStringList(_kWrong, kept);
    return removed;
  }

  int todayCount() {
    final today = _todayKey();
    if (_prefs.getString(_kTodayDate) != today) return 0;
    return _prefs.getInt(_kTodayCount) ?? 0;
  }

  int streakDays() => _prefs.getInt(_kStreak) ?? 0;

  int dailyGoal() => _prefs.getInt(_kDailyGoal) ?? 20;

  Future<void> setDailyGoal(int n) async {
    final v = n.clamp(5, 200);
    await _prefs.setInt(_kDailyGoal, v);
  }

  bool get todayGoalMet => todayCount() >= dailyGoal();

  /// en-US = 美音, en-GB = 英音
  String ttsAccent() {
    final v = _prefs.getString(_kTtsAccent);
    if (v == 'en-GB') return 'en-GB';
    return 'en-US';
  }

  Future<void> setTtsAccent(String code) async {
    final v = code == 'en-GB' ? 'en-GB' : 'en-US';
    await _prefs.setString(_kTtsAccent, v);
  }

  bool autoSpeak() => _prefs.getBool(_kAutoSpeak) ?? false;

  Future<void> setAutoSpeak(bool v) async {
    await _prefs.setBool(_kAutoSpeak, v);
  }

  /// `meaning` = 看义选词；`listen` = 听音选义.
  String quizVariant() {
    final v = _prefs.getString(_kQuizVariant);
    return v == 'listen' ? 'listen' : 'meaning';
  }

  Future<void> setQuizVariant(String variant) async {
    final v = variant == 'listen' ? 'listen' : 'meaning';
    await _prefs.setString(_kQuizVariant, v);
  }

  String? unitFilterForBook(String bookId) => _prefs.getString('$_kUnitFilterPrefix$bookId');

  Future<void> setUnitFilterForBook(String bookId, String? unit) async {
    final key = '$_kUnitFilterPrefix$bookId';
    if (unit == null || unit.isEmpty) {
      await _prefs.remove(key);
    } else {
      await _prefs.setString(key, unit);
    }
  }

  Future<void> markLearned(String id, {DateTime? now}) async {
    final ids = learnedIds();
    final first = !ids.contains(id);
    if (first) {
      ids.add(id);
      await _prefs.setStringList(_kLearned, ids.toList());
      await bumpTodayCount();
      // 首次认识：固定进 1 天桶（即使此前点过「不认识」写过 stage）
      final today = dateKey(now);
      await _setReview(id, stage: 0, at: addDaysToDateKey(today, daysForStage(0)));
    } else {
      await bumpTodayCount();
      await advanceReviewAfterKnown(id, now: now);
    }
    await removeWrong(id);
  }


  /// Increment today's activity count without marking a word learned (e.g. quiz correct).
  Future<void> bumpTodayCount() async {
    final today = _todayKey();
    if (_prefs.getString(_kTodayDate) != today) {
      await _prefs.setString(_kTodayDate, today);
      await _prefs.setInt(_kTodayCount, 1);
    } else {
      await _prefs.setInt(_kTodayCount, todayCount() + 1);
    }
    await _updateStreak(today);
  }
  Future<void> markWrong(String id, {DateTime? now}) async {
    final ids = wrongIds();
    if (!ids.contains(id)) {
      ids.add(id);
      await _prefs.setStringList(_kWrong, ids.toList());
    }
    await resetReviewAfterUnknown(id, now: now);
  }

  Future<void> removeWrong(String id) async {
    final ids = wrongIds();
    if (!ids.contains(id)) return;
    ids.remove(id);
    await _prefs.setStringList(_kWrong, ids.toList());
  }


  Future<void> touchActive() async {
    await _updateStreak(_todayKey());
  }

  Future<void> _updateStreak(String today) async {
    final last = _prefs.getString(_kLastActive);
    if (last == today) return;

    if (last == null) {
      await _prefs.setInt(_kStreak, 1);
    } else {
      final lastDate = DateTime.tryParse(last);
      final todayDate = DateTime.tryParse(today);
      if (lastDate != null && todayDate != null) {
        final diff = todayDate.difference(lastDate).inDays;
        if (diff == 1) {
          await _prefs.setInt(_kStreak, streakDays() + 1);
        } else if (diff > 1) {
          await _prefs.setInt(_kStreak, 1);
        }
      } else {
        await _prefs.setInt(_kStreak, 1);
      }
    }
    await _prefs.setString(_kLastActive, today);
  }
}