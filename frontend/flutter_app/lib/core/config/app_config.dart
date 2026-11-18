import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();

  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_override.isNotEmpty) {
      return _override;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/v1';
    }

    return 'http://127.0.0.1:8000/api/v1';
  }
}
