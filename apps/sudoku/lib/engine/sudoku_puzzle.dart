import 'difficulty.dart';

/// A puzzle as generated: the starting numbers plus the one solution.
class SudokuPuzzle {
  SudokuPuzzle({
    required List<int> givens,
    required List<int> solution,
    required this.difficulty,
    required this.seed,
    this.dailyKey,
  }) : givens = List.unmodifiable(givens),
       solution = List.unmodifiable(solution);

  /// Starting numbers (0 = empty).
  final List<int> givens;
  final List<int> solution;
  final Difficulty difficulty;
  final int seed;

  /// Set for daily puzzles, e.g. `2026-11-24`.
  final String? dailyKey;

  bool get isDaily => dailyKey != null;

  int get clueCount => givens.where((v) => v != 0).length;

  SudokuPuzzle asDaily(String key) => SudokuPuzzle(
    givens: givens,
    solution: solution,
    difficulty: difficulty,
    seed: seed,
    dailyKey: key,
  );

  Map<String, dynamic> toJson() => {
    'givens': givens.join(),
    'solution': solution.join(),
    'difficulty': difficulty.name,
    'seed': seed,
    'daily': dailyKey,
  };

  factory SudokuPuzzle.fromJson(Map<String, dynamic> json) => SudokuPuzzle(
    givens: _digits(json['givens'] as String),
    solution: _digits(json['solution'] as String),
    difficulty: Difficulty.fromName(json['difficulty'] as String?),
    seed: json['seed'] as int,
    dailyKey: json['daily'] as String?,
  );

  static List<int> _digits(String s) {
    if (s.length != 81) throw const FormatException('Expected 81 digits');
    return [for (final ch in s.codeUnits) ch - 0x30];
  }
}
