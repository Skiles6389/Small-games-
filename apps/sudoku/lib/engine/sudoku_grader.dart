import 'sudoku_solver.dart';

/// Checks how a person might solve a puzzle, to judge its difficulty.
///
/// It only knows the two basic techniques:
/// * **Naked single** – a cell where only one digit fits.
/// * **Hidden single** – a digit that fits in only one cell of a row,
///   column or box.
///
/// If those alone fill the board, the puzzle is "friendly"; otherwise the
/// player will need more advanced reasoning.
class SudokuGrader {
  const SudokuGrader._();

  static bool solvableWithSingles(List<int> puzzle) {
    final grid = List<int>.of(puzzle);
    while (true) {
      if (!grid.contains(0)) return true;
      if (!_applyStep(grid)) return false;
    }
  }

  /// Fills every cell it can in one pass. Returns false when stuck.
  static bool _applyStep(List<int> grid) {
    var progress = false;

    for (var i = 0; i < 81; i++) {
      if (grid[i] != 0) continue;
      final mask = SudokuSolver.candidatesMask(grid, i);
      if (mask == 0) return false;
      if (SudokuSolver.bitCount(mask) == 1) {
        grid[i] = SudokuSolver.lowestDigit(mask);
        progress = true;
      }
    }

    for (final unit in SudokuSolver.units) {
      for (var d = 1; d <= 9; d++) {
        final bit = 1 << d;
        var spot = -1;
        var count = 0;
        var alreadyPlaced = false;
        for (final i in unit) {
          if (grid[i] == d) {
            alreadyPlaced = true;
            break;
          }
          if (grid[i] == 0 && SudokuSolver.candidatesMask(grid, i) & bit != 0) {
            spot = i;
            count++;
          }
        }
        if (!alreadyPlaced && count == 1) {
          grid[spot] = d;
          progress = true;
        }
      }
    }
    return progress;
  }
}
