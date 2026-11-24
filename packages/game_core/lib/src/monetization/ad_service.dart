import 'package:material_ui/material_ui.dart';

import '../theme/calm_theme.dart';

/// What happened when the player was offered a rewarded ad.
enum RewardedAdResult {
  /// The ad finished; give the player their reward.
  rewarded,

  /// The player closed the ad early; no reward.
  dismissed,

  /// No ad could be loaded (offline, no fill, ...).
  unavailable,
}

/// Everything a game needs from an ad network.
///
/// The app only talks to this interface. Today it is backed by
/// [FakeAdService]; later an `AdMobAdService` can implement the same methods
/// using the real SDK without touching game code.
abstract class AdService {
  Future<void> initialize();

  /// Shows a "watch an ad to get a reward" video.
  Future<RewardedAdResult> showRewarded(
    BuildContext context, {
    required String placement,
  });

  /// Shows a full-screen ad between games.
  Future<void> showInterstitial(
    BuildContext context, {
    required String placement,
  });

  /// A banner ad widget (usually at the bottom of a screen).
  Widget buildBanner(BuildContext context, {required String placement});
}

/// Pretend ads for development: no SDK, no accounts, no network.
///
/// * Rewarded: shows a small "ad placeholder" dialog that counts down and
///   then grants the reward. The player can also close it early.
/// * Interstitial: does nothing except log (so playtesting is not annoying).
/// * Banner: a quiet placeholder strip so layouts have the right space.
class FakeAdService implements AdService {
  FakeAdService({this.rewardedDuration = const Duration(seconds: 2)});

  /// How long the fake rewarded ad "plays". Use [Duration.zero] in tests.
  final Duration rewardedDuration;

  @override
  Future<void> initialize() async {}

  @override
  Future<RewardedAdResult> showRewarded(
    BuildContext context, {
    required String placement,
  }) async {
    if (rewardedDuration == Duration.zero) return RewardedAdResult.rewarded;
    final result = await showDialog<RewardedAdResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FakeRewardedDialog(duration: rewardedDuration),
    );
    return result ?? RewardedAdResult.dismissed;
  }

  @override
  Future<void> showInterstitial(
    BuildContext context, {
    required String placement,
  }) async {
    debugPrint('[FakeAdService] interstitial "$placement" would show here');
  }

  @override
  Widget buildBanner(BuildContext context, {required String placement}) =>
      const _FakeBanner();
}

class _FakeRewardedDialog extends StatefulWidget {
  const _FakeRewardedDialog({required this.duration});

  final Duration duration;

  @override
  State<_FakeRewardedDialog> createState() => _FakeRewardedDialogState();
}

class _FakeRewardedDialogState extends State<_FakeRewardedDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    _progress.forward().whenComplete(() {
      if (mounted) Navigator.of(context).pop(RewardedAdResult.rewarded);
    });
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    return AlertDialog(
      title: const Text('Ad placeholder'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A rewarded video ad would play here.\n'
            'No real ads are wired up yet.',
            style: TextStyle(color: colors.textMuted),
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _progress,
            builder: (context, _) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: _progress.value),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(RewardedAdResult.dismissed),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _FakeBanner extends StatelessWidget {
  const _FakeBanner();

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    return Container(
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.gridLine)),
      ),
      child: Text(
        'Banner ad placeholder',
        style: TextStyle(color: colors.textMuted, fontSize: 12),
      ),
    );
  }
}
