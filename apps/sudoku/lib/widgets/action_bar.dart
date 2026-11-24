import 'package:game_core/game_core.dart';
import 'package:material_ui/material_ui.dart';

/// Undo / Erase / Notes / Hint buttons above the number pad.
class ActionBar extends StatelessWidget {
  const ActionBar({
    super.key,
    required this.notesMode,
    required this.canUndo,
    required this.hintNeedsAd,
    required this.onUndo,
    required this.onErase,
    required this.onToggleNotes,
    required this.onHint,
  });

  final bool notesMode;
  final bool canUndo;
  final bool hintNeedsAd;
  final VoidCallback onUndo;
  final VoidCallback onErase;
  final VoidCallback onToggleNotes;
  final VoidCallback onHint;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _ActionButton(
          key: const ValueKey('action-undo'),
          icon: Icons.undo_rounded,
          label: 'Undo',
          enabled: canUndo,
          onTap: onUndo,
        ),
        _ActionButton(
          key: const ValueKey('action-erase'),
          icon: Icons.backspace_outlined,
          label: 'Erase',
          onTap: onErase,
        ),
        _ActionButton(
          key: const ValueKey('action-notes'),
          icon: Icons.edit_outlined,
          label: 'Notes',
          active: notesMode,
          badge: _Badge(
            text: notesMode ? 'ON' : 'OFF',
            filled: notesMode,
            colors: colors,
          ),
          onTap: onToggleNotes,
        ),
        _ActionButton(
          key: const ValueKey('action-hint'),
          icon: Icons.lightbulb_outline_rounded,
          label: 'Hint',
          badge: hintNeedsAd
              ? _Badge(text: 'AD', filled: false, colors: colors)
              : null,
          onTap: onHint,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.active = false,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool active;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final fg = active ? colors.accent : colors.text;
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: active
                          ? colors.accent.withValues(alpha: 0.16)
                          : colors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: fg, size: 22),
                  ),
                  if (badge != null)
                    Positioned(right: -8, top: -4, child: badge!),
                ],
              ),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontSize: 12, color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
    required this.filled,
    required this.colors,
  });

  final String text;
  final bool filled;
  final CalmColors colors;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: filled ? colors.accent : colors.surfaceHigh,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: filled ? colors.background : colors.textMuted,
        ),
      ),
    );
  }
}
