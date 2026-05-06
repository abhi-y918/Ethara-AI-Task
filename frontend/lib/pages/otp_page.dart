import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../core/constants.dart';

class OtpPage extends ConsumerWidget {
  final String email;
  final String password;

  const OtpPage({super.key, required this.email, required this.password});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otpCtrl = TextEditingController();
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Check your email', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text('We sent a 6-digit code to $email', style: const TextStyle(color: Color(0xFFB0B0C0))),
                    const SizedBox(height: 32),
                    TextField(
                      controller: otpCtrl, 
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(labelText: 'OTP Code', counterText: ''),
                    ),
                    const SizedBox(height: 8),
                    if (auth.error != null)
                      Text(auth.error!, style: const TextStyle(color: Colors.redAccent)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: auth.isLoading
                          ? null
                          : () async {
                              final success = await ref.read(authProvider.notifier).verifyOtpAndLogin(email, password, otpCtrl.text.trim());
                              if (success && context.mounted) {
                                context.go(kRouteDashboard);
                              }
                            },
                      child: auth.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Verify & Login'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go(kRouteLogin),
                      child: const Text('Back to Login'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
