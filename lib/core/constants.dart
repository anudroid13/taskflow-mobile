import 'dart:io' show Platform;

class AppConstants {
  AppConstants._();

  /// Base URL for the backend API.
  /// Android emulator uses 10.0.2.2 to reach the host machine's localhost.
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 30);

  static const int maxFileSize = 10 * 1024 * 1024; // 10 MB
  static const String tokenKey = 'access_token';
  static const String userIdKey = 'user_id';
}
