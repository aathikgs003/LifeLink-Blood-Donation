import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../../models/donor/donor_model.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/service_providers.dart';
import '../../../providers/user_provider.dart';
import '../../widgets/common_widgets.dart';

class DonorProfileScreen extends ConsumerWidget {
  const DonorProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final donorRepository = ref.watch(donorRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(AppRoutes.editDonorProfile),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.donorSettings),
          ),
        ],
      ),
      body: user == null
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: LoadingListPlaceholder(itemCount: 5, itemHeight: 88),
            )
          : StreamBuilder<DonorModel?>(
              stream: donorRepository.watchDonorByUserId(user.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: LoadingListPlaceholder(itemCount: 5, itemHeight: 88),
                  );
                }

                final donor = snapshot.data;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildHeader(context, user, donor),
                      const SizedBox(height: 24),
                      _buildStats(donor),
                      const SizedBox(height: 24),
                      _buildInfoCard('Personal Information', [
                        _infoTile(Icons.email_outlined, 'Email', user.email),
                        _infoTile(Icons.phone_outlined, 'Phone',
                            user.phoneNumber ?? 'Not provided'),
                        _infoTile(Icons.location_city_outlined, 'City',
                            donor?.city ?? user.metadata['city'] ?? 'Not provided'),
                        _infoTile(Icons.bloodtype_outlined, 'Blood Group',
                            donor?.bloodGroup.displayName ?? user.metadata['bloodGroup'] ?? 'Not recorded'),
                      ]),
                      const SizedBox(height: 16),
                      _buildInfoCard('Medical Status', [
                        _infoTile(Icons.history, 'Last Donation',
                            _formatDate(donor?.lastDonationDate)),
                        _infoTile(Icons.event_available, 'Next Eligibility',
                            _formatDate(donor?.nextEligibleDonationDate)),
                        _infoTile(Icons.favorite_outline, 'Availability',
                            donor == null
                                ? 'Not set'
                                : (donor.isAvailable ? 'Available' : 'Unavailable')),
                        _infoTile(Icons.verified_user_outlined, 'Verification',
                            donor == null
                                ? 'Not set'
                                : (donor.verified ? 'Verified' : 'Pending')),
                      ]),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showDonorId(context, user.userId),
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Show Donor ID'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () async {
                          await ref.read(authServiceProvider).signOut();
                          if (context.mounted) {
                            context.go(AppRoutes.splash);
                          }
                        },
                        child: const Text(
                          'Log Out',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user, DonorModel? donor) {
    final profileImageUrl = donor?.profileImageUrl ?? user.profileImageUrl;
    final displayName = donor?.name.isNotEmpty == true
        ? donor!.name
        : (user.fullName ?? 'Unnamed User');

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.primaryRed,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _imageProvider(profileImageUrl),
                child: profileImageUrl == null || profileImageUrl.isEmpty
                    ? const Icon(Icons.person, color: Colors.white, size: 42)
                    : null,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (donor?.verified ?? user.isActive)
                    ? AppColors.success
                    : AppColors.warning,
                shape: BoxShape.circle,
              ),
              child: Icon(
                donor?.verified == true
                    ? Icons.verified_user
                    : Icons.person_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ).animate().scale(),
        const SizedBox(height: 16),
        Text(
          displayName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          donor != null ? 'Donor' : 'User',
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.primaryRed,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          'Member since ${user.createdAt.year}',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textTertiaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStats(DonorModel? donor) {
    final donations = donor?.donationCount ?? 0;
    final units = _totalUnits(donor?.donationHistory ?? const []);
    final rating = donor?.averageRating ?? 0.0;
    final availability = donor?.isAvailable == true ? 'Available' : 'Inactive';

    return Row(
      children: [
        _statItem('$donations', 'Donations'),
        _statItem('$units', 'Units'),
        _statItem(rating == 0 ? '-' : rating.toStringAsFixed(1), 'Rating'),
        _statItem(availability, 'Status'),
      ],
    );
  }

  Widget _statItem(String val, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            val,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textTertiaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textTertiaryDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textTertiaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  val,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDonorId(BuildContext context, String donorId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Donor ID'),
        content: SelectableText(donorId),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  ImageProvider? _imageProvider(String? url) {
    if (url == null || url.isEmpty) return null;
    return NetworkImage(url);
  }

  int _totalUnits(List<Map<String, dynamic>> history) {
    var total = 0;
    for (final entry in history) {
      final raw = _pickFirst(entry, const ['units', 'unitCount']);
      total += int.tryParse(_asString(raw, fallback: '0')) ?? 0;
    }
    return total;
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Not recorded';
    return value.toLocal().toString().split(' ').first;
  }

  static dynamic _pickFirst(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      if (source.containsKey(key) && source[key] != null) {
        return source[key];
      }
    }
    return null;
  }

  static String _asString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final result = value.toString().trim();
    return result.isEmpty ? fallback : result;
  }
}
