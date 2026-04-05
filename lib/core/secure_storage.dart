import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'constants.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static Future<void> setToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return _storage.read(key: AppConstants.tokenKey);
  }

  static Future<void> setUserId(String userId) async {
    await _storage.write(key: AppConstants.userIdKey, value: userId);
  }

  static Future<String?> getUserId() async {
    return _storage.read(key: AppConstants.userIdKey);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
