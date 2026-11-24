import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/engine/difficulty.dart';
import 'package:sudoku/engine/sudoku_generator.dart';
import 'package:sudoku/engine/sudoku_grader.dart';
import 'package:sudoku/engine/sudoku_puzzle.dart';
import 'package:sudoku/engine/sudoku_solver.dart';

List<int> parse(String s) => [
  for (final ch in s.replaceAll(RegExp(r'\s'), '').split(''))
    ch == '.' ? 0 : int.parse(ch),
];

// A well-known puzzle and its solution.
final classicPuzzle = parse('''
53..7....
6..195...
.98....6.
8...6...3
4..8.3..1
7...2...6
.6....28.
...419..5
....8..79
''');

final classicSolution = parse('''
534678912
672195348
198342567
859761423
426853791
713924856
961537284
287419635
345286179
''');

void main() {
  group('SudokuSolver', () {
    test('solves a known puzzle', () {
      expect(SudokuSolver.solve(classicPuzzle), classicSolution);
      expect(SudokuSolver.countSolutions(classicPuzzle), 1);
    });

    test('validates solutions', () {
      expect(SudokuSolver.isValidSolution(classicSolution), isTrue);
      final broken = List<int>.of(classicSolution);
      broken[0] = broken[1];
      expect(SudokuSolver.isValidSolution(broken), isFalse);
      expect(SudokuSolver.isValidSolution(classicPuzzle), isFalse);
    });

    test('detects multiple solutions', () {
      final empty = List.filled(81, 0);
      expect(SudokuSolver.countSolutions(empty), 2);
      expect(SudokuSolver.countSolutions(empty, limit: 5), 5);

      // Blank a "deadly rectangle": 4 cells in 2 rows, 2 columns and exactly
      // 2 boxes holding a/b and b/a. Swapping them is also valid, so the
      // grid has two solutions.
      final ambiguous = List<int>.of(classicSolution);
      var found = false;
      for (var r1 = 0; r1 < 9 && !found; r1++) {
        for (var r2 = r1 + 1; r2 < 9 && !found; r2++) {
          for (var c1 = 0; c1 < 9 && !found; c1++) {
            for (var c2 = c1 + 1; c2 < 9 && !found; c2++) {
              final sameBand = r1 ~/ 3 == r2 ~/ 3;
              final sameStack = c1 ~/ 3 == c2 ~/ 3;
              if (sameBand == sameStack) continue;
              final a = classicSolution[r1 * 9 + c1];
              final b = classicSolution[r1 * 9 + c2];
              if (classicSolution[r2 * 9 + c1] == b &&
                  classicSolution[r2 * 9 + c2] == a) {
                for (final i in [
                  r1 * 9 + c1,
                  r1 * 9 + c2,
                  r2 * 9 + c1,
                  r2 * 9 + c2,
                ]) {
                  ambiguous[i] = 0;
                }
                found = true;
              }
            }
          }
        }
      }
      expect(found, isTrue);
      expect(SudokuSolver.countSolutions(ambiguous), 2);
      expect(SudokuSolver.hasUniqueSolution(ambiguous), isFalse);
    });

    test('rejects impossible or broken grids', () {
      final dup = List<int>.filled(81, 0)
        ..[0] = 5
        ..[1] = 5;
      expect(SudokuSolver.solve(dup), isNull);
      expect(SudokuSolver.countSolutions(dup), 0);

      // Valid-looking but unsolvable: cell 0 has no candidates left.
      final stuck = List<int>.filled(81, 0);
      for (var c = 1; c < 9; c++) {
        stuck[c] = c;
      }
      stuck[9 * 4] = 9;
      expect(SudokuSolver.isConsistent(stuck), isTrue);
      expect(SudokuSolver.solve(stuck), isNull);
    });
  });

  group('SudokuGenerator', () {
    void expectWellFormed(SudokuPuzzle p) {
      expect(
        SudokuSolver.isValidSolution(p.solution),
        isTrue,
        reason: 'solution must follow the rules',
      );
      for (var i = 0; i < 81; i++) {
        if (p.givens[i] != 0) {
          expect(p.givens[i], p.solution[i], reason: 'givens match solution');
        }
      }
      expect(
        SudokuSolver.countSolutions(p.givens),
        1,
        reason: 'puzzle must have exactly one solution',
      );
      expect(SudokuSolver.solve(p.givens), p.solution);
    }

    for (final difficulty in Difficulty.values) {
      test('${difficulty.label}: unique, valid and matches its difficulty', () {
        for (var seed = 1; seed <= 8; seed++) {
          final p = SudokuGenerator.generate(difficulty, seed: seed * 7919);
          expectWellFormed(p);
          expect(p.difficulty, difficulty);
          expect(p.clueCount, greaterThanOrEqualTo(17));
          if (difficulty.singlesOnly) {
            expect(SudokuGrader.solvableWithSingles(p.givens), isTrue);
          }
        }
      });
    }

    test('harder levels leave fewer clues on average', () {
      double avgClues(Difficulty d) {
        var total = 0;
        for (var seed = 100; seed < 106; seed++) {
          total += SudokuGenerator.generate(d, seed: seed).clueCount;
        }
        return total / 6;
      }

      final easy = avgClues(Difficulty.easy);
      final medium = avgClues(Difficulty.medium);
      final hard = avgClues(Difficulty.hard);
      final expert = avgClues(Difficulty.expert);
      expect(easy, greaterThan(medium));
      expect(medium, greaterThan(hard));
      expect(hard, greaterThan(expert));
    });

    test('same seed gives the same puzzle', () {
      final a = SudokuGenerator.generate(Difficulty.hard, seed: 12345);
      final b = SudokuGenerator.generate(Difficulty.hard, seed: 12345);
      final c = SudokuGenerator.generate(Difficulty.hard, seed: 54321);
      expect(a.givens, b.givens);
      expect(a.solution, b.solution);
      expect(a.givens, isNot(c.givens));
    });

    test('daily puzzle is deterministic per date', () {
      final morning = SudokuGenerator.daily(DateTime(2026, 11, 24, 7));
      final evening = SudokuGenerator.daily(DateTime(2026, 11, 24, 22));
      final tomorrow = SudokuGenerator.daily(DateTime(2026, 11, 25, 7));
      expect(morning.givens, evening.givens);
      expect(morning.givens, isNot(tomorrow.givens));
      expect(morning.dailyKey, '2026-11-24');
      expect(morning.isDaily, isTrue);
      expectWellFormed(morning);
    });

    test('daily puzzle is pinned (same on phones and the web)', () {
      // If this changes, every player's daily puzzle changes. Run with
      // `flutter test --platform chrome` too to check the web build agrees.
      expect(
        SudokuGenerator.daily(DateTime(2026, 1, 1)).givens.join(),
        '007090050000200001009354802008002003'
        '070603040600400100702548600300009000050030200',
      );
    });

    test('puzzle JSON round-trips', () {
      final p = SudokuGenerator.daily(DateTime(2026, 1, 1));
      final copy = SudokuPuzzle.fromJson(p.toJson());
      expect(copy.givens, p.givens);
      expect(copy.solution, p.solution);
      expect(copy.difficulty, p.difficulty);
      expect(copy.dailyKey, p.dailyKey);
    });
  });

  group('SudokuGrader', () {
    test('classic puzzle is solvable with singles', () {
      expect(SudokuGrader.solvableWithSingles(classicPuzzle), isTrue);
    });

    test('an empty board is not', () {
      expect(SudokuGrader.solvableWithSingles(List.filled(81, 0)), isFalse);
    });
  });
}
