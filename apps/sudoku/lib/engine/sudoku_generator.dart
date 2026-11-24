import 'package:game_core/game_core.dart';

import 'difficulty.dart';
import 'sudoku_grader.dart';
import 'sudoku_puzzle.dart';
import 'sudoku_solver.dart';

/// Makes new puzzles that always have exactly one solution.
///
/// How it works:
/// 1. Fill an empty board with a random valid solution.
/// 2. Visit the cells in random order and try removing each one (together
///    with its mirror cell, so the puzzle looks symmetric).
/// 3. Keep a removal only if the puzzle still has exactly one solution and
///    still fits the chosen difficulty.
///
/// The same seed always gives the same puzzle, on every device.
class SudokuGenerator {
  const SudokuGenerator._();

  /// Expert boards are retried a few times to find one that needs more than
  /// basic techniques. If none is found, the last attempt is used.
  static const int _expertAttempts = 6;

  static const String gameId = 'sudoku';
  static const Difficulty dailyDifficulty = Difficulty.medium;

  /// Today's puzzle: everyone gets the same one on the same calendar date.
  static SudokuPuzzle daily(DateTime date) => generate(
    dailyDifficulty,
    seed: DailyPuzzle.seedFor(gameId, date),
  ).asDaily(DailyPuzzle.dateKey(date));

  static SudokuPuzzle generate(Difficulty difficulty, {required int seed}) {
    final random = SeededRandom(seed);
    late SudokuPuzzle result;
    final attempts = difficulty.needsAdvancedTechniques ? _expertAttempts : 1;
    for (var attempt = 0; attempt < attempts; attempt++) {
      result = _attempt(difficulty, random, seed);
      if (!difficulty.needsAdvancedTechniques ||
          !SudokuGrader.solvableWithSingles(result.givens)) {
        break;
      }
    }
    return result;
  }

  static SudokuPuzzle _attempt(
    Difficulty difficulty,
    SeededRandom random,
    int seed,
  ) {
    final solution = SudokuSolver.solve(List.filled(81, 0), random: random)!;
    final puzzle = List<int>.of(solution);
    var clues = 81;

    // Only visit the first half (plus the centre); each cell is paired with
    // its mirror image through the centre.
    final order = List<int>.generate(41, (i) => i);
    random.shuffle(order);

    bool tryRemove(List<int> cells) {
      final saved = [for (final c in cells) puzzle[c]];
      for (final c in cells) {
        puzzle[c] = 0;
      }
      final ok =
          SudokuSolver.hasUniqueSolution(puzzle) &&
          (!difficulty.singlesOnly || SudokuGrader.solvableWithSingles(puzzle));
      if (!ok) {
        for (var k = 0; k < cells.length; k++) {
          puzzle[cells[k]] = saved[k];
        }
      }
      return ok;
    }

    for (final i in order) {
      if (clues <= difficulty.targetClues) break;
      final mirror = 80 - i;
      final pair = i == mirror ? [i] : [i, mirror];
      if (tryRemove(pair)) clues -= pair.length;
    }

    // Symmetric pairs often get stuck above the target; finish with single
    // cells so harder levels reach their clue count.
    if (clues > difficulty.targetClues) {
      final singles = [
        for (var i = 0; i < 81; i++)
          if (puzzle[i] != 0) i,
      ];
      random.shuffle(singles);
      for (final i in singles) {
        if (clues <= difficulty.targetClues) break;
        if (tryRemove([i])) clues--;
      }
    }

    return SudokuPuzzle(
      givens: puzzle,
      solution: solution,
      difficulty: difficulty,
      seed: seed,
    );
  }
}
