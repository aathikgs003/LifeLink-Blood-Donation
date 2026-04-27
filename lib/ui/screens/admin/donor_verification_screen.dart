import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelink_blood/providers/service_providers.dart';
import 'package:lifelink_blood/models/donor/donor_model.dart';

class DonorVerificationScreen extends ConsumerWidget {
  const DonorVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminService = ref.watch(adminServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Donor Verification')),
      body: FutureBuilder<List<DonorModel>>(
        future: adminService.fetchPendingDonors(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final donors = snapshot.data ?? [];
          if (donors.isEmpty) {
            return const Center(child: Text('No pending verifications'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: donors.length,
            itemBuilder: (context, index) {
              final donor = donors[index];
              return Card(
                child: ListTile(
                  title: Text(donor.name),
                  subtitle:
                      Text('Blood Group: ${donor.bloodGroup.displayName}'),
                  trailing: ElevatedButton(
                      onPressed: () async {
                        await adminService.verifyDonor(donor.donorId);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Donor Verified!')),
                        );
                      },
                      child: const Text('Verify')),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
