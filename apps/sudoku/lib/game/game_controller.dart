import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:game_core/game_core.dart';

import '../engine/difficulty.dart';
import '../engine/sudoku_generator.dart';
import 'sudoku_game.dart';
import 'sudoku_settings.dart';

/// Shown on the win screen.
class GameOutcome {
  const GameOutcome({
    required this.seconds,
    required this.difficulty,
    required this.isNewBest,
    required this.mistakes,
    required this.hintsUsed,
    this.dailyStreak,
  });

  final int seconds;
  final Difficulty difficulty;
  final bool isNewBest;
  final int mistakes;
  final int hintsUsed;

  /// Set only for daily puzzles.
  final int? dailyStreak;
}

/// Runs one game on screen: selection, input modes, timer, auto-save and
/// recording the result. Widgets listen to it and rebuild on changes.
class GameController extends ChangeNotifier {
  GameController._(this.game, this._services, this._slot, {this.today});

  static const _currentSlot = 'current';
  static const _dailySlot = 'daily';
  static const _saveEverySeconds = 5;

  final SudokuGame game;
  final GameServices _services;
  final SaveSlot _slot;

  /// The date a daily puzzle counts towards (defaults to now).
  final DateTime? today;

  int? selected;
  bool notesMode = false;
  bool _paused = true;
  Timer? _timer;
  GameOutcome? outcome;

  bool get isPaused => _paused;
  bool get isSolved => game.isSolved;
  bool get isDaily => game.puzzle.isDaily;
  String get statsMode => isDaily ? 'daily' : game.puzzle.difficulty.name;
  SettingsController get settings => _services.settings;

  // ---- Starting and resuming ----------------------------------------------

  /// A fresh random puzzle.
  static Future<GameController> newGame(
    GameServices services,
    Difficulty difficulty, {
    int? seed,
  }) async {
    final s = seed ?? _randomSeed();
    final puzzle = SudokuGenerator.generate(difficulty, seed: s);
    final controller = GameController._(
      SudokuGame(puzzle),
      services,
      services.saveSlot(_currentSlot),
    );
    await services.stats.recordStart(controller.statsMode);
    await controller.save();
    return controller;
  }

  /// The saved non-daily game, if any.
  static GameController? resume(GameServices services) {
    final slot = services.saveSlot(_currentSlot);
    final game = SudokuGame.fromJson(slot.load());
    if (game == null || game.isSolved) return null;
    return GameController._(game, services, slot);
  }

  /// Summary of the saved game for the home screen ("Medium · 4:12").
  static SudokuGame? peekSavedGame(GameServices services) =>
      SudokuGame.fromJson(services.saveSlot(_currentSlot).load());

  /// Today's daily puzzle, resuming progress made earlier today.
  static Future<GameController> daily(
    GameServices services,
    DateTime today,
  ) async {
    final slot = services.saveSlot(_dailySlot);
    final key = DailyPuzzle.dateKey(today);
    final saved = SudokuGame.fromJson(slot.load());
    if (saved != null && saved.puzzle.dailyKey == key && !saved.isSolved) {
      return GameController._(saved, services, slot, today: today);
    }
    final controller = GameController._(
      SudokuGame(SudokuGenerator.daily(today)),
      services,
      slot,
      today: today,
    );
    await services.stats.recordStart(controller.statsMode);
    await controller.save();
    return controller;
  }

  static int _randomSeed() =>
      math.Random().nextInt(0x7FFFFFFF) ^ DateTime.now().microsecondsSinceEpoch;

  // ---- Timer --------------------------------------------------------------

  void resumeTimer() {
    if (!_paused || isSolved) return;
    _paused = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  void pauseTimer() {
    if (_paused) return;
    _paused = true;
    _timer?.cancel();
    _timer = null;
    unawaited(save());
    notifyListeners();
  }

  void _tick() {
    game.elapsedSeconds++;
    if (game.elapsedSeconds % _saveEverySeconds == 0) unawaited(save());
    notifyListeners();
  }

  // ---- Player actions -----------------------------------------------------

  void select(int index) {
    if (_paused) return;
    selected = index;
    notifyListeners();
  }

  void toggleNotesMode() {
    notesMode = !notesMode;
    notifyListeners();
  }

  /// Number pad press: a digit or a pencil mark depending on [notesMode].
  void input(int digit) {
    final i = selected;
    if (i == null || _paused || isSolved) return;
    final changed = notesMode && game.values[i] == 0
        ? game.toggleNote(i, digit)
        : game.enterDigit(i, digit, autoRemoveNotes: settings.autoRemoveNotes);
    if (changed) _afterMove();
  }

  void erase() {
    final i = selected;
    if (i == null || _paused) return;
    if (game.erase(i)) _afterMove();
  }

  void undo() {
    if (_paused) return;
    if (game.undo()) _afterMove();
  }

  /// The cell a hint would fill right now.
  int? get hintTarget => game.hintTarget(selected);

  /// Reveals [index]. Call after the player has earned the hint.
  void applyHint(int index) {
    if (isSolved) return;
    game.reveal(index);
    selected = index;
    _afterMove();
  }

  void _afterMove() {
    notifyListeners();
    if (game.isSolved) {
      unawaited(_finish());
    } else {
      unawaited(save());
    }
  }

  Future<void> _finish() async {
    _timer?.cancel();
    _timer = null;
    _paused = true;
    selected = null;
    await _slot.clear();
    final isBest = await _services.stats.recordWin(
      statsMode,
      game.elapsedSeconds,
    );
    int? streak;
    if (isDaily) {
      final day = today ?? DateTime.now();
      await _services.streak.recordCompletion(day);
      streak = _services.streak.currentStreak(day);
    }
    outcome = GameOutcome(
      seconds: game.elapsedSeconds,
      difficulty: game.puzzle.difficulty,
      isNewBest: isBest,
      mistakes: game.mistakes,
      hintsUsed: game.hintsUsed,
      dailyStreak: streak,
    );
    notifyListeners();
  }

  Future<void> save() async {
    if (game.isSolved) return;
    await _slot.save(game.toJson());
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (!game.isSolved) unawaited(save());
    super.dispose();
  }

  @visibleForTesting
  void tickForTesting() => _tick();
}
