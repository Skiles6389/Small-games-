import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// The one place games save data to.
///
/// Everything (settings, stats, saved games) is stored as text under a key.
/// Swapping the implementation lets tests use memory instead of the device.
abstract class KeyValueStore {
  String? getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}

extension KeyValueStoreJson on KeyValueStore {
  /// Reads a JSON object saved with [setJson]. Returns null if missing or
  /// unreadable (for example after a format change), so callers can simply
  /// fall back to defaults.
  Map<String, dynamic>? getJson(String key) {
    final raw = getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> setJson(String key, Map<String, dynamic> value) =>
      setString(key, jsonEncode(value));
}

/// Stores data on the device (or in browser local storage on the web).
class SharedPreferencesStore implements KeyValueStore {
  SharedPreferencesStore._(this._prefs);

  final SharedPreferences _prefs;

  static Future<SharedPreferencesStore> create() async =>
      SharedPreferencesStore._(await SharedPreferences.getInstance());

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

/// Keeps data in memory only. Handy for tests; everything is lost on restart.
class MemoryStore implements KeyValueStore {
  MemoryStore([Map<String, String>? initial]) : _data = {...?initial};

  final Map<String, String> _data;

  @override
  String? getString(String key) => _data[key];

  @override
  Future<void> setString(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }
}
