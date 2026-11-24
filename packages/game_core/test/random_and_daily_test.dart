import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';

void main() {
  group('SeededRandom', () {
    test('same seed gives the same sequence', () {
      final a = SeededRandom(42);
      final b = SeededRandom(42);
      expect(
        List.generate(20, (_) => a.nextUint32()),
        List.generate(20, (_) => b.nextUint32()),
      );
    });

    test('sequence is pinned so it cannot silently change', () {
      // If this test fails, every player's daily puzzle would change.
      final r = SeededRandom(1);
      expect(
        [r.nextUint32(), r.nextUint32(), r.nextUint32()],
        [270369, 67634689, 2647435461],
      );
    });

    test('nextInt stays in range and seed 0 still works', () {
      final r = SeededRandom(0);
      for (var i = 0; i < 1000; i++) {
        final v = r.nextInt(9);
        expect(v, inInclusiveRange(0, 8));
      }
    });

    test('shuffle keeps all elements', () {
      final list = List.generate(9, (i) => i + 1);
      SeededRandom(7).shuffle(list);
      expect(list.toSet(), {1, 2, 3, 4, 5, 6, 7, 8, 9});
    });
  });

  group('stableHash', () {
    test('is pinned to FNV-1a values', () {
      expect(stableHash(''), 0x811C9DC5);
      expect(stableHash('a'), 0xE40C292C);
      expect(stableHash('foobar'), 0xBF9CF968);
    });
  });

  group('DailyPuzzle', () {
    test('dateKey ignores the time of day', () {
      expect(DailyPuzzle.dateKey(DateTime(2026, 3, 7, 0, 1)), '2026-03-07');
      expect(DailyPuzzle.dateKey(DateTime(2026, 3, 7, 23, 59)), '2026-03-07');
    });

    test('parseKey round-trips', () {
      final d = DailyPuzzle.parseKey('2026-11-24')!;
      expect(DailyPuzzle.dateKey(d), '2026-11-24');
      expect(DailyPuzzle.parseKey('nope'), isNull);
    });

    test('seed is the same all day and differs between days and games', () {
      final morning = DailyPuzzle.seedFor('sudoku', DateTime(2026, 1, 1, 8));
      final night = DailyPuzzle.seedFor('sudoku', DateTime(2026, 1, 1, 22));
      final nextDay = DailyPuzzle.seedFor('sudoku', DateTime(2026, 1, 2));
      final otherGame = DailyPuzzle.seedFor('mines', DateTime(2026, 1, 1));
      expect(morning, night);
      expect(morning, isNot(nextDay));
      expect(morning, isNot(otherGame));
    });

    test('daysBetween works across DST-like boundaries', () {
      expect(
        DailyPuzzle.daysBetween(
          DateTime(2026, 3, 28, 23),
          DateTime(2026, 3, 30, 1),
        ),
        2,
      );
    });
  });

  test('formatDuration', () {
    expect(formatDuration(0), '0:00');
    expect(formatDuration(65), '1:05');
    expect(formatDuration(3725), '1:02:05');
  });
}
