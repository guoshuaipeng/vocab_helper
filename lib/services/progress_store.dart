import 'package:shared_preferences/shared_preferences.dart';

class ProgressStore {
  ProgressStore(this._prefs);

  final SharedPreferences _prefs;

  static const _kLearned = 'learned_ids';
  static const _kTodayCount = 'today_count';
  static const _kTodayDate = 'today_date';
  static const _kStreak = 'streak_days';
  static const _kLastActive = 'last_active_date';
  static const _kBookId = 'selected_book_id';

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

  int learnedCount() => learnedIds().length;

  int todayCount() {
    final today = _todayKey();
    if (_prefs.getString(_kTodayDate) != today) return 0;
    return _prefs.getInt(_kTodayCount) ?? 0;
  }

  int streakDays() => _prefs.getInt(_kStreak) ?? 0;

  Future<void> markLearned(String id) async {
    final ids = learnedIds();
    if (ids.contains(id)) return;
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