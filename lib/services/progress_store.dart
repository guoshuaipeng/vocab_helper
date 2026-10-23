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

  static Future<ProgressStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    return ProgressStore(prefs);
  }

  String? selectedBookId() => _prefs.getString(_kBookId);

  Future<void> setSelectedBookId(String id) async {
    await _prefs.setString(_kBookId, id);
  }

  bool get hasSelectedBook => selectedBookId() != null && selectedBookId()!.isNotEmpty;

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
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
    final kept = before.where((id) => !id.startsWith(prefix)).toList();
    final removed = before.length - kept.length;
    await _prefs.setStringList(_kLearned, kept);
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

  String? unitFilterForBook(String bookId) => _prefs.getString('$_kUnitFilterPrefix$bookId');

  Future<void> setUnitFilterForBook(String bookId, String? unit) async {
    final key = '$_kUnitFilterPrefix$bookId';
    if (unit == null || unit.isEmpty) {
      await _prefs.remove(key);
    } else {
      await _prefs.setString(key, unit);
    }
  }

  Future<void> markLearned(String id) async {
    final ids = learnedIds();
    if (!ids.contains(id)) {
      ids.add(id);
      await _prefs.setStringList(_kLearned, ids.toList());

      final today = _todayKey();
      if (_prefs.getString(_kTodayDate) != today) {
        await _prefs.setString(_kTodayDate, today);
        await _prefs.setInt(_kTodayCount, 1);
      } else {
        await _prefs.setInt(_kTodayCount, todayCount() + 1);
      }
      await _updateStreak(today);
    }
    await removeWrong(id);
  }

  Future<void> markWrong(String id) async {
    final ids = wrongIds();
    if (ids.contains(id)) return;
    ids.add(id);
    await _prefs.setStringList(_kWrong, ids.toList());
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