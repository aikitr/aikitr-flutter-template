import 'package:shared_preferences/shared_preferences.dart';

abstract interface class PreferencesRepository {
  Future<String?> readString(String key);

  Future<void> writeString(String key, String value);
}

final class SharedPreferencesRepository implements PreferencesRepository {
  const SharedPreferencesRepository(this._preferences);

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> readString(String key) => _preferences.getString(key);

  @override
  Future<void> writeString(String key, String value) =>
      _preferences.setString(key, value);
}
