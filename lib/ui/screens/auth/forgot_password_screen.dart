import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../providers/service_providers.dart';
import '../../../utils/validators.dart';
import '../../../utils/auth_error_message.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await ref.read(authServiceProvider).resetPassword(_emailController.text.trim());
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isSent = true;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(authErrorMessage(e))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _isSent ? _buildSuccessState() : _buildFormState(),
        ),
      ).animate().fadeIn(),
    );
  }

  List<Widget> _buildFormState() {
    return [
      const Icon(Icons.lock_reset, size: 80, color: AppColors.primaryRed).animate().fadeIn(),
      const SizedBox(height: 24),
      const Text('Forgot Password?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text(
        'Enter your email to receive reset instructions',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 16),
      ),
      const SizedBox(height: 32),
      Form(
        key: _formKey,
        child: TextFormField(
          controller: _emailController,
          validator: Validators.validateEmail,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
      ),
      const SizedBox(height: 32),
      ElevatedButton(
        onPressed: _isLoading ? null : _handleReset,
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text('Send Reset Link'),
      ),
    ];
  }

  List<Widget> _buildSuccessState() {
    return [
      const Icon(Icons.check_circle_outline, size: 80, color: AppColors.success).animate().scale(),
      const SizedBox(height: 24),
      const Text('Email Sent!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      const Text(
        'Check your inbox for password reset instructions.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 16),
      ),
      const SizedBox(height: 32),
      ElevatedButton(
        onPressed: () => context.go(AppRoutes.login),
        child: const Text('Back to Login'),
      ),
    ];
  }
}
