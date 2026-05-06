import 'package:dio/dio.dart';
import '../core/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio dio = Dio(BaseOptions(
    baseUrl: kApiPrefix,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
    extra: {'withCredentials': true}, // Critical for sending HttpOnly cookies
  ))
    ..interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          // TODO: handle 401 refresh logic
          return handler.next(error);
        },
      ),
    );
}
