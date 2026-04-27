import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../models/donor/donor_model.dart';
import '../../../providers/service_providers.dart';
import '../../../providers/user_provider.dart';

class DonorAvailabilityScreen extends ConsumerStatefulWidget {
  const DonorAvailabilityScreen({super.key});

  @override
  ConsumerState<DonorAvailabilityScreen> createState() =>
      _DonorAvailabilityScreenState();
}

class _DonorAvailabilityScreenState
    extends ConsumerState<DonorAvailabilityScreen> {
  DonorModel? _donor;
  bool _isAvailable = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadDonor);
  }

  Future<void> _loadDonor() async {
    final user = ref.read(userProvider);
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final donor =
        await ref.read(donorServiceProvider).getDonorProfile(user.userId);
    if (mounted) {
      setState(() {
        _donor = donor;
        _isAvailable = donor?.isAvailable ?? false;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAvailability() async {
    final donor = _donor;
    if (donor == null) {
      _showMessage('Complete your donor profile before changing availability.');
      return;
    }

    final nextValue = !_isAvailable;
    setState(() => _isAvailable = nextValue);

    try {
      await ref
          .read(donorServiceProvider)
          .updateAvailability(donor.donorId, nextValue);
      if (mounted) {
        _showMessage(nextValue
            ? 'You are available to donate.'
            : 'You are marked unavailable.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAvailable = !nextValue);
        _showMessage('Could not update availability: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Availability')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: _toggleAvailability,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isAvailable
                            ? AppColors.success.withAlpha(51)
                            : AppColors.error.withAlpha(51),
                        border: Border.all(
                            color: _isAvailable
                                ? AppColors.success
                                : AppColors.error,
                            width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: (_isAvailable
                                    ? AppColors.success
                                    : AppColors.error)
                                .withAlpha(76),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isAvailable
                                  ? Icons.check_circle
                                  : Icons.do_not_disturb_on,
                              size: 60,
                              color: _isAvailable
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _isAvailable ? 'AVAILABLE' : 'UNAVAILABLE',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _isAvailable
                                      ? AppColors.success
                                      : AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    ).animate().scale(),
                  ),
                  const SizedBox(height: 48),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _infoRow('Last Donation',
                              _formatDate(_donor?.lastDonationDate)),
                          const SizedBox(height: 12),
                          _infoRow('Next Eligibility',
                              _formatDate(_donor?.nextEligibleDonationDate)),
                          const Divider(height: 32),
                          const Text(
                            'Marking yourself as available will notify requesters near you.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiaryDark),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _infoRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(val,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.primaryRed)),
      ],
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Not recorded';
    return value.toLocal().toString().split(' ').first;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
