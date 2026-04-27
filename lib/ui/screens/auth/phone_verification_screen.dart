import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../providers/service_providers.dart';
import '../../../models/enums.dart';

class PhoneVerificationScreen extends ConsumerStatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  ConsumerState<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends ConsumerState<PhoneVerificationScreen> {
  bool _isLoading = false;
  String _otpCode = "";

  Future<void> _verifyOtp() async {
    if (_otpCode.length < 6) return;
    
    setState(() => _isLoading = true);
    // Real Firebase Phone Auth logic would go here
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() => _isLoading = false);
      // For demo, just say success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone verified successfully!')),
      );

      final user = await ref.read(authServiceProvider).getCurrentUser();
      if (!mounted) return;

      if (user == null) {
        context.go(AppRoutes.login);
      } else if (user.role == UserRole.donor) {
        if (user.profileCompleted) {
          context.go(AppRoutes.donorHome);
        } else {
          context.go(AppRoutes.completeDonorProfile);
        }
      } else if (user.role == UserRole.requester) {
        context.go(AppRoutes.requesterHome);
      } else {
        context.go(AppRoutes.adminHome);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Phone')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.phone_android, size: 80, color: AppColors.primaryRed).animate().fadeIn(),
              const SizedBox(height: 24),
              const Text('Enter Verification Code', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Code sent to your mobile number', style: TextStyle(color: AppColors.textSecondaryDark)),
              const SizedBox(height: 48),
              PinCodeTextField(
                appContext: context,
                length: 6,
                obscureText: false,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 50,
                  fieldWidth: 45,
                  activeFillColor: AppColors.cardDark,
                  inactiveFillColor: AppColors.cardDark,
                  selectedFillColor: AppColors.cardDark,
                  activeColor: AppColors.primaryRed,
                  inactiveColor: AppColors.borderDark,
                  selectedColor: AppColors.primaryRed,
                ),
                animationDuration: const Duration(milliseconds: 300),
                backgroundColor: Colors.transparent,
                enableActiveFill: true,
                keyboardType: TextInputType.number,
                onCompleted: (v) {
                  _otpCode = v;
                  _verifyOtp();
                },
                onChanged: (value) {
                  setState(() => _otpCode = value);
                },
              ),
              const SizedBox(height: 32),
              const Text('Resend code in 00:59', style: TextStyle(color: AppColors.textTertiaryDark)),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                child: _isLoading 
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Verify'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
