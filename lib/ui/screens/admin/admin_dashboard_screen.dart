import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:lifelink_blood/config/theme.dart';
import 'package:lifelink_blood/config/routes.dart';
import 'package:lifelink_blood/providers/service_providers.dart';
import 'package:lifelink_blood/providers/user_provider.dart';
import 'package:lifelink_blood/models/analytics/analytics_model.dart';
import '../../widgets/common_widgets.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsyncValue =
        ref.watch(analyticsServiceProvider).getSystemAnalytics();
    final user = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push(AppRoutes.adminProfile),
          ),
          IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () => context.push(AppRoutes.adminNotifications)),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.adminSettings),
          ),
        ],
      ),
      drawer: _buildDrawer(context, ref, user),
      body: FutureBuilder<SystemAnalytics>(
        future: analyticsAsyncValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
                return const SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                    children: [
                  LoadingListPlaceholder(itemCount: 4, itemHeight: 110),
                  SizedBox(height: 16),
                  LoadingSkeletonBlock(height: 220),
                  SizedBox(height: 16),
                  LoadingListPlaceholder(itemCount: 4, itemHeight: 72),
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final data = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsGrid(data),
                const SizedBox(height: 24),
                _buildChartsSection(data),
                const SizedBox(height: 24),
                _buildRecentActivity(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref, dynamic user) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primaryRed),
            accountName: Text(user?.fullName ?? 'System Admin'),
            accountEmail: Text(user?.email ?? 'admin@lifelink.com'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: user?.profileImageUrl != null &&
                      user.profileImageUrl.toString().isNotEmpty
                  ? NetworkImage(user.profileImageUrl)
                  : null,
              child: user?.profileImageUrl == null ||
                      user.profileImageUrl.toString().isEmpty
                  ? const Icon(Icons.admin_panel_settings,
                      color: AppColors.primaryRed)
                  : null,
            ),
            onDetailsPressed: () => context.push(AppRoutes.adminProfile),
          ),
          _drawerItem(Icons.person_outline, 'My Profile',
              () => context.push(AppRoutes.adminProfile)),
            _drawerItem(Icons.settings_outlined, 'Settings',
              () => context.push(AppRoutes.adminSettings)),
          _drawerItem(Icons.dashboard, 'Dashboard', () => context.pop()),
          _drawerItem(Icons.people, 'User Management',
              () => context.push(AppRoutes.userManagement)),
          _drawerItem(Icons.verified_user, 'Donor Verification',
              () => context.push(AppRoutes.donorVerification)),
          _drawerItem(Icons.monitor_heart, 'Request Monitoring',
              () => context.push(AppRoutes.requestMonitoring)),
          _drawerItem(Icons.analytics, 'Analytics',
              () => context.push(AppRoutes.analytics)),
          const Spacer(),
          _drawerItem(Icons.logout, 'Logout', () async {
            try {
              // Close drawer first
              Navigator.of(context).pop();

              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go(AppRoutes.splash);
            } catch (e) {
              debugPrint('Logout Error: $e');
            }
          }, isDanger: true),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap,
      {bool isDanger = false}) {
    return ListTile(
      leading: Icon(icon, color: isDanger ? AppColors.error : null),
      title: Text(title,
          style: TextStyle(color: isDanger ? AppColors.error : null)),
      onTap: onTap,
    );
  }

  Widget _buildStatsGrid(SystemAnalytics data) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _statCard(
            'Total Users', '${data.totalUsers}', Icons.people, AppColors.info),
        _statCard('Donors', '${data.totalDonors}', Icons.favorite,
            AppColors.primaryRed),
        _statCard('Active Requests', '${data.activeRequests}',
            Icons.pending_actions, AppColors.warning),
        _statCard('Successful', '${data.completedDonations}',
            Icons.check_circle, AppColors.success),
      ],
    );
  }

  Widget _statCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderDark)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(val,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              Text(title,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textTertiaryDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(SystemAnalytics data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Request Trends',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: data.dailyRequests
                      .asMap()
                      .entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
                      .toList(),
                  isCurved: true,
                  color: AppColors.primaryRed,
                  barWidth: 4,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                      show: true, color: AppColors.primaryRed.withAlpha(51)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person, size: 20)),
              title: const Text('Recent system event'),
              subtitle: const Text('Updated just now'),
              trailing: TextButton(
                onPressed: () => context.push(AppRoutes.analytics),
                child: const Text('Open'),
              ),
            );
          },
        ),
      ],
    );
  }
}
