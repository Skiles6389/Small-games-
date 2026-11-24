import 'package:game_core/game_core.dart';
import 'package:material_ui/material_ui.dart';

import '../engine/sudoku_solver.dart';
import '../game/game_controller.dart';
import '../game/sudoku_settings.dart';

enum _Shade { none, related, sameNumber, selected }

/// The 9x9 grid. Rebuilds whenever the [controller] changes.
class SudokuBoard extends StatelessWidget {
  const SudokuBoard({super.key, required this.controller, this.onCellTap});

  final GameController controller;
  final ValueChanged<int>? onCellTap;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final game = controller.game;
    final settings = controller.settings;
    final selected = controller.selected;
    final selectedDigit = selected == null ? 0 : game.values[selected];
    final showMistakes = settings.showMistakes;

    _Shade shadeFor(int i) {
      if (selected == null) return _Shade.none;
      if (i == selected) return _Shade.selected;
      if (settings.highlightSameNumbers &&
          selectedDigit != 0 &&
          game.values[i] == selectedDigit) {
        return _Shade.sameNumber;
      }
      if (settings.highlightRelated &&
          (SudokuSolver.rowOf(i) == SudokuSolver.rowOf(selected) ||
              SudokuSolver.colOf(i) == SudokuSolver.colOf(selected) ||
              SudokuSolver.boxOf(i) == SudokuSolver.boxOf(selected))) {
        return _Shade.related;
      }
      return _Shade.none;
    }

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellSize = constraints.maxWidth / 9;
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: ColoredBox(
              color: colors.surface,
              child: Stack(
                children: [
                  Column(
                    children: [
                      for (var r = 0; r < 9; r++)
                        Expanded(
                          child: Row(
                            children: [
                              for (var c = 0; c < 9; c++)
                                Expanded(
                                  child: _Cell(
                                    key: ValueKey('cell-${r * 9 + c}'),
                                    index: r * 9 + c,
                                    value: game.values[r * 9 + c],
                                    notes: game.notes[r * 9 + c],
                                    isGiven: game.isGiven(r * 9 + c),
                                    isRevealed: game.isRevealed(r * 9 + c),
                                    isWrong:
                                        showMistakes && game.isWrong(r * 9 + c),
                                    shade: shadeFor(r * 9 + c),
                                    noteHighlight: settings.highlightSameNumbers
                                        ? selectedDigit
                                        : 0,
                                    cellSize: cellSize,
                                    onTap: onCellTap,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(painter: _GridPainter(colors)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    super.key,
    required this.index,
    required this.value,
    required this.notes,
    required this.isGiven,
    required this.isRevealed,
    required this.isWrong,
    required this.shade,
    required this.noteHighlight,
    required this.cellSize,
    required this.onTap,
  });

  final int index;
  final int value;
  final int notes;
  final bool isGiven;
  final bool isRevealed;
  final bool isWrong;
  final _Shade shade;
  final int noteHighlight;
  final double cellSize;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);

    final background = switch (shade) {
      _Shade.selected => colors.accent.withValues(alpha: 0.30),
      _Shade.sameNumber => colors.accent.withValues(alpha: 0.15),
      _Shade.related => Colors.white.withValues(alpha: 0.045),
      _Shade.none => Colors.transparent,
    };

    final Color digitColor;
    if (isWrong) {
      digitColor = colors.error;
    } else if (isGiven) {
      digitColor = colors.text;
    } else if (isRevealed) {
      digitColor = colors.text.withValues(alpha: 0.75);
    } else {
      digitColor = colors.accent;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap == null ? null : () => onTap!(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        color: isWrong
            ? Color.alphaBlend(colors.error.withValues(alpha: 0.10), background)
            : background,
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutBack,
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: Tween(begin: 0.6, end: 1.0).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: value != 0
              ? Text(
                  '$value',
                  key: ValueKey('v$value'),
                  style: TextStyle(
                    fontSize: cellSize * 0.56,
                    height: 1,
                    fontWeight: isGiven ? FontWeight.w500 : FontWeight.w400,
                    color: digitColor,
                  ),
                )
              : notes != 0
              ? _Notes(
                  key: const ValueKey('notes'),
                  notes: notes,
                  highlight: noteHighlight,
                  cellSize: cellSize,
                )
              : const SizedBox.shrink(key: ValueKey('empty')),
        ),
      ),
    );
  }
}

class _Notes extends StatelessWidget {
  const _Notes({
    super.key,
    required this.notes,
    required this.highlight,
    required this.cellSize,
  });

  final int notes;
  final int highlight;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final style = TextStyle(
      fontSize: cellSize * 0.24,
      height: 1,
      fontWeight: FontWeight.w500,
    );
    return Padding(
      padding: EdgeInsets.all(cellSize * 0.06),
      child: Column(
        children: [
          for (var r = 0; r < 3; r++)
            Expanded(
              child: Row(
                children: [
                  for (var c = 0; c < 3; c++)
                    Expanded(
                      child: Center(
                        child: Builder(
                          builder: (context) {
                            final d = r * 3 + c + 1;
                            if (notes & (1 << d) == 0) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              '$d',
                              style: style.copyWith(
                                color: d == highlight
                                    ? colors.accent
                                    : colors.textMuted,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter(this.colors);

  final CalmColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final thin = Paint()
      ..color = colors.gridLine
      ..strokeWidth = 1;
    final thick = Paint()
      ..color = colors.boxLine
      ..strokeWidth = 2;
    final step = size.width / 9;
    for (var k = 1; k < 9; k++) {
      final p = k * step;
      final paint = k % 3 == 0 ? thick : thin;
      canvas.drawLine(Offset(p, 0), Offset(p, size.height), paint);
      canvas.drawLine(Offset(0, p), Offset(size.width, p), paint);
    }
    final border = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(14),
    ).deflate(1);
    canvas.drawRRect(
      border,
      Paint()
        ..color = colors.boxLine
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => oldDelegate.colors != colors;
}
