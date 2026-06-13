/// Pluggable persistence for Polyboard's per-device preferences (keyboard
/// mode, language, dock side).
///
/// The package never depends on a specific storage engine. Pass any adapter
/// — wrap `SharedPreferences`, Hive, secure storage, etc. Getters are
/// synchronous (the controller reads them during construction); writes are
/// fire-and-forget. The default [InMemoryPolyboardStorage] persists nothing.
abstract class PolyboardStorage {
  String? getString(String key);
  void setString(String key, String value);
  bool? getBool(String key);
  void setBool(String key, bool value);
}

/// Default no-persistence storage — preferences last only for the session.
class InMemoryPolyboardStorage implements PolyboardStorage {
  final Map<String, Object> _data = {};

  @override
  String? getString(String key) => _data[key] as String?;

  @override
  void setString(String key, String value) => _data[key] = value;

  @override
  bool? getBool(String key) => _data[key] as bool?;

  @override
  void setBool(String key, bool value) => _data[key] = value;
}
