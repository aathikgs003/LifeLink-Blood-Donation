import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';

class OnboardingWelcomeScreen extends StatefulWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  State<OnboardingWelcomeScreen> createState() => _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState extends State<OnboardingWelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            children: [
              _buildPage(
                'Save Lives', 
                'Every drop of blood counts. Join the movement to save lives daily.', 
                Icons.favorite, 
                AppColors.primaryRed,
              ),
              _buildPage(
                'Find Donors', 
                'Quickly find and connect with matching donors in your vicinity.', 
                Icons.map_rounded, 
                Colors.blueAccent,
              ),
              _buildPage(
                'Emergency Support', 
                'Instant alerts and connection for critical emergencies.', 
                Icons.emergency_share_rounded, 
                Colors.orangeAccent,
              ),
            ],
          ),
          Positioned(
            bottom: 50,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: const Text('Skip'),
                ),
                Row(
                  children: List.generate(
                    3, 
                    (index) => _indicator(index == _currentPage),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: () {
                    if (_currentPage < 2) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 600), 
                        curve: Curves.easeInOutBack,
                      );
                    } else {
                      context.go(AppRoutes.login);
                    }
                  },
                  child: Icon(
                    _currentPage == 2 ? Icons.check : Icons.arrow_forward_rounded,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 500.ms),
          ),
        ],
      ),
    );
  }

  Widget _indicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8, 
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryRed : AppColors.borderDark, 
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildPage(String title, String desc, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withAlpha(25),
            Colors.transparent,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 100, color: color),
            ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
            const SizedBox(height: 60),
            Text(
              title, 
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
            const SizedBox(height: 20),
            Text(
              desc, 
              textAlign: TextAlign.center, 
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondaryDark,
                  ),
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }
}
