import 'package:shared_preferences/shared_preferences.dart';

/// 本周打卡格状态（自然周周一～周日）。
enum CheckInDayStatus {
  /// 有记录且 count ≥ goal
  met,

  /// 有记录且 count < goal（仅过去日）
  missed,

  /// 过去日无键
  empty,

  /// 今天且尚未达标
  todayProgress,

  /// 本周内未来日
  future,
}

class CheckInDay {
  const CheckInDay({
    required this.ymd,
    required this.weekday,
    required this.status,
    this.count,
  });

  final String ymd;

  /// DateTime.weekday：1=周一 … 7=周日
  final int weekday;
  final CheckInDayStatus status;
  final int? count;
}

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
  static const _kDayCountPrefix = 'day_count_';
  static const _kGoalCelebratedYmd = 'goal_celebrated_ymd';

  static Future<ProgressStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    return ProgressStore(prefs);
  }

  String? selectedBookId() => _prefs.getString(_kBookId);

  Future<void> setSelectedBookId(String id) async {
    await _prefs.setString(_kBookId, id);
  }

  bool get hasSelectedBook => selectedBookId() != null && selectedBookId()!.isNotEmpty;

  static const _kReviewAtPrefix = 'review_at_';
  static const _kReviewStagePrefix = 'review_stage_';
  static const _kReviewNextHint = 'review_next_hint_enabled';

  /// R38 max stage (0..4 → 1/3/7/14/30 days).
  static const int maxReviewStage = 4;

  /// Interval days for stage 0/1/2/3/4 → 1 / 3 / 7 / 14 / 30.
  static int daysForStage(int stage) {
    const days = [1, 3, 7, 14, 30];
    final i = stage.clamp(0, maxReviewStage);
    return days[i];
  }

  /// Kid-friendly label for the next review after landing on [stage].
  static String labelForStage(int stage) {
    switch (stage.clamp(0, maxReviewStage)) {
      case 0:
        return '明天复习';
      case 1:
        return '3天后';
      case 2:
        return '约一周';
      case 3:
        return '约两周';
      default:
        return '约一个月';
    }
  }

  static String nextReviewHintForStage(int stage) =>
      '下次 · ${labelForStage(stage)}';

  /// Show next-review tip after 认识. Default on; can disable.
  bool reviewNextHintEnabled() => _prefs.getBool(_kReviewNextHint) ?? true;

  Future<void> setReviewNextHintEnabled(bool enabled) async {
    await _prefs.setBool(_kReviewNextHint, enabled);
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
    return dueReviewEntriesForBook(bookId, now: now).length;
  }

  /// Due reviews for [bookId]: earliest [reviewAt] first; same day by id.
  /// Caller may re-sort by word spelling after resolving [Word]s.
  List<({String id, String at})> dueReviewEntriesForBook(String bookId, {DateTime? now}) {
    final prefix = '$bookId-';
    final today = dateKey(now);
    final out = <({String id, String at})>[];
    for (final id in learnedIds()) {
      if (!id.startsWith(prefix)) continue;
      final at = reviewAt(id);
      if (at != null && at.isNotEmpty && at.compareTo(today) <= 0) {
        out.add((id: id, at: at));
      }
    }
    out.sort((a, b) {
      final c = a.at.compareTo(b.at);
      if (c != 0) return c;
      return a.id.compareTo(b.id);
    });
    return out;
  }

  int newWordCountInScope(Iterable<String> wordIds) {
    final learned = learnedIds();
    return wordIds.where((id) => !learned.contains(id)).length;
  }

  Future<void> _setReview(String wordId, {required int stage, required String at}) async {
    await _prefs.setInt('$_kReviewStagePrefix$wordId', stage.clamp(0, maxReviewStage));
    await _prefs.setString('$_kReviewAtPrefix$wordId', at);
  }

  Future<void> _clearReview(String wordId) async {
    await _prefs.remove('$_kReviewStagePrefix$wordId');
    await _prefs.remove('$_kReviewAtPrefix$wordId');
  }

  /// After 「认识」: first time → stage0 +1d; due again → stage+1 capped at 4, bucket days.
  Future<void> advanceReviewAfterKnown(String wordId, {DateTime? now}) async {
    final today = dateKey(now);
    final cur = reviewStage(wordId);
    if (cur == null) {
      await _setReview(wordId, stage: 0, at: addDaysToDateKey(today, daysForStage(0)));
    } else {
      final next = (cur + 1).clamp(0, maxReviewStage);
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

  int todayCount({DateTime? now}) {
    final today = dateKey(now);
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

  /// `meaning` | `word` | `listen` | `spell` | `dictation` (听写).
  String quizVariant() {
    final v = _prefs.getString(_kQuizVariant);
    if (v == 'listen' || v == 'spell' || v == 'word' || v == 'dictation') return v!;
    return 'meaning';
  }

  Future<void> setQuizVariant(String variant) async {
    final v = (variant == 'listen' ||
            variant == 'spell' ||
            variant == 'word' ||
            variant == 'dictation')
        ? variant
        : 'meaning';
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

  /// 跨日：先把昨日桶写入 `day_count_yyyy-MM-dd`，再清零今日。
  Future<void> ensureDayRolled({DateTime? now}) => _archiveIfRolled(now);

  Future<void> _archiveIfRolled(DateTime? now) async {
    final today = dateKey(now);
    final stored = _prefs.getString(_kTodayDate);
    if (stored == null || stored == today) return;
    final count = _prefs.getInt(_kTodayCount) ?? 0;
    await _prefs.setInt('$_kDayCountPrefix$stored', count);
    await _prefs.setString(_kTodayDate, today);
    await _prefs.setInt(_kTodayCount, 0);
  }

  /// 某日学词数。`null` = 无记录（无归档键且非当前今日桶）。
  int? dayCountFor(String ymd, {DateTime? now}) {
    final storedDate = _prefs.getString(_kTodayDate);
    if (storedDate == ymd) {
      return _prefs.getInt(_kTodayCount) ?? 0;
    }
    final key = '$_kDayCountPrefix$ymd';
    if (!_prefs.containsKey(key)) return null;
    return _prefs.getInt(key) ?? 0;
  }

  /// 含 [now] 的自然周（周一～周日）七格状态。
  List<CheckInDay> weekCheckIns({DateTime? now}) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final goal = dailyGoal();
    return List<CheckInDay>.generate(7, (i) {
      final d = DateTime(monday.year, monday.month, monday.day + i);
      final ymd = dateKey(d);
      final count = dayCountFor(ymd, now: n);
      final CheckInDayStatus status;
      if (d.isAfter(today)) {
        status = CheckInDayStatus.future;
      } else if (d == today) {
        status = (count != null && count >= goal)
            ? CheckInDayStatus.met
            : CheckInDayStatus.todayProgress;
      } else if (count == null) {
        status = CheckInDayStatus.empty;
      } else if (count >= goal) {
        status = CheckInDayStatus.met;
      } else {
        status = CheckInDayStatus.missed;
      }
      return CheckInDay(ymd: ymd, weekday: d.weekday, status: status, count: count);
    });
  }

  /// yyyy-MM-dd when goal celebrate banner was shown (same-day dedupe).
  String? goalCelebratedYmd() => _prefs.getString(_kGoalCelebratedYmd);

  /// Rising-edge across [dailyGoal] and not yet celebrated today.
  Future<bool> _consumeGoalCelebrate({
    required int before,
    required int after,
    DateTime? now,
  }) async {
    final goal = dailyGoal();
    if (goal <= 0) return false;
    final today = dateKey(now);
    if (goalCelebratedYmd() == today) return false;
    if (before < goal && after >= goal) {
      await _prefs.setString(_kGoalCelebratedYmd, today);
      return true;
    }
    return false;
  }

  /// Returns true when UI should show the once-per-day goal celebrate banner.
  Future<bool> markLearned(String id, {DateTime? now}) async {
    final ids = learnedIds();
    final first = !ids.contains(id);
    final bool celebrate;
    if (first) {
      ids.add(id);
      await _prefs.setStringList(_kLearned, ids.toList());
      celebrate = await bumpTodayCount(now: now);
      final today = dateKey(now);
      await _setReview(id, stage: 0, at: addDaysToDateKey(today, daysForStage(0)));
    } else {
      celebrate = await bumpTodayCount(now: now);
      await advanceReviewAfterKnown(id, now: now);
    }
    await removeWrong(id);
    return celebrate;
  }

  /// Increment today's activity count without marking a word learned (e.g. quiz correct).
  /// Returns true when UI should show the once-per-day goal celebrate banner.
  Future<bool> bumpTodayCount({DateTime? now}) async {
    final before = todayCount(now: now);
    await _archiveIfRolled(now);
    final today = dateKey(now);
    if (_prefs.getString(_kTodayDate) != today) {
      await _prefs.setString(_kTodayDate, today);
      await _prefs.setInt(_kTodayCount, 1);
    } else {
      await _prefs.setInt(_kTodayCount, (_prefs.getInt(_kTodayCount) ?? 0) + 1);
    }
    await _updateStreak(today);
    final after = todayCount(now: now);
    return _consumeGoalCelebrate(before: before, after: after, now: now);
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

  Future<void> touchActive({DateTime? now}) async {
    await _archiveIfRolled(now);
    await _updateStreak(dateKey(now));
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
