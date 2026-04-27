import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../models/enums.dart';
import '../../../utils/validators.dart';
import '../../../utils/auth_error_message.dart';
import '../../../providers/service_providers.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  UserRole _selectedRole = UserRole.donor;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreedToTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate() && _agreedToTerms) {
      setState(() => _isLoading = true);
      
      try {
        final authService = ref.read(authServiceProvider);
        final user = await authService.signUp(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _selectedRole,
        );

        if (mounted) {
          setState(() => _isLoading = false);
          if (user != null) {
            // Success - Redirect to splash which will route to correct home
            context.go(AppRoutes.splash);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Signup failed. Please try again.')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(authErrorMessage(e))),
          );
        }
      }
    } else if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to terms and conditions')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Join us and save lives',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondaryDark),
              ).animate().fadeIn(),
              const SizedBox(height: 32),
              
              const Text(
                'I want to',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildRoleCard(
                      UserRole.donor,
                      'Donate Blood',
                      Icons.favorite,
                      'Save lives by donating',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildRoleCard(
                      UserRole.requester,
                      'Request Blood',
                      Icons.medical_services,
                      'Find donors quickly',
                    ),
                  ),
                ],
              ).animate().slideY(begin: 0.1, duration: 400.ms),
              
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: Validators.validateEmail,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_reset),
                  suffixIcon: IconButton(
                    icon: Icon(_isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                  ),
                ),
                validator: (value) {
                  if (value != _passwordController.text) return 'Passwords do not match';
                  return Validators.validatePassword(value);
                },
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (val) => setState(() => _agreedToTerms = val!),
                  ),
                  const Expanded(
                    child: Text('I agree to the Terms & Conditions and Privacy Policy'),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSignup,
                child: _isLoading 
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ) 
                  : const Text('Sign Up'),
              ),
              const SizedBox(height: 24),
              
              Center(
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: const Text('Already have an account? Login'),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(),
      ),
    );
  }

  Widget _buildRoleCard(UserRole role, String title, IconData icon, String subtitle) {
    bool isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryRed.withAlpha(25) : AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryRed : AppColors.borderDark,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isSelected ? AppColors.primaryRed : AppColors.textTertiaryDark),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.textTertiaryDark)),
          ],
        ),
      ),
    );
  }
}
