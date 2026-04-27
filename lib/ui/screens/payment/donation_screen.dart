import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';
import '../../../providers/service_providers.dart';
import '../../../providers/user_provider.dart';

class DonationScreen extends ConsumerStatefulWidget {
  const DonationScreen({super.key});

  @override
  ConsumerState<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends ConsumerState<DonationScreen> {
  int _selectedAmount = 500;
  bool _isProcessing = false;

  void _handleDonation() async {
    final user = ref.read(userProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in before donating.')));
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final success = await ref.read(paymentServiceProvider).processDonation(
            userId: user.userId,
            amount: _selectedAmount.toDouble(),
            email: user.email,
            phone: user.phoneNumber ?? '',
          );

      if (mounted) {
        setState(() => _isProcessing = false);
        if (success) {
          _showSuccessDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Payment failed: $e')));
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thank You!'),
        content:
            const Text('Your donation has been received. You are a lifesaver!'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support LifeLink')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Colors.orange, Colors.redAccent]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                children: [
                  Icon(Icons.volunteer_activism, size: 60, color: Colors.white),
                  SizedBox(height: 16),
                  Text('Your donation helps save lives',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(
                      'Support our platform to connect more donors with those in need',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ).animate().fadeIn().scale(),
            const SizedBox(height: 32),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Select Amount',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [100, 500, 1000, 2000, 5000]
                  .map((amt) => _amountChip(amt))
                  .toList(),
            ),
            const SizedBox(height: 32),
            _impactCard('Rs 100 helps connect 10 donors', Icons.people_outline),
            _impactCard(
                'Rs 500 supports emergency alerts', Icons.emergency_outlined),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _isProcessing ? null : _handleDonation,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60)),
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Donate Rs $_selectedAmount Now'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _amountChip(int amt) {
    bool isSelected = _selectedAmount == amt;
    return GestureDetector(
      onTap: () => setState(() => _selectedAmount = amt),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryRed : AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? AppColors.primaryRed : AppColors.borderDark),
        ),
        child: Text('Rs $amt',
            style: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _impactCard(String msg, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryRed),
        title: Text(msg, style: const TextStyle(fontSize: 14)),
      ),
    );
  }
}
