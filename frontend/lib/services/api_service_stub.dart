import 'package:dio/dio.dart';

/// No-op stub for non-web platforms.
/// BrowserHttpClientAdapter is only available in Flutter Web.
void configureWebCredentials(Dio dio) {
  // Not needed on mobile/desktop — cookies are handled natively.
}
