import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../../providers/service_providers.dart';
import '../../../providers/user_provider.dart';
import '../../widgets/common_widgets.dart';

class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(AppRoutes.editAdminProfile),
          ),
        ],
      ),
      body: user == null
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: LoadingListPlaceholder(itemCount: 4, itemHeight: 88),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(
                    user.fullName,
                    user.createdAt.year,
                    user.profileImageUrl,
                  ),
                  const SizedBox(height: 24),
                  _buildInfoCard('Admin Information', [
                    _infoTile(Icons.person_outline, 'Full Name',
                        user.fullName ?? 'Not set'),
                    _infoTile(Icons.email_outlined, 'Email', user.email),
                    _infoTile(Icons.phone_outlined, 'Phone',
                        _safeValue(user.phoneNumber)),
                    _infoTile(Icons.security_outlined, 'Role', 'Admin'),
                  ]),
                  const SizedBox(height: 16),
                  _buildInfoCard('Location', [
                    _infoTile(Icons.location_city_outlined, 'City',
                        _safeValue(user.metadata['city'])),
                    _infoTile(Icons.home_outlined, 'Address',
                        _safeValue(user.metadata['address'])),
                  ]),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.push(AppRoutes.editAdminProfile),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  const SizedBox(height: 12),
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
            ),
    );
  }

  Widget _buildHeader(String? name, int joinedYear, String? profileImageUrl) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: AppColors.primaryRed,
            backgroundImage:
                profileImageUrl != null && profileImageUrl.isNotEmpty
                    ? NetworkImage(profileImageUrl)
                    : null,
            child: profileImageUrl == null || profileImageUrl.isEmpty
                ? const Icon(Icons.admin_panel_settings,
                    size: 44, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            name?.isNotEmpty == true ? name! : 'Admin User',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            'Member since $joinedYear',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textTertiaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _safeValue(String? value) {
    if (value == null || value.trim().isEmpty) return 'Not provided';
    return value;
  }
}
