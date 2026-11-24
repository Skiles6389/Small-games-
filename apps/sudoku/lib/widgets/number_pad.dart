import 'package:game_core/game_core.dart';
import 'package:material_ui/material_ui.dart';

import '../game/game_controller.dart';

/// Digits 1-9. Each key shows how many of that digit are still missing and
/// fades out once all nine are placed correctly.
class NumberPad extends StatelessWidget {
  const NumberPad({super.key, required this.controller, required this.onDigit});

  final GameController controller;
  final ValueChanged<int> onDigit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var d = 1; d <= 9; d++)
          Expanded(
            child: _PadKey(
              digit: d,
              remaining: 9 - controller.game.correctCount(d),
              notesMode: controller.notesMode,
              onTap: () => onDigit(d),
            ),
          ),
      ],
    );
  }
}

class _PadKey extends StatelessWidget {
  const _PadKey({
    required this.digit,
    required this.remaining,
    required this.notesMode,
    required this.onTap,
  });

  final int digit;
  final int remaining;
  final bool notesMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final done = remaining <= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: done ? 0.25 : 1,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            key: ValueKey('pad-$digit'),
            borderRadius: BorderRadius.circular(12),
            onTap: done ? null : onTap,
            child: SizedBox(
              height: 68,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    style: TextStyle(
                      fontSize: notesMode ? 24 : 32,
                      height: 1.1,
                      fontWeight: notesMode ? FontWeight.w500 : FontWeight.w300,
                      color: notesMode ? colors.textMuted : colors.accent,
                    ),
                    child: Text('$digit'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    done ? '' : '$remaining',
                    style: TextStyle(fontSize: 11, color: colors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
