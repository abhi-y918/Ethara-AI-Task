import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
  }) =>
      AuthState(
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

  // LOGIN
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Step 1: Login request
      await _service.login(email, password);

      // Step 2: Wait for browser to persist HttpOnly cookies
      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      // Step 3: Fetch authenticated user
      final user = await _service.getMe();

      state = state.copyWith(
        user: user,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e),
      );
      rethrow;
    }
  }

  // SIGNUP
  Future<bool> signup(
    String name,
    String email,
    String password,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.signup(name, email, password);

      state = state.copyWith(isLoading: false);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e),
      );

      return false;
    }
  }

  // VERIFY OTP + LOGIN
  Future<bool> verifyOtpAndLogin(
    String email,
    String password,
    String otp,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // verify-otp sets cookies
      final res = await _service.verifyOtp(email, otp);

      // Wait for cookies to persist
      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      final user = UserModel.fromJson(res['user']);

      state = state.copyWith(
        user: user,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e),
      );

      return false;
    }
  }

  // LOAD CURRENT USER
  Future<void> loadCurrentUser() async {
    try {
      final loggedIn = await _service.isLoggedIn();

      if (!loggedIn) return;

      final user = await _service.getMe();

      state = state.copyWith(user: user);
    } catch (_) {}
  }

  // GOOGLE LOGIN
  Future<bool> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final googleProvider = GoogleAuthProvider();

      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      final credential = await FirebaseAuth.instance
          .signInWithPopup(googleProvider);

      final idToken = await credential.user!.getIdToken();

      // Backend login
      await _service.googleLogin(idToken!);

      // Wait for cookies to persist
      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      // Fetch authenticated user
      final user = await _service.getMe();

      state = state.copyWith(
        user: user,
        isLoading: false,
      );

      return true;
    } on FirebaseAuthException catch (e) {
      final msg =
          'Google Sign-In failed: ${e.code} — ${e.message}';

      state = state.copyWith(
        isLoading: false,
        error: msg,
      );

      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e),
      );

      return false;
    }
  }

  // LOGOUT
  Future<void> logout() async {
    await _service.logout();

    state = const AuthState();
  }
}

// Provider
final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);