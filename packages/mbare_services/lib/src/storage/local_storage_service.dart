import 'package:shared_preferences/shared_preferences.dart';
import 'package:mbare_core/mbare_core.dart';

/// Local storage service using SharedPreferences
class LocalStorageService {
  LocalStorageService(this._prefs);

  final SharedPreferences _prefs;

  /// Save string value
  Future<Result<void>> saveString(String key, String value) async {
    try {
      await _prefs.setString(key, value);
      return success(null);
    } catch (e) {
      return failure(CacheFailure(message: e.toString()));
    }
  }

  /// Get string value
  Result<String?> getString(String key) {
    try {
      return success(_prefs.getString(key));
    } catch (e) {
      return failure(CacheFailure(message: e.toString()));
    }
  }

  /// Save int value
  Future<Result<void>> saveInt(String key, int value) async {
    try {
      await _prefs.setInt(key, value);
      return success(null);
    } catch (e) {
      return failure(CacheFailure(message: e.toString()));
    }
  }

  /// Get int value
  Result<int?> getInt(String key) {
    try {
      return success(_prefs.getInt(key));
    } catch (e) {
      return failure(CacheFailure(message: e.toString()));
    }
  }

  /// Save double value
  Future<Result<void>> saveDouble(String key, double value) async {
    try {
      await _prefs.setDouble(key, value);
      return success(null);
    } catch (e) {
      return failure(CacheFailure(message: e.toString()));
    }
  }

  /// Get double value
  Result<double?> getDouble(String key) {
    try {
      return success(_prefs.getDouble(key));
    } catch (e) {
      return failure(CacheFailure(message: e.toString()));
    }
  }

  /// Save bool value
  Future<Result<void>> saveBool(String key, {required bool value}) async {
    try {
      await _prefs.setBool(key, value);
      return success(null);
    } catch (e) {
      return failure(CacheFailure(message: e.toString()));
    }
  }

  /// Get bool value
  Result<bool?> getBool(String key) {
    try {
      return success(_prefs.getBool(key));
    } catch (e) {
      return failure(CacheFailure(message: e.toString()));
    }
  }

  /// Save string list
  Future<Result<void>> saveStringList(String key, List<String> value) async {
    try {
      await _prefs.setStringList(key, value);
      return success(null);
    } catch (e) {
      return failure(CacheFailure(message: e.toString()));
    }
  }

  /// Get string list
  Result<List<String>?> getStringList(String key) {
    try {
      return success(_prefs.getStringList(key));
    } catch (e) {
      return failure(CacheFailure(message: e.toString()));
    }
  }

  /// Check if key exists
  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }

  /// Remove a key
  Future<Result<void>> remove(String key) async {
    try {
      await _prefs.remove(key);
      return success(null);
    } catch (e) {
      return failure(CacheFailure(message: e.toString()));
    }
  }

  /// Clear all data
  Future<Result<void>> clear() async {
    try {
      await _prefs.clear();
      return success(null);
    } catch (e) {
      return failure(CacheFailure(message: e.toString()));
    }
  }

  /// Get all keys
  Set<String> getAllKeys() {
    return _prefs.getKeys();
  }
}
