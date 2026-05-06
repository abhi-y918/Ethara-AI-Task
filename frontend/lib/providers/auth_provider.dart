import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

String _parseError(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data.containsKey('detail')) {
      return data['detail'].toString();
    }
    return e.message ?? 'Network error';
  }
  return e.toString();
}

// State
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({UserModel? user, bool? isLoading, String? error}) => AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  bool get isAuthenticated => user != null;
}

// Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service = AuthService();

  AuthNotifier() : super(const AuthState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.login(email, password);
      final user = await _service.getMe();
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      rethrow; // Let UI handle special cases like 403
    }
  }

  Future<bool> signup(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.signup(name, email, password);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  Future<bool> verifyOtpAndLogin(String email, String password, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // verify-otp now creates the user AND sets cookies in one step
      final res = await _service.verifyOtp(email, otp);
      final user = UserModel.fromJson(res['user']);
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  Future<void> loadCurrentUser() async {
    try {
      final loggedIn = await _service.isLoggedIn();
      if (!loggedIn) return;
      final user = await _service.getMe();
      state = state.copyWith(user: user);
    } catch (_) {}
  }

  Future<void> logout() async {
    await _service.logout();
    state = const AuthState();
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
