import 'package:game_core/game_core.dart';

/// Sudoku-only switches, stored through the shared [SettingsController].
extension SudokuSettings on SettingsController {
  static const _showMistakes = 'sudoku.showMistakes';
  static const _highlightSame = 'sudoku.highlightSame';
  static const _highlightRelated = 'sudoku.highlightRelated';
  static const _autoRemoveNotes = 'sudoku.autoRemoveNotes';

  /// Colors wrong digits and shows a mistake counter.
  bool get showMistakes => getBool(_showMistakes, defaultValue: true);
  Future<void> setShowMistakes(bool v) => setBool(_showMistakes, v);

  /// Highlights every cell holding the selected digit.
  bool get highlightSameNumbers => getBool(_highlightSame, defaultValue: true);
  Future<void> setHighlightSameNumbers(bool v) => setBool(_highlightSame, v);

  /// Shades the selected cell's row, column and box.
  bool get highlightRelated => getBool(_highlightRelated, defaultValue: true);
  Future<void> setHighlightRelated(bool v) => setBool(_highlightRelated, v);

  /// Placing a digit removes that pencil mark from related cells.
  bool get autoRemoveNotes => getBool(_autoRemoveNotes, defaultValue: true);
  Future<void> setAutoRemoveNotes(bool v) => setBool(_autoRemoveNotes, v);
}
