import 'package:game_core/game_core.dart';

/// Board helpers and a fast backtracking solver.
///
/// A grid is a flat list of 81 numbers, row by row. `0` means empty and
/// `1`-`9` are digits. Cell `i` is in row `i ~/ 9` and column `i % 9`.
class SudokuSolver {
  const SudokuSolver._();

  static int rowOf(int i) => i ~/ 9;
  static int colOf(int i) => i % 9;
  static int boxOf(int i) => (rowOf(i) ~/ 3) * 3 + colOf(i) ~/ 3;

  /// For every cell, the 20 other cells in its row, column and box.
  static final List<List<int>> peers = List.generate(81, (i) {
    final result = <int>[];
    for (var j = 0; j < 81; j++) {
      if (j == i) continue;
      if (rowOf(j) == rowOf(i) ||
          colOf(j) == colOf(i) ||
          boxOf(j) == boxOf(i)) {
        result.add(j);
      }
    }
    return result;
  }, growable: false);

  /// The 27 groups (9 rows, 9 columns, 9 boxes) as lists of cell indexes.
  static final List<List<int>> units = [
    for (var r = 0; r < 9; r++) [for (var c = 0; c < 9; c++) r * 9 + c],
    for (var c = 0; c < 9; c++) [for (var r = 0; r < 9; r++) r * 9 + c],
    for (var b = 0; b < 9; b++)
      [
        for (var k = 0; k < 9; k++)
          ((b ~/ 3) * 3 + k ~/ 3) * 9 + (b % 3) * 3 + k % 3,
      ],
  ];

  /// True if no row, column or box contains the same digit twice
  /// (empty cells are ignored).
  static bool isConsistent(List<int> grid) {
    if (grid.length != 81) return false;
    for (final unit in units) {
      var seen = 0;
      for (final i in unit) {
        final v = grid[i];
        if (v == 0) continue;
        if (v < 0 || v > 9) return false;
        final bit = 1 << v;
        if (seen & bit != 0) return false;
        seen |= bit;
      }
    }
    return true;
  }

  /// True if [grid] is completely filled and follows the rules.
  static bool isValidSolution(List<int> grid) =>
      grid.length == 81 && !grid.contains(0) && isConsistent(grid);

  /// Solves [grid] and returns the filled grid, or null if impossible.
  ///
  /// With a [random] generator the search tries digits in random order, which
  /// is how the generator builds a random full board.
  static List<int>? solve(List<int> grid, {SeededRandom? random}) {
    final search = _Search.fromGrid(grid, random: random);
    if (search == null) return null;
    return search.run(limit: 1) == 1 ? search.firstSolution : null;
  }

  /// Counts solutions, stopping early at [limit]. A proper puzzle has
  /// exactly one, so `countSolutions(grid) == 1` is the uniqueness check.
  static int countSolutions(List<int> grid, {int limit = 2}) {
    final search = _Search.fromGrid(grid);
    if (search == null) return 0;
    return search.run(limit: limit);
  }

  static bool hasUniqueSolution(List<int> grid) => countSolutions(grid) == 1;

  /// Bit mask of the digits that could go in cell [i] (bit `d` = digit `d`).
  static int candidatesMask(List<int> grid, int i) {
    var used = 0;
    for (final p in peers[i]) {
      used |= 1 << grid[p];
    }
    return _allDigits & ~used;
  }

  static const int _allDigits = 0x3FE; // bits 1..9

  static int bitCount(int mask) {
    var n = 0;
    while (mask != 0) {
      mask &= mask - 1;
      n++;
    }
    return n;
  }

  /// Index of the lowest set bit (e.g. 0b1000 -> 3).
  static int lowestDigit(int mask) {
    var d = 0;
    while ((mask & 1) == 0) {
      mask >>= 1;
      d++;
    }
    return d;
  }
}

/// Depth-first search with "most constrained cell first", using bit masks
/// for the digits already used in each row, column and box.
class _Search {
  _Search._(this._grid, this._random);

  static _Search? fromGrid(List<int> grid, {SeededRandom? random}) {
    if (grid.length != 81 || !SudokuSolver.isConsistent(grid)) return null;
    final s = _Search._(List<int>.of(grid), random);
    for (var i = 0; i < 81; i++) {
      final v = grid[i];
      if (v != 0) s._place(i, v);
    }
    return s;
  }

  final List<int> _grid;
  final SeededRandom? _random;
  final List<int> _rows = List.filled(9, 0);
  final List<int> _cols = List.filled(9, 0);
  final List<int> _boxes = List.filled(9, 0);

  List<int>? firstSolution;
  int _found = 0;

  void _place(int i, int d) {
    final bit = 1 << d;
    _grid[i] = d;
    _rows[SudokuSolver.rowOf(i)] |= bit;
    _cols[SudokuSolver.colOf(i)] |= bit;
    _boxes[SudokuSolver.boxOf(i)] |= bit;
  }

  void _unplace(int i, int d) {
    final bit = ~(1 << d);
    _grid[i] = 0;
    _rows[SudokuSolver.rowOf(i)] &= bit;
    _cols[SudokuSolver.colOf(i)] &= bit;
    _boxes[SudokuSolver.boxOf(i)] &= bit;
  }

  int _candidates(int i) =>
      SudokuSolver._allDigits &
      ~(_rows[SudokuSolver.rowOf(i)] |
          _cols[SudokuSolver.colOf(i)] |
          _boxes[SudokuSolver.boxOf(i)]);

  int run({required int limit}) {
    _found = 0;
    _recurse(limit);
    return _found;
  }

  void _recurse(int limit) {
    var bestCell = -1;
    var bestMask = 0;
    var bestCount = 10;
    for (var i = 0; i < 81; i++) {
      if (_grid[i] != 0) continue;
      final mask = _candidates(i);
      final count = SudokuSolver.bitCount(mask);
      if (count < bestCount) {
        bestCell = i;
        bestMask = mask;
        bestCount = count;
        if (count <= 1) break;
      }
    }

    if (bestCell == -1) {
      _found++;
      firstSolution ??= List<int>.of(_grid);
      return;
    }
    if (bestCount == 0) return;

    final digits = <int>[
      for (var d = 1; d <= 9; d++)
        if (bestMask & (1 << d) != 0) d,
    ];
    _random?.shuffle(digits);

    for (final d in digits) {
      _place(bestCell, d);
      _recurse(limit);
      _unplace(bestCell, d);
      if (_found >= limit) return;
    }
  }
}
