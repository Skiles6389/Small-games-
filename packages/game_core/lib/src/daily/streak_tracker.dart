import 'package:flutter/foundation.dart';

import '../storage/key_value_store.dart';
import 'daily_puzzle.dart';

/// Counts how many days in a row the player finished the daily puzzle.
class StreakTracker extends ChangeNotifier {
  StreakTracker(this._store, {required String gameId})
    : _key = '$gameId.streak' {
    final data = _store.getJson(_key) ?? const {};
    _lastCompleted = DailyPuzzle.parseKey(data['last'] as String?);
    _streak = (data['streak'] as int?) ?? 0;
    _best = (data['best'] as int?) ?? 0;
  }

  final KeyValueStore _store;
  final String _key;

  DateTime? _lastCompleted;
  int _streak = 0;
  int _best = 0;

  /// The longest streak ever reached.
  int get bestStreak => _best;

  /// The streak as of [today]. It drops to 0 once a whole day is missed.
  int currentStreak(DateTime today) {
    final last = _lastCompleted;
    if (last == null) return 0;
    final gap = DailyPuzzle.daysBetween(last, today);
    return (gap == 0 || gap == 1) ? _streak : 0;
  }

  bool isCompleted(DateTime day) {
    final last = _lastCompleted;
    return last != null && DailyPuzzle.daysBetween(last, day) == 0;
  }

  /// Call when the daily puzzle for [day] is solved. Solving the same day
  /// twice does not count twice.
  Future<void> recordCompletion(DateTime day) async {
    final date = DailyPuzzle.dateOnly(day);
    final last = _lastCompleted;
    if (last != null) {
      final gap = DailyPuzzle.daysBetween(last, date);
      if (gap <= 0) return;
      _streak = gap == 1 ? _streak + 1 : 1;
    } else {
      _streak = 1;
    }
    _lastCompleted = date;
    if (_streak > _best) _best = _streak;
    await _store.setJson(_key, {
      'last': DailyPuzzle.dateKey(date),
      'streak': _streak,
      'best': _best,
    });
    notifyListeners();
  }

  Future<void> reset() async {
    _lastCompleted = null;
    _streak = 0;
    _best = 0;
    await _store.remove(_key);
    notifyListeners();
  }
}
