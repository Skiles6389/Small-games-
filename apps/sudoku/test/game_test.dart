import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:sudoku/engine/difficulty.dart';
import 'package:sudoku/engine/sudoku_generator.dart';
import 'package:sudoku/engine/sudoku_solver.dart';
import 'package:sudoku/game/game_controller.dart';
import 'package:sudoku/game/sudoku_game.dart';

SudokuGame newGame() =>
    SudokuGame(SudokuGenerator.generate(Difficulty.easy, seed: 99));

int firstEmpty(SudokuGame g) => g.values.indexOf(0);

/// A digit that is *not* the answer for cell [i].
int wrongDigit(SudokuGame g, int i) => g.solution[i] % 9 + 1;

void main() {
  group('SudokuGame', () {
    test('entering digits counts mistakes and ignores givens', () {
      final g = newGame();
      final given = g.values.indexWhere((v) => v != 0);
      expect(g.enterDigit(given, 1), isFalse);

      final i = firstEmpty(g);
      expect(g.enterDigit(i, wrongDigit(g, i)), isTrue);
      expect(g.isWrong(i), isTrue);
      expect(g.mistakes, 1);
      expect(g.enterDigit(i, g.solution[i]), isTrue);
      expect(g.isWrong(i), isFalse);
      expect(g.mistakes, 1);
    });

    test('notes toggle and are cleared from peers when a digit is placed', () {
      final g = newGame();
      final i = firstEmpty(g);
      final digit = g.solution[i];
      final peer = SudokuSolver.peers[i].firstWhere((p) => g.values[p] == 0);

      expect(g.toggleNote(peer, digit), isTrue);
      expect(g.toggleNote(peer, 5 == digit ? 6 : 5), isTrue);
      expect(g.hasNote(peer, digit), isTrue);

      g.enterDigit(i, digit);
      expect(g.hasNote(peer, digit), isFalse, reason: 'auto-removed');

      expect(g.undo(), isTrue);
      expect(g.values[i], 0);
      expect(g.hasNote(peer, digit), isTrue, reason: 'undo brings notes back');

      expect(g.toggleNote(peer, digit), isTrue);
      expect(g.hasNote(peer, digit), isFalse);
    });

    test('notes cannot be added to a filled cell', () {
      final g = newGame();
      final i = firstEmpty(g);
      g.enterDigit(i, g.solution[i]);
      expect(g.toggleNote(i, 3), isFalse);
    });

    test('erase and undo', () {
      final g = newGame();
      final i = firstEmpty(g);
      expect(g.erase(i), isFalse, reason: 'nothing to erase');
      g.enterDigit(i, 4);
      expect(g.erase(i), isTrue);
      expect(g.values[i], 0);
      g.undo();
      expect(g.values[i], 4);
      g.undo();
      expect(g.values[i], 0);
      expect(g.canUndo, isFalse);
      expect(g.undo(), isFalse);
    });

    test('hints reveal and lock a cell, even against undo', () {
      final g = newGame();
      final i = firstEmpty(g);
      g.enterDigit(i, wrongDigit(g, i));
      expect(g.hintTarget(i), i, reason: 'prefers the selected wrong cell');
      g.reveal(i);
      expect(g.values[i], g.solution[i]);
      expect(g.isRevealed(i), isTrue);
      expect(g.hintsUsed, 1);
      expect(g.enterDigit(i, 1), isFalse);
      g.undo();
      expect(g.values[i], g.solution[i]);
      expect(g.hintTarget(i), isNot(i), reason: 'falls back to another cell');
    });

    test('filling every cell solves the puzzle', () {
      final g = newGame();
      expect(g.isSolved, isFalse);
      for (var i = 0; i < 81; i++) {
        if (g.values[i] == 0) g.enterDigit(i, g.solution[i]);
      }
      expect(g.isSolved, isTrue);
      expect(g.hintTarget(null), isNull);
      expect(g.correctCount(5), 9);
    });

    test('save and load keep progress', () {
      final g = newGame();
      final a = firstEmpty(g);
      g.enterDigit(a, wrongDigit(g, a));
      final b = g.values.indexOf(0);
      g.toggleNote(b, 2);
      g.toggleNote(b, 7);
      final c = g.values.indexOf(0, b + 1);
      g.reveal(c);
      g.elapsedSeconds = 321;

      final loaded = SudokuGame.fromJson(g.toJson())!;
      expect(loaded.values, g.values);
      expect(loaded.notes, g.notes);
      expect(loaded.fixed, g.fixed);
      expect(loaded.elapsedSeconds, 321);
      expect(loaded.mistakes, 1);
      expect(loaded.hintsUsed, 1);
      expect(SudokuGame.fromJson({'version': 99}), isNull);
      expect(SudokuGame.fromJson({'version': 1, 'puzzle': 'bad'}), isNull);
    });
  });

  group('GameController', () {
    Future<void> solveWithHints(GameController c) async {
      while (c.hintTarget != null) {
        c.applyHint(c.hintTarget!);
      }
      // Let the async win bookkeeping finish.
      for (var k = 0; k < 10 && c.outcome == null; k++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    test('new game records stats, auto-saves and resumes', () async {
      final services = GameServices.inMemory(gameId: 'sudoku');
      final c = await GameController.newGame(
        services,
        Difficulty.medium,
        seed: 5,
      );
      expect(services.stats.statsFor('medium').played, 1);

      c.selected = c.game.values.indexOf(0);
      c.resumeTimer();
      c.input(c.game.solution[c.selected!]);
      c.tickForTesting();
      c.pauseTimer();
      await Future<void>.delayed(Duration.zero);

      final resumed = GameController.resume(services)!;
      expect(resumed.game.values, c.game.values);
      expect(resumed.game.elapsedSeconds, 1);
      c.dispose();
      resumed.dispose();
    });

    test('notes mode adds pencil marks instead of digits', () async {
      final services = GameServices.inMemory(gameId: 'sudoku');
      final c = await GameController.newGame(
        services,
        Difficulty.easy,
        seed: 1,
      );
      c.resumeTimer();
      final i = c.game.values.indexOf(0);
      c.select(i);
      c.toggleNotesMode();
      c.input(3);
      c.input(8);
      expect(c.game.values[i], 0);
      expect(c.game.hasNote(i, 3) && c.game.hasNote(i, 8), isTrue);
      c.erase();
      expect(c.game.notes[i], 0);
      c.undo();
      expect(c.game.hasNote(i, 8), isTrue);
      c.dispose();
    });

    test('winning records the result and clears the save', () async {
      final services = GameServices.inMemory(gameId: 'sudoku');
      final c = await GameController.newGame(
        services,
        Difficulty.easy,
        seed: 2,
      );
      c.resumeTimer();
      c.game.elapsedSeconds = 90;
      await solveWithHints(c);

      expect(c.isSolved, isTrue);
      expect(c.outcome, isNotNull);
      expect(c.outcome!.seconds, 90);
      expect(c.outcome!.isNewBest, isTrue);
      expect(c.outcome!.dailyStreak, isNull);
      expect(services.stats.statsFor('easy').won, 1);
      expect(services.stats.statsFor('easy').bestSeconds, 90);
      expect(GameController.resume(services), isNull);
      c.dispose();
    });

    test('daily puzzle resumes the same day and builds a streak', () async {
      final services = GameServices.inMemory(gameId: 'sudoku');
      final day1 = DateTime(2026, 11, 24, 9);

      final first = await GameController.daily(services, day1);
      final i = first.game.values.indexOf(0);
      first.game.enterDigit(i, first.game.solution[i]);
      await first.save();
      first.dispose();

      final again = await GameController.daily(services, day1);
      expect(again.game.values[i], again.game.solution[i]);
      expect(services.stats.statsFor('daily').played, 1);
      await solveWithHints(again);
      expect(again.outcome!.dailyStreak, 1);
      again.dispose();

      final day2 = await GameController.daily(services, DateTime(2026, 11, 25));
      expect(day2.game.puzzle.dailyKey, '2026-11-25');
      await solveWithHints(day2);
      expect(day2.outcome!.dailyStreak, 2);
      expect(services.streak.bestStreak, 2);
      day2.dispose();
    });
  });
}
