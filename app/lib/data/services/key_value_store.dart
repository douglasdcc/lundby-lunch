import 'package:shared_preferences/shared_preferences.dart';

/// Simple persistent key-value storage.
abstract interface class KeyValueStore {
  String? getString(String key);

  List<String>? getStringList(String key);

  Future<void> setString(String key, String value);

  Future<void> setStringList(String key, List<String> value);
}

/// [KeyValueStore] backed by `shared_preferences`.
class SharedPreferencesStore implements KeyValueStore {
  SharedPreferencesStore(this._preferences);

  final SharedPreferencesWithCache _preferences;

  @override
  String? getString(String key) => _preferences.getString(key);

  @override
  List<String>? getStringList(String key) => _preferences.getStringList(key);

  @override
  Future<void> setString(String key, String value) =>
      _preferences.setString(key, value);

  @override
  Future<void> setStringList(String key, List<String> value) =>
      _preferences.setStringList(key, value);
}
