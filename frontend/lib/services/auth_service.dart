import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final _dio = ApiService().dio;

  Future<void> login(String email, String password) async {
    await _dio.post('/auth/login', data: {'email': email, 'password': password});
  }

  Future<UserModel> signup(String name, String email, String password) async {
    final res = await _dio.post('/auth/signup', data: {'name': name, 'email': email, 'password': password});
    return UserModel.fromJson(res.data);
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    final res = await _dio.post('/auth/verify-otp', data: {'email': email, 'otp': otp});
    return res.data as Map<String, dynamic>;
  }

  Future<UserModel> getMe() async {
    final res = await _dio.get('/auth/me');
    return UserModel.fromJson(res.data);
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {}
  }

  Future<bool> isLoggedIn() async {
    try {
      await getMe();
      return true;
    } catch (e) {
      return false;
    }
  }
}
