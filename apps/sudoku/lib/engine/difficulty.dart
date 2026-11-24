/// The four difficulty levels.
///
/// [targetClues] is how many numbers the generator tries to leave on the
/// board (fewer = harder). [singlesOnly] means the puzzle must be solvable
/// using only the two most basic techniques (see `SudokuGrader`).
enum Difficulty {
  easy(label: 'Easy', targetClues: 40, singlesOnly: true),
  medium(label: 'Medium', targetClues: 32, singlesOnly: true),
  hard(label: 'Hard', targetClues: 27, singlesOnly: false),
  expert(label: 'Expert', targetClues: 22, singlesOnly: false);

  const Difficulty({
    required this.label,
    required this.targetClues,
    required this.singlesOnly,
  });

  final String label;
  final int targetClues;
  final bool singlesOnly;

  /// Expert puzzles should need more than basic techniques.
  bool get needsAdvancedTechniques => this == Difficulty.expert;

  static Difficulty fromName(String? name) => Difficulty.values.firstWhere(
    (d) => d.name == name,
    orElse: () => Difficulty.easy,
  );
}
