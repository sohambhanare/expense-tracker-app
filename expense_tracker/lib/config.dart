import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

class Config {
  /// Base URL of the FastAPI backend.
  ///
  /// Priority:
  /// 1. Compile-time override:  --dart-define=API_URL=https://your-host
  /// 2. Android emulator host loopback (10.0.2.2)
  /// 3. localhost everywhere else (iOS simulator, desktop, web)
  static String get apiBaseUrl {
    const override = String.fromEnvironment('API_URL');
    if (override.isNotEmpty) return override;
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }
}
