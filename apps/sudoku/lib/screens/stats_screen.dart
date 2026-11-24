import 'package:game_core/game_core.dart';
import 'package:material_ui/material_ui.dart';

import '../engine/difficulty.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key, required this.clock});

  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final services = GameServices.of(context);
    final colors = CalmColors.of(context);
    final today = clock();

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: ListenableBuilder(
        listenable: Listenable.merge([services.stats, services.streak]),
        builder: (context, _) {
          final stats = services.stats;
          final overall = stats.overall;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    children: [
                      _Big(label: 'Played', value: '${overall.played}'),
                      _Big(label: 'Won', value: '${overall.won}'),
                      _Big(
                        label: 'Win rate',
                        value: '${(overall.winRate * 100).round()}%',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    children: [
                      _Big(
                        label: 'Daily streak',
                        value: '${services.streak.currentStreak(today)}',
                        accent: true,
                      ),
                      _Big(
                        label: 'Best streak',
                        value: '${services.streak.bestStreak}',
                      ),
                      _Big(
                        label: 'Dailies won',
                        value: '${stats.statsFor('daily').won}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'BY DIFFICULTY',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              for (final d in Difficulty.values) ...[
                _DifficultyRow(label: d.label, stats: stats.statsFor(d.name)),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Big extends StatelessWidget {
  const _Big({required this.label, required this.value, this.accent = false});

  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w400,
              color: accent ? colors.accent : colors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: colors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _DifficultyRow extends StatelessWidget {
  const _DifficultyRow({required this.label, required this.stats});

  final String label;
  final ModeStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    String time(int? s) => s == null ? '–' : formatDuration(s);
    Widget cell(String title, String value) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(color: colors.textMuted, fontSize: 11)),
        ],
      ),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            cell('Won', '${stats.won}/${stats.played}'),
            cell('Best', time(stats.bestSeconds)),
            cell('Average', time(stats.averageSeconds)),
          ],
        ),
      ),
    );
  }
}
