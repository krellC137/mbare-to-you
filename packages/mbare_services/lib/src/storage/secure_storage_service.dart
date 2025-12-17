import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mbare_core/mbare_core.dart';

/// Secure storage service for sensitive data
class SecureStorageService {
  SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  /// Save string value securely
  Future<Result<void>> saveString(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      return success(null);
    } catch (e) {
      return failure(CacheFailure(message: e.toString()));
    }
  }

  /// Get string value
  Future<Result<String?>> getString(String key) async {
    try {
      final value = await _storage.read(key: key);
      return success(value);
    } catch (e) {
      return failure(CacheFailure(message: e.toString()));
    }
  }

  /// Check if key exists
  Future<Result<bool>> containsKey(String key) async {
    try {
      final contains = await _storage.containsKey(key: key);
      return success(contains);
    } catch (e) {
      return failure(CacheFailure(message: e.toString()));
    }
  }

  /// Delete a key
  Future<Result<void>> delete(String key) async {
    try {
      await _storage.delete(key: key);
      return success(null);
    } catch (e) {
      return failure(CacheFailure(message: e.toString()));
    }
  }

  /// Delete all keys
  Future<Result<void>> deleteAll() async {
    try {
      await _storage.deleteAll();
      return success(null);
    } catch (e) {
      return failure(CacheFailure(message: e.toString()));
    }
  }

  /// Get all keys
  Future<Result<Map<String, String>>> readAll() async {
    try {
      final all = await _storage.readAll();
      return success(all);
    } catch (e) {
      return failure(CacheFailure(message: e.toString()));
    }
  }

  // Convenience methods for common use cases

  /// Save auth token
  Future<Result<void>> saveAuthToken(String token) async {
    return saveString('auth_token', token);
  }

  /// Get auth token
  Future<Result<String?>> getAuthToken() async {
    return getString('auth_token');
  }

  /// Delete auth token
  Future<Result<void>> deleteAuthToken() async {
    return delete('auth_token');
  }

  /// Save refresh token
  Future<Result<void>> saveRefreshToken(String token) async {
    return saveString('refresh_token', token);
  }

  /// Get refresh token
  Future<Result<String?>> getRefreshToken() async {
    return getString('refresh_token');
  }

  /// Delete refresh token
  Future<Result<void>> deleteRefreshToken() async {
    return delete('refresh_token');
  }
}
