import 'dart:math' as math;

/// A tiny random number generator that gives the *same* sequence of numbers
/// for the same seed on every platform (Android, iOS and the web).
///
/// Dart's built-in `Random(seed)` is not guaranteed to match between the
/// native VM and JavaScript, which would break "everyone gets the same daily
/// puzzle". This uses the xorshift32 algorithm, which only needs shifts and
/// XORs on 32-bit numbers, so it behaves identically everywhere.
class SeededRandom implements math.Random {
  SeededRandom(int seed) : _state = _normalizeSeed(seed);

  static const int _mask32 = 0xFFFFFFFF;

  int _state;

  static int _normalizeSeed(int seed) {
    final s = seed & _mask32;
    // xorshift gets stuck at zero, so swap it for an arbitrary constant.
    return s == 0 ? 0x9E3779B9 : s;
  }

  /// Next raw 32-bit unsigned value.
  int nextUint32() {
    var x = _state;
    x ^= (x << 13) & _mask32;
    x ^= x >> 17;
    x ^= (x << 5) & _mask32;
    _state = x & _mask32;
    return _state;
  }

  @override
  int nextInt(int max) {
    if (max <= 0 || max > 0x100000000) {
      throw RangeError.range(max, 1, 0x100000000, 'max');
    }
    // Rejection sampling avoids a bias towards small numbers.
    final limit = 0x100000000 - (0x100000000 % max);
    while (true) {
      final value = nextUint32();
      if (value < limit) return value % max;
    }
  }

  @override
  double nextDouble() => nextUint32() / 0x100000000;

  @override
  bool nextBool() => (nextUint32() & 1) == 1;

  /// Shuffles [list] in place (Fisher-Yates) using this generator.
  void shuffle<T>(List<T> list) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }
}

/// 32-bit FNV-1a hash of [text]. Stable across platforms (unlike
/// `String.hashCode`), so it is safe to use for seeds.
int stableHash(String text) {
  const mask32 = 0xFFFFFFFF;
  var hash = 0x811C9DC5;
  for (final unit in text.codeUnits) {
    hash ^= unit;
    // hash * 16777619, split as (hash << 24) + hash * 403 so the intermediate
    // values stay small enough to be exact in JavaScript.
    hash = (((hash << 24) & mask32) + hash * 403) & mask32;
  }
  return hash;
}
