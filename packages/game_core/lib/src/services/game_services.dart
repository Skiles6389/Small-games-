import 'package:material_ui/material_ui.dart';

import '../daily/streak_tracker.dart';
import '../monetization/ad_service.dart';
import '../monetization/purchase_service.dart';
import '../settings/settings_controller.dart';
import '../stats/stats_repository.dart';
import '../storage/key_value_store.dart';
import '../storage/save_slot.dart';

/// Everything a game needs from the outside world, created once at startup.
///
/// Screens get it with `GameServices.of(context)`.
class GameServices {
  GameServices({
    required this.gameId,
    required this.store,
    required this.ads,
    required this.purchases,
    this.interstitialEvery = 3,
  }) : settings = SettingsController(store),
       stats = StatsRepository(store, gameId: gameId),
       streak = StreakTracker(store, gameId: gameId);

  /// Real storage on the device, fake ads and purchases.
  static Future<GameServices> create({required String gameId}) async {
    final store = await SharedPreferencesStore.create();
    final services = GameServices(
      gameId: gameId,
      store: store,
      ads: FakeAdService(),
      purchases: FakePurchaseService(store),
    );
    await services.initialize();
    return services;
  }

  /// Memory-only services with instant fake ads. Meant for tests.
  factory GameServices.inMemory({
    String gameId = 'test',
    KeyValueStore? store,
  }) {
    final s = store ?? MemoryStore();
    return GameServices(
      gameId: gameId,
      store: s,
      ads: FakeAdService(rewardedDuration: Duration.zero),
      purchases: FakePurchaseService(s),
    );
  }

  final String gameId;
  final KeyValueStore store;
  final AdService ads;
  final PurchaseService purchases;
  final SettingsController settings;
  final StatsRepository stats;
  final StreakTracker streak;

  /// Show an interstitial after every N finished games.
  final int interstitialEvery;
  int _finishedGames = 0;

  Future<void> initialize() async {
    await ads.initialize();
    await purchases.initialize();
  }

  SaveSlot saveSlot(String name) => SaveSlot(store, gameId: gameId, name: name);

  /// Asks the player to watch a rewarded ad. Returns true if they earned the
  /// reward. Players who bought "Remove Ads" get the reward straight away.
  Future<bool> earnReward(
    BuildContext context, {
    required String placement,
  }) async {
    if (purchases.adsRemoved) return true;
    final result = await ads.showRewarded(context, placement: placement);
    return result == RewardedAdResult.rewarded;
  }

  /// Call when a game ends; shows an interstitial every [interstitialEvery]
  /// games unless ads were removed.
  Future<void> onGameFinished(BuildContext context) async {
    _finishedGames++;
    if (purchases.adsRemoved || interstitialEvery <= 0) return;
    if (_finishedGames % interstitialEvery == 0) {
      await ads.showInterstitial(context, placement: 'game_end');
    }
  }

  static GameServices of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<GameServicesScope>();
    assert(scope != null, 'Wrap the app in a GameServicesScope');
    return scope!.services;
  }
}

/// Makes [GameServices] available to every widget below it.
class GameServicesScope extends InheritedWidget {
  const GameServicesScope({
    super.key,
    required this.services,
    required super.child,
  });

  final GameServices services;

  @override
  bool updateShouldNotify(GameServicesScope oldWidget) =>
      services != oldWidget.services;
}

/// A banner ad slot that disappears once ads are removed.
class AdBannerSlot extends StatelessWidget {
  const AdBannerSlot({super.key, required this.placement});

  final String placement;

  @override
  Widget build(BuildContext context) {
    final services = GameServices.of(context);
    return ListenableBuilder(
      listenable: services.purchases,
      builder: (context, _) => services.purchases.adsRemoved
          ? const SizedBox.shrink()
          : services.ads.buildBanner(context, placement: placement),
    );
  }
}
