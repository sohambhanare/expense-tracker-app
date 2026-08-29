import 'dart:io' show Platform;

import 'package:cronet_http/cronet_http.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// Returns the best HTTP client for the platform.
///
/// Android: Cronet (Chromium's network stack — same DNS resolution and
/// connection handling as Chrome, resilient to flaky resolvers).
/// Elsewhere: the default package:http client.
http.Client createPlatformHttpClient() {
  if (!kIsWeb && Platform.isAndroid) {
    return CronetClient.defaultCronetEngine();
  }
  return http.Client();
}
