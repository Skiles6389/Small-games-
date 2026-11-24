import 'key_value_store.dart';

/// A named place to auto-save one in-progress game, e.g. "the current Sudoku".
///
/// The game decides what goes in the map; the slot just stores and loads it.
class SaveSlot {
  SaveSlot(this._store, {required String gameId, required String name})
    : key = '$gameId.save.$name';

  final KeyValueStore _store;
  final String key;

  bool get hasSave => _store.getString(key) != null;

  Map<String, dynamic>? load() => _store.getJson(key);

  Future<void> save(Map<String, dynamic> data) => _store.setJson(key, data);

  Future<void> clear() => _store.remove(key);
}
