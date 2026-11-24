import '../engine/sudoku_puzzle.dart';
import '../engine/sudoku_solver.dart';

/// One cell's state before a move, so the move can be undone.
class _CellSnapshot {
  const _CellSnapshot(this.index, this.value, this.notes);

  final int index;
  final int value;
  final int notes;
}

/// The rules and state of a game in progress. Plain Dart (no Flutter), so it
/// is easy to unit test.
///
/// Notes are stored as bit masks: bit `d` set means "pencil mark d".
class SudokuGame {
  SudokuGame(this.puzzle)
    : values = List<int>.of(puzzle.givens),
      notes = List<int>.filled(81, 0),
      fixed = [for (final v in puzzle.givens) v != 0];

  final SudokuPuzzle puzzle;

  /// Current digit in every cell (0 = empty).
  final List<int> values;

  /// Pencil marks in every cell.
  final List<int> notes;

  /// Cells the player can't change: the starting numbers and hint reveals.
  final List<bool> fixed;

  int elapsedSeconds = 0;
  int mistakes = 0;
  int hintsUsed = 0;

  final List<List<_CellSnapshot>> _history = [];

  List<int> get solution => puzzle.solution;

  bool get canUndo => _history.isNotEmpty;

  bool get isSolved {
    for (var i = 0; i < 81; i++) {
      if (values[i] != solution[i]) return false;
    }
    return true;
  }

  bool isGiven(int i) => puzzle.givens[i] != 0;

  bool isRevealed(int i) => fixed[i] && !isGiven(i);

  bool isWrong(int i) => values[i] != 0 && values[i] != solution[i];

  bool hasNote(int i, int digit) => notes[i] & (1 << digit) != 0;

  /// How many cells hold [digit] correctly. Used to grey out finished digits.
  int correctCount(int digit) {
    var n = 0;
    for (var i = 0; i < 81; i++) {
      if (values[i] == digit && solution[i] == digit) n++;
    }
    return n;
  }

  /// Puts [digit] in cell [i]. When [autoRemoveNotes] is on, the same pencil
  /// mark is cleared from the cell's row, column and box.
  /// Returns false if nothing changed.
  bool enterDigit(int i, int digit, {bool autoRemoveNotes = true}) {
    if (fixed[i] || values[i] == digit) return false;
    final changes = <_CellSnapshot>[_snapshot(i)];
    values[i] = digit;
    notes[i] = 0;
    if (autoRemoveNotes) {
      final bit = 1 << digit;
      for (final p in SudokuSolver.peers[i]) {
        if (notes[p] & bit != 0) {
          changes.add(_snapshot(p));
          notes[p] &= ~bit;
        }
      }
    }
    if (digit != solution[i]) mistakes++;
    _history.add(changes);
    return true;
  }

  /// Adds or removes pencil mark [digit] in an empty cell.
  bool toggleNote(int i, int digit) {
    if (fixed[i] || values[i] != 0) return false;
    _history.add([_snapshot(i)]);
    notes[i] ^= 1 << digit;
    return true;
  }

  /// Clears the digit or notes in cell [i].
  bool erase(int i) {
    if (fixed[i] || (values[i] == 0 && notes[i] == 0)) return false;
    _history.add([_snapshot(i)]);
    values[i] = 0;
    notes[i] = 0;
    return true;
  }

  /// Reverts the last move. Cells revealed by a hint stay revealed.
  bool undo() {
    if (_history.isEmpty) return false;
    for (final s in _history.removeLast().reversed) {
      if (fixed[s.index]) continue;
      values[s.index] = s.value;
      notes[s.index] = s.notes;
    }
    return true;
  }

  /// Picks the cell a hint should reveal: [preferred] if it is empty or
  /// wrong, otherwise the first empty-or-wrong cell. Null if solved.
  int? hintTarget(int? preferred) {
    bool needsHelp(int i) => !fixed[i] && values[i] != solution[i];
    if (preferred != null && needsHelp(preferred)) return preferred;
    for (var i = 0; i < 81; i++) {
      if (needsHelp(i)) return i;
    }
    return null;
  }

  /// Fills cell [i] with its correct digit and locks it.
  void reveal(int i) {
    values[i] = solution[i];
    notes[i] = 0;
    fixed[i] = true;
    final bit = 1 << solution[i];
    for (final p in SudokuSolver.peers[i]) {
      notes[p] &= ~bit;
    }
    hintsUsed++;
  }

  _CellSnapshot _snapshot(int i) => _CellSnapshot(i, values[i], notes[i]);

  // ---- Saving -------------------------------------------------------------

  Map<String, dynamic> toJson() => {
    'version': 1,
    'puzzle': puzzle.toJson(),
    'values': values.join(),
    'notes': notes,
    'fixed': [
      for (var i = 0; i < 81; i++)
        if (fixed[i] && !isGiven(i)) i,
    ],
    'elapsed': elapsedSeconds,
    'mistakes': mistakes,
    'hints': hintsUsed,
  };

  /// Restores a saved game. Undo history is not saved. Returns null if the
  /// data is missing or damaged.
  static SudokuGame? fromJson(Map<String, dynamic>? json) {
    if (json == null || json['version'] != 1) return null;
    try {
      final game = SudokuGame(
        SudokuPuzzle.fromJson(json['puzzle'] as Map<String, dynamic>),
      );
      final values = json['values'] as String;
      final notes = (json['notes'] as List).cast<int>();
      if (values.length != 81 || notes.length != 81) return null;
      for (var i = 0; i < 81; i++) {
        if (!game.fixed[i]) {
          game.values[i] = values.codeUnitAt(i) - 0x30;
          game.notes[i] = notes[i];
        }
      }
      for (final i in (json['fixed'] as List).cast<int>()) {
        game.fixed[i] = true;
        game.values[i] = game.solution[i];
      }
      game.elapsedSeconds = json['elapsed'] as int;
      game.mistakes = json['mistakes'] as int;
      game.hintsUsed = json['hints'] as int;
      return game;
    } on Object {
      return null;
    }
  }
}
