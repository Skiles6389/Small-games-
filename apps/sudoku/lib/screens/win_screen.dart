import 'dart:math' as math;

import 'package:game_core/game_core.dart';
import 'package:material_ui/material_ui.dart';

import '../game/game_controller.dart';
import 'navigation.dart';

class WinScreen extends StatefulWidget {
  const WinScreen({super.key, required this.outcome, required this.isDaily});

  final GameOutcome outcome;
  final bool isDaily;

  @override
  State<WinScreen> createState() => _WinScreenState();
}

class _WinScreenState extends State<WinScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) GameServices.of(context).onGameFinished(context);
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Animation<double> _interval(double begin, double end, [Curve? curve]) =>
      CurvedAnimation(
        parent: _anim,
        curve: Interval(begin, end, curve: curve ?? Curves.easeOutCubic),
      );

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final o = widget.outcome;
    final services = GameServices.of(context);

    final details = FadeTransition(
      opacity: _interval(0.35, 0.8),
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(_interval(0.35, 0.8)),
        child: Column(
          children: [
            Text(
              widget.isDaily ? 'Daily puzzle solved' : 'Solved!',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w300),
            ),
            const SizedBox(height: 6),
            Text(
              widget.isDaily
                  ? 'See you tomorrow'
                  : '${o.difficulty.label} puzzle',
              style: TextStyle(color: colors.textMuted),
            ),
            if (o.isNewBest) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'New best time',
                  style: TextStyle(
                    color: colors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  children: [
                    _Stat(label: 'Time', value: formatDuration(o.seconds)),
                    _Stat(label: 'Mistakes', value: '${o.mistakes}'),
                    _Stat(label: 'Hints', value: '${o.hintsUsed}'),
                    if (o.dailyStreak != null)
                      _Stat(label: 'Streak', value: '${o.dailyStreak}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 3),
              Center(child: _Badge(animation: _anim)),
              const SizedBox(height: 32),
              details,
              const Spacer(flex: 3),
              FadeTransition(
                opacity: _interval(0.6, 1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      onPressed: () => openGame(
                        context,
                        GameController.newGame(services, o.difficulty),
                        replace: true,
                      ),
                      child: Text('New ${o.difficulty.label} game'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Home'),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

/// A check mark that pops in, surrounded by a soft ring of dots.
class _Badge extends StatelessWidget {
  const _Badge({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final pop = CurvedAnimation(
      parent: animation,
      curve: const Interval(0, 0.45, curve: Curves.easeOutBack),
    );
    final ring = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.1, 0.9, curve: Curves.easeOutCubic),
    );
    return SizedBox(
      width: 180,
      height: 180,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(180, 180),
              painter: _RingPainter(ring.value, colors.accent),
            ),
            Transform.scale(
              scale: pop.value,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.accent.withValues(alpha: 0.16),
                  border: Border.all(color: colors.accent, width: 2),
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 52,
                  color: colors.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.t, this.color);

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final center = size.center(Offset.zero);
    final radius = 52 + 34 * t;
    final paint = Paint()..color = color.withValues(alpha: (1 - t) * 0.8 + 0.1);
    for (var k = 0; k < 12; k++) {
      final angle = k * math.pi / 6;
      final offset = Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawCircle(center + offset, 3.5 * (1 - t * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.t != t || old.color != color;
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: colors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}
