import '../random/seeded_random.dart';

/// Helpers for "puzzle of the day" features.
///
/// Every player who opens the game on the same calendar date gets the same
/// seed, so a game can generate the same daily puzzle for everyone without a
/// server.
class DailyPuzzle {
  const DailyPuzzle._();

  /// The calendar date (no time part) for [moment], in the player's local time.
  static DateTime dateOnly(DateTime moment) =>
      DateTime.utc(moment.year, moment.month, moment.day);

  /// A readable key like `2026-11-24`. Used for seeds and for saving progress.
  static String dateKey(DateTime moment) {
    final d = dateOnly(moment);
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  /// Parses a key produced by [dateKey]. Returns null if it is malformed.
  static DateTime? parseKey(String? key) {
    if (key == null) return null;
    final parts = key.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime.utc(y, m, d);
  }

  /// The seed for [gameId]'s daily puzzle on [date].
  ///
  /// Different games get different seeds on the same day, so the daily
  /// Sudoku and a future daily Minesweeper are not secretly linked.
  static int seedFor(String gameId, DateTime date) =>
      stableHash('$gameId:daily:${dateKey(date)}');

  /// Whole days from [from] to [to], ignoring the time of day.
  static int daysBetween(DateTime from, DateTime to) =>
      dateOnly(to).difference(dateOnly(from)).inDays;
}
