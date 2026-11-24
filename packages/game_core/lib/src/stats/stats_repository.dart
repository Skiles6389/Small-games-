import 'package:flutter/foundation.dart';

import '../storage/key_value_store.dart';

/// Numbers for one mode of a game (for Sudoku, a mode is a difficulty).
@immutable
class ModeStats {
  const ModeStats({
    this.played = 0,
    this.won = 0,
    this.bestSeconds,
    this.totalWinSeconds = 0,
  });

  final int played;
  final int won;

  /// Fastest win in seconds, or null if never won.
  final int? bestSeconds;
  final int totalWinSeconds;

  double get winRate => played == 0 ? 0 : won / played;
  int? get averageSeconds => won == 0 ? null : totalWinSeconds ~/ won;

  ModeStats copyWith({
    int? played,
    int? won,
    int? bestSeconds,
    int? totalWinSeconds,
  }) => ModeStats(
    played: played ?? this.played,
    won: won ?? this.won,
    bestSeconds: bestSeconds ?? this.bestSeconds,
    totalWinSeconds: totalWinSeconds ?? this.totalWinSeconds,
  );

  Map<String, dynamic> toJson() => {
    'played': played,
    'won': won,
    'best': bestSeconds,
    'total': totalWinSeconds,
  };

  factory ModeStats.fromJson(Map<String, dynamic> json) => ModeStats(
    played: (json['played'] as int?) ?? 0,
    won: (json['won'] as int?) ?? 0,
    bestSeconds: json['best'] as int?,
    totalWinSeconds: (json['total'] as int?) ?? 0,
  );
}

/// Games played / won and best times, saved per mode.
class StatsRepository extends ChangeNotifier {
  StatsRepository(this._store, {required String gameId})
    : _key = '$gameId.stats' {
    final data = _store.getJson(_key) ?? const {};
    for (final entry in data.entries) {
      if (entry.value is Map<String, dynamic>) {
        _modes[entry.key] = ModeStats.fromJson(entry.value);
      }
    }
  }

  final KeyValueStore _store;
  final String _key;
  final Map<String, ModeStats> _modes = {};

  ModeStats statsFor(String mode) => _modes[mode] ?? const ModeStats();

  /// Totals across every mode.
  ModeStats get overall {
    var played = 0, won = 0, total = 0;
    int? best;
    for (final s in _modes.values) {
      played += s.played;
      won += s.won;
      total += s.totalWinSeconds;
      final b = s.bestSeconds;
      if (b != null && (best == null || b < best)) best = b;
    }
    return ModeStats(
      played: played,
      won: won,
      bestSeconds: best,
      totalWinSeconds: total,
    );
  }

  Future<void> recordStart(String mode) async {
    final s = statsFor(mode);
    _modes[mode] = s.copyWith(played: s.played + 1);
    await _persist();
  }

  /// Records a win and returns true if it is a new best time.
  Future<bool> recordWin(String mode, int seconds) async {
    final s = statsFor(mode);
    final isBest = s.bestSeconds == null || seconds < s.bestSeconds!;
    _modes[mode] = s.copyWith(
      won: s.won + 1,
      bestSeconds: isBest ? seconds : s.bestSeconds,
      totalWinSeconds: s.totalWinSeconds + seconds,
    );
    await _persist();
    return isBest;
  }

  Future<void> reset() async {
    _modes.clear();
    await _store.remove(_key);
    notifyListeners();
  }

  Future<void> _persist() async {
    await _store.setJson(_key, {
      for (final e in _modes.entries) e.key: e.value.toJson(),
    });
    notifyListeners();
  }
}
