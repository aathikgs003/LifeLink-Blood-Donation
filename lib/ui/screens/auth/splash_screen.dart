import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../providers/user_provider.dart';
import '../../../models/enums.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Artificial delay for splash animation
    await Future.delayed(const Duration(seconds: 3));
    _checkAuthState();
  }

  void _checkAuthState() {
    if (!mounted) return;

    final authState = ref.read(currentUserStreamProvider);
    
    authState.when(
      data: (user) {
        if (user == null) {
          context.go(AppRoutes.login);
        } else {
          if (user.role == UserRole.donor) {
            if (user.profileCompleted) {
              context.go(AppRoutes.donorHome);
            } else {
              context.go(AppRoutes.completeDonorProfile);
            }
          } else if (user.role == UserRole.requester) {
            context.go(AppRoutes.requesterHome);
          } else if (user.role == UserRole.admin) {
            context.go(AppRoutes.adminHome);
          } else {
            context.go(AppRoutes.login);
          }
        }
      },
      loading: () => null, // Wait for it
      error: (_, __) => context.go(AppRoutes.login),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to current user changes globally
    ref.listen(currentUserStreamProvider, (previous, next) {
      // Logic could also be here if we want reactive splash
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryRed, Color(0xFF7F0000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bloodtype,
                size: 80,
                color: Colors.white,
              ).animate().scale(duration: 800.ms, curve: Curves.elasticOut).shimmer(duration: 2.seconds),
            ),
            const SizedBox(height: 24),
            const Text(
              'LifeLink',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
            const SizedBox(height: 8),
            const Text(
              'Connecting Lives, Saving Hearts',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            ).animate().fadeIn(delay: 800.ms),
            const SizedBox(height: 60),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ).animate().fadeIn(),
    );
  }
}
