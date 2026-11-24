import 'package:game_core/game_core.dart';
import 'package:material_ui/material_ui.dart';

import '../game/sudoku_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = GameServices.of(context);
    final colors = CalmColors.of(context);
    final settings = services.settings;
    final purchases = services.purchases;

    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: colors.textMuted,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );

    Widget toggle(
      String title,
      String subtitle,
      bool value,
      ValueChanged<bool> onChanged,
    ) => SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(color: colors.textMuted)),
      value: value,
      onChanged: onChanged,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: Listenable.merge([settings, purchases]),
        builder: (context, _) => ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            section('Gameplay'),
            toggle(
              'Show mistakes',
              'Wrong numbers turn red',
              settings.showMistakes,
              settings.setShowMistakes,
            ),
            toggle(
              'Highlight same numbers',
              'Shade every cell with the selected number',
              settings.highlightSameNumbers,
              settings.setHighlightSameNumbers,
            ),
            toggle(
              'Highlight row, column and box',
              'Shade the cells related to the selection',
              settings.highlightRelated,
              settings.setHighlightRelated,
            ),
            toggle(
              'Auto-remove notes',
              'Placing a number clears it from nearby notes',
              settings.autoRemoveNotes,
              settings.setAutoRemoveNotes,
            ),
            toggle(
              'Vibration',
              'A light tap when you press a cell or number',
              settings.hapticsEnabled,
              settings.setHapticsEnabled,
            ),
            section('Ads'),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              title: const Text('Remove ads'),
              subtitle: Text(
                purchases.adsRemoved
                    ? 'Thanks! Ads are off and hints are free.'
                    : 'Test purchase · ${purchases.removeAdsPrice}',
                style: TextStyle(color: colors.textMuted),
              ),
              trailing: purchases.adsRemoved
                  ? Icon(Icons.check_rounded, color: colors.accent)
                  : const Icon(Icons.chevron_right_rounded),
              onTap: purchases.adsRemoved ? null : purchases.buyRemoveAds,
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              title: const Text('Restore purchases'),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                await purchases.restorePurchases();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Purchases restored')),
                );
              },
            ),
            if (purchases is FakePurchaseService && purchases.adsRemoved)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: const Text('Bring ads back (testing)'),
                onTap: purchases.resetForTesting,
              ),
            section('Data'),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              title: Text(
                'Reset statistics',
                style: TextStyle(color: colors.error),
              ),
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Reset statistics?'),
                    content: const Text(
                      'Games played, best times and your daily streak will be '
                      'cleared. This cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await services.stats.reset();
                  await services.streak.reset();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
