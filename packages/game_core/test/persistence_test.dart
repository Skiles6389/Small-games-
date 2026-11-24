import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';

void main() {
  group('StreakTracker', () {
    test('counts consecutive days and resets after a gap', () async {
      final store = MemoryStore();
      final streak = StreakTracker(store, gameId: 'g');
      final day1 = DateTime(2026, 5, 1, 9);

      expect(streak.currentStreak(day1), 0);
      await streak.recordCompletion(day1);
      await streak.recordCompletion(day1.add(const Duration(hours: 5)));
      expect(streak.currentStreak(day1), 1, reason: 'same day counts once');

      final day2 = DateTime(2026, 5, 2, 20);
      await streak.recordCompletion(day2);
      expect(streak.currentStreak(day2), 2);
      expect(
        streak.currentStreak(DateTime(2026, 5, 3)),
        2,
        reason: 'still alive the next day',
      );
      expect(
        streak.currentStreak(DateTime(2026, 5, 4)),
        0,
        reason: 'a missed day breaks it',
      );

      await streak.recordCompletion(DateTime(2026, 5, 5));
      expect(streak.currentStreak(DateTime(2026, 5, 5)), 1);
      expect(streak.bestStreak, 2);
      expect(streak.isCompleted(DateTime(2026, 5, 5, 23)), isTrue);

      final reloaded = StreakTracker(store, gameId: 'g');
      expect(reloaded.currentStreak(DateTime(2026, 5, 5)), 1);
      expect(reloaded.bestStreak, 2);
    });
  });

  group('StatsRepository', () {
    test('tracks played, won and best times per mode', () async {
      final store = MemoryStore();
      final stats = StatsRepository(store, gameId: 'g');
      await stats.recordStart('easy');
      await stats.recordStart('easy');
      expect(await stats.recordWin('easy', 300), isTrue);
      await stats.recordStart('easy');
      expect(await stats.recordWin('easy', 400), isFalse);
      expect(await stats.recordWin('easy', 200), isTrue);

      final easy = stats.statsFor('easy');
      expect(easy.played, 3);
      expect(easy.won, 3);
      expect(easy.bestSeconds, 200);
      expect(easy.averageSeconds, 300);
      expect(stats.statsFor('hard').played, 0);

      final reloaded = StatsRepository(store, gameId: 'g');
      expect(reloaded.statsFor('easy').bestSeconds, 200);
      expect(reloaded.overall.played, 3);

      await reloaded.reset();
      expect(reloaded.overall.played, 0);
    });
  });

  group('SettingsController', () {
    test('persists flags with defaults', () async {
      final store = MemoryStore();
      final settings = SettingsController(store);
      expect(settings.hapticsEnabled, isTrue);
      expect(settings.getBool('custom', defaultValue: false), isFalse);
      await settings.setHapticsEnabled(false);
      await settings.setBool('custom', true);

      final reloaded = SettingsController(store);
      expect(reloaded.hapticsEnabled, isFalse);
      expect(reloaded.getBool('custom', defaultValue: false), isTrue);
    });
  });

  group('SaveSlot', () {
    test('saves, loads and clears', () async {
      final store = MemoryStore();
      final slot = SaveSlot(store, gameId: 'g', name: 'current');
      expect(slot.hasSave, isFalse);
      await slot.save({
        'a': 1,
        'b': [1, 2],
      });
      expect(slot.load(), {
        'a': 1,
        'b': [1, 2],
      });
      await slot.clear();
      expect(slot.load(), isNull);
    });

    test('corrupt data loads as null instead of crashing', () {
      final store = MemoryStore({'g.save.current': '{not json'});
      expect(SaveSlot(store, gameId: 'g', name: 'current').load(), isNull);
    });
  });

  group('FakePurchaseService', () {
    test('remove ads is remembered', () async {
      final store = MemoryStore();
      final p = FakePurchaseService(store);
      await p.initialize();
      expect(p.adsRemoved, isFalse);
      expect(await p.buyRemoveAds(), PurchaseResult.purchased);
      expect(p.adsRemoved, isTrue);

      final again = FakePurchaseService(store);
      await again.initialize();
      expect(again.adsRemoved, isTrue);
    });
  });
}
