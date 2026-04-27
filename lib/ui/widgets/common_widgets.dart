import 'package:flutter/material.dart';
import '../../models/enums.dart';
import '../../config/theme.dart';

class LoadingSkeletonBlock extends StatelessWidget {
  final double height;
  final double width;
  final BorderRadius borderRadius;

  const LoadingSkeletonBlock({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.35, end: 0.85),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.borderDark.withValues(alpha: value),
            borderRadius: borderRadius,
          ),
        );
      },
      onEnd: () {},
    );
  }
}

class LoadingListPlaceholder extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const LoadingListPlaceholder({
    super.key,
    this.itemCount = 4,
    this.itemHeight = 84,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => LoadingSkeletonBlock(height: itemHeight),
    );
  }
}

class UrgencyBadge extends StatelessWidget {
  final UrgencyLevel urgency;
  const UrgencyBadge({super.key, required this.urgency});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (urgency) {
      case UrgencyLevel.critical: color = AppColors.error; break;
      case UrgencyLevel.urgent: color = AppColors.warning; break;
      case UrgencyLevel.normal: color = AppColors.success; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(51), borderRadius: BorderRadius.circular(4)),
      child: Text(
        urgency.displayName.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class BloodGroupBadge extends StatelessWidget {
  final String group;
  final bool isLarge;
  const BloodGroupBadge({super.key, required this.group, this.isLarge = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isLarge ? 80 : 50,
      height: isLarge ? 80 : 50,
      decoration: BoxDecoration(color: AppColors.primaryRed.withAlpha(25), shape: BoxShape.circle),
      child: Center(
        child: Text(
          group,
          style: TextStyle(
            color: AppColors.primaryRed,
            fontWeight: FontWeight.bold,
            fontSize: isLarge ? 24 : 16,
          ),
        ),
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
        child: isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(label),
      );
    }
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
      child: isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(label),
    );
  }
}
