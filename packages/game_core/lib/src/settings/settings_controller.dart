import 'package:flutter/foundation.dart';

import '../storage/key_value_store.dart';

/// On/off settings, saved automatically.
///
/// Settings shared by every game have their own getters below. A game can
/// add its own switches with [getBool]/[setBool] and its own key names.
class SettingsController extends ChangeNotifier {
  SettingsController(this._store) {
    final data = _store.getJson(_key) ?? const {};
    for (final entry in data.entries) {
      if (entry.value is bool) _flags[entry.key] = entry.value as bool;
    }
  }

  static const _key = 'settings';

  static const hapticsKey = 'haptics';
  static const soundKey = 'sound';

  final KeyValueStore _store;
  final Map<String, bool> _flags = {};

  bool getBool(String key, {required bool defaultValue}) =>
      _flags[key] ?? defaultValue;

  Future<void> setBool(String key, bool value) async {
    _flags[key] = value;
    notifyListeners();
    await _store.setJson(_key, Map<String, dynamic>.from(_flags));
  }

  bool get hapticsEnabled => getBool(hapticsKey, defaultValue: true);
  Future<void> setHapticsEnabled(bool value) => setBool(hapticsKey, value);

  bool get soundEnabled => getBool(soundKey, defaultValue: true);
  Future<void> setSoundEnabled(bool value) => setBool(soundKey, value);
}
