import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../providers/service_providers.dart';
import '../../../models/enums.dart';
import '../../../utils/auth_error_message.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  int _resendCooldown = 0;
  Timer? _timer;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final authService = ref.read(authServiceProvider);
      final user = await authService.getCurrentUser();
      if (user != null && user.emailVerified) {
        timer.cancel();
        if (mounted) {
          _handleVerified(user);
        }
      }
    });
  }

  void _handleVerified(dynamic user) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email verified successfully!')),
    );
    if (user.role == UserRole.donor) {
      if (user.profileCompleted) {
        context.go(AppRoutes.donorHome);
      } else {
        context.go(AppRoutes.completeDonorProfile);
      }
    } else if (user.role == UserRole.requester) {
      context.go(AppRoutes.requesterHome);
    } else {
      context.go(AppRoutes.login);
    }
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _resendEmail() async {
    try {
      await ref.read(authServiceProvider).verifyEmail();
      if (!mounted) return;
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authErrorMessage(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_read_outlined,
                    size: 100, color: AppColors.primaryRed)
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 32),
            Text('Verify Your Email',
                style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 16),
            const Text(
              "We've sent a verification link to your email. Please check your inbox and click the link to verify your account.",
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: AppColors.textSecondaryDark, fontSize: 16),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () async {
                final user =
                    await ref.read(authServiceProvider).getCurrentUser();
                if (!context.mounted) return;
                if (user != null && user.emailVerified) {
                  _handleVerified(user);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Email not verified yet. Please check your inbox.')),
                  );
                }
              },
              child: const Text("I've Verified"),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _resendCooldown > 0 ? null : _resendEmail,
              child: Text(_resendCooldown > 0
                  ? 'Resend in ${_resendCooldown}s'
                  : 'Resend Email'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go(AppRoutes.login),
              child: const Text('Change Email'),
            ),
          ],
        ),
      ).animate().fadeIn(),
    );
  }
}
