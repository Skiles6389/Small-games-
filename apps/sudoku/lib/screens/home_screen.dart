import 'package:game_core/game_core.dart';
import 'package:material_ui/material_ui.dart';

import '../engine/difficulty.dart';
import '../game/game_controller.dart';
import 'navigation.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.clock});

  final DateTime Function() clock;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      // Coming back from a game: refresh "Continue" and the streak.
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _newGame() async {
    final services = GameServices.of(context);
    final difficulty = await showModalBottomSheet<Difficulty>(
      context: context,
      backgroundColor: CalmColors.of(context).surface,
      showDragHandle: true,
      builder: (_) => const _DifficultySheet(),
    );
    if (difficulty == null || !mounted) return;

    if (GameController.peekSavedGame(services) != null) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Start a new game?'),
          content: const Text('Your unfinished game will be replaced.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep playing'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('New game'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    if (!mounted) return;
    await _run(
      () => openGame(context, GameController.newGame(services, difficulty)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = GameServices.of(context);
    final colors = CalmColors.of(context);
    final theme = Theme.of(context);
    final saved = GameController.peekSavedGame(services);
    final today = widget.clock();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: 'Statistics',
                    icon: const Icon(Icons.bar_chart_rounded),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => StatsScreen(clock: widget.clock),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Settings',
                    icon: const Icon(Icons.tune_rounded),
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                      if (mounted) setState(() {});
                    },
                  ),
                ],
              ),
              const Spacer(flex: 2),
              const _Logo(),
              const SizedBox(height: 20),
              Text(
                'Sudoku',
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'A calm place for numbers',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textMuted),
              ),
              const Spacer(flex: 2),
              ListenableBuilder(
                listenable: services.streak,
                builder: (context, _) => _DailyCard(
                  date: today,
                  streak: services.streak.currentStreak(today),
                  completed: services.streak.isCompleted(today),
                  onTap: () => _run(
                    () => openGame(
                      context,
                      GameController.daily(services, today),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (saved != null) ...[
                FilledButton(
                  onPressed: () => _run(() async {
                    final c = GameController.resume(services);
                    if (c != null) await openGame(context, Future.value(c));
                  }),
                  child: Text(
                    'Continue  ·  ${saved.puzzle.difficulty.label}  '
                    '${formatDuration(saved.elapsedSeconds)}',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _newGame,
                  child: const Text('New game'),
                ),
              ] else
                FilledButton(
                  onPressed: _newGame,
                  child: const Text('New game'),
                ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    // A tiny 3x3 board with one highlighted cell.
    return Center(
      child: SizedBox(
        width: 72,
        height: 72,
        child: GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(9, (i) {
            final lit = i == 4;
            return DecoratedBox(
              decoration: BoxDecoration(
                color: lit ? colors.accent : colors.surfaceHigh,
                borderRadius: BorderRadius.circular(5),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({
    required this.date,
    required this.streak,
    required this.completed,
    required this.onTap,
  });

  final DateTime date;
  final int streak;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  completed ? Icons.check_rounded : Icons.wb_twilight_rounded,
                  color: colors.accent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily puzzle',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      completed
                          ? 'Solved today · come back tomorrow'
                          : longDate(date),
                      style: TextStyle(color: colors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    '$streak',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: streak > 0 ? colors.accent : colors.textMuted,
                    ),
                  ),
                  Text(
                    streak == 1 ? 'day' : 'days',
                    style: TextStyle(color: colors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultySheet extends StatelessWidget {
  const _DifficultySheet();

  static const _blurbs = {
    Difficulty.easy: 'Relaxed, plenty of numbers to start',
    Difficulty.medium: 'A gentle challenge',
    Difficulty.hard: 'Fewer clues, more thinking',
    Difficulty.expert: 'Needs advanced techniques',
  };

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 8),
              child: Text(
                'Choose difficulty',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            for (final d in Difficulty.values)
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text(d.label),
                subtitle: Text(
                  _blurbs[d]!,
                  style: TextStyle(color: colors.textMuted),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    4,
                    (i) => Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: CircleAvatar(
                        radius: 4,
                        backgroundColor: i <= d.index
                            ? colors.accent
                            : colors.surfaceHigh,
                      ),
                    ),
                  ),
                ),
                onTap: () => Navigator.pop(context, d),
              ),
          ],
        ),
      ),
    );
  }
}
