import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/constants.dart';

// BrowserHttpClientAdapter is only available on Flutter Web (dart:html)
// We use a conditional import to avoid compile errors on mobile/desktop.
import 'api_service_stub.dart'
    if (dart.library.html) 'api_service_web.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio dio = _buildDio();

  Dio _buildDio() {
    final d = Dio(BaseOptions(
      baseUrl: kApiPrefix,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    // ✅ CRITICAL for Flutter Web cross-origin cookie sending
    if (kIsWeb) {
      configureWebCredentials(d);
    }

    d.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          // TODO: handle 401 refresh logic
          return handler.next(error);
        },
      ),
    );

    return d;
  }
}
