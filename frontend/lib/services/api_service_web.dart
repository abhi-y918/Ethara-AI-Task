import 'package:dio/dio.dart';
import 'package:dio/browser.dart';

/// Sets withCredentials = true on Flutter Web so the browser
/// includes HttpOnly cookies in cross-origin Dio requests.
void configureWebCredentials(Dio dio) {
  (dio.httpClientAdapter as BrowserHttpClientAdapter).withCredentials = true;
}
