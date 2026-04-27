import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../../models/donor/donor_model.dart';
import '../../../models/enums.dart';
import '../../../models/request/blood_request_model.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/service_providers.dart';
import '../../../providers/user_provider.dart';
import '../../widgets/common_widgets.dart';

class DonorHomeScreen extends ConsumerStatefulWidget {
  const DonorHomeScreen({super.key});

  @override
  ConsumerState<DonorHomeScreen> createState() => _DonorHomeScreenState();
}

class _DonorHomeScreenState extends ConsumerState<DonorHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final donorRepository = ref.watch(donorRepositoryProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useSidebar = constraints.maxWidth >= 900;

        if (useSidebar) {
          return Scaffold(
            backgroundColor: AppColors.bgLight,
            body: Row(
              children: [
                _buildSidebar(context),
                Expanded(child: _buildContent(user, donorRepository)),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.bgLight,
          body: _buildContent(user, donorRepository),
          bottomNavigationBar: _buildBottomNav(context),
        );
      },
    );
  }

  Widget _buildContent(dynamic user, donorRepository) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeader(context, ref, user?.fullName ?? 'Donor', user?.profileImageUrl),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (user != null)
                StreamBuilder<DonorModel?>(
                  stream: donorRepository.watchDonorByUserId(user.userId),
                  builder: (context, snapshot) {
                    return _buildStatusCard(context, user, snapshot.data);
                  },
                ),
              const SizedBox(height: 24),
              _buildSectionHeader(
                'Blood Requests Near You',
                'View All',
                onAction: () => context.push(AppRoutes.activeRequests),
              ),
              const SizedBox(height: 16),
              if (user != null)
                StreamBuilder<DonorModel?>(
                  stream: donorRepository.watchDonorByUserId(user.userId),
                  builder: (context, donorSnapshot) {
                    final donor = donorSnapshot.data;
                    final requestsStream = ref
                        .watch(requestServiceProvider)
                        .watchActiveRequests(
                          city: donor?.city ?? user.metadata['city'],
                        );

                    return StreamBuilder<List<BloodRequestModel>>(
                      stream: requestsStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const LoadingListPlaceholder(
                              itemCount: 3, itemHeight: 88);
                        }
                        if (snapshot.hasError) {
                          return _buildRequestFeedError(snapshot.error);
                        }
                        final requests = (snapshot.data ?? [])
                            .where(
                              (request) =>
                                  _matchesDonorBloodGroup(request, donor),
                            )
                            .toList();
                        if (requests.isEmpty) return _buildEmptyRequests();
                        return _buildRequestList(requests);
                      },
                    );
                  },
                ),
              const SizedBox(height: 24),
              _buildSectionHeader('Quick Actions', null),
              const SizedBox(height: 16),
              _buildQuickActions(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, String name, String? profileImageUrl) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 180),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hello, $name',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 16)),
                      const Text('Find Donors',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.white24,
                        backgroundImage: profileImageUrl != null &&
                                profileImageUrl.isNotEmpty
                            ? NetworkImage(profileImageUrl)
                            : null,
                        child: profileImageUrl == null || profileImageUrl.isEmpty
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: Colors.white),
                        tooltip: 'Settings',
                        onPressed: () => context.push(AppRoutes.donorSettings),
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_outline, color: Colors.white),
                        tooltip: 'Profile',
                        onPressed: () => context.push(AppRoutes.donorProfile),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        tooltip: 'Logout',
                        onPressed: () async {
                          await ref.read(authServiceProvider).signOut();
                          if (context.mounted) context.go(AppRoutes.splash);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Your contribution saves lives.',
                  style: TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    dynamic user,
    DonorModel? donor,
  ) {
    final bloodGroup =
        donor?.bloodGroup.displayName ?? user.metadata['bloodGroup'] ?? '--';
    final city = donor?.city ?? user.metadata['city'] ?? 'Location';
    final isDonor = donor != null || user.role == UserRole.donor;
    final isAvailable = donor?.isAvailable ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                      color: AppColors.primaryRed,
                      borderRadius: BorderRadius.circular(16)),
                  child: Text(bloodGroup,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your Blood Group',
                        style: TextStyle(
                            color: AppColors.textTertiaryLight, fontSize: 12)),
                    Text(
                        isDonor ? 'Active Donor' : 'Registered User',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.location_on,
                    color: AppColors.primaryRed, size: 20),
                Text(city,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Available to Donate',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('You will be visible to requesters',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiaryLight)),
                    ],
                  ),
                ),
                Switch(
                  value: isAvailable,
                  onChanged: donor == null
                      ? null
                      : (val) => _updateAvailability(context, donor, val),
                  activeThumbColor: AppColors.success,
                ),
              ],
            ),
            if (donor != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  _metricBox('Donations', donor.donationCount.toString()),
                  const SizedBox(width: 12),
                  _metricBox(
                      'Rating', donor.averageRating == 0
                          ? '-'
                          : donor.averageRating.toStringAsFixed(1)),
                  const SizedBox(width: 12),
                  _metricBox(
                      'Status', donor.verified ? 'Verified' : 'Pending'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metricBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textTertiaryDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? action,
      {VoidCallback? onAction}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action)),
      ],
    );
  }

  Widget _buildEmptyRequests() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off_rounded,
              size: 48, color: AppColors.textTertiaryDark),
          SizedBox(height: 16),
          Text('No urgent requests nearby',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text('We will notify you when someone needs blood',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: AppColors.textTertiaryDark, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRequestList(List<BloodRequestModel> requests) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final request = requests[index];
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: _buildBloodBadge(request.bloodGroupRequired.displayName),
            title: Text(request.patientName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.hospitalName),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildUrgencyChip(
                        request.urgencyLevel.displayName.toUpperCase()),
                    const SizedBox(width: 8),
                    const Text('Nearby', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context
                .push('${AppRoutes.requestDetail}?id=${request.requestId}'),
          ),
        );
      },
    );
  }

  bool _matchesDonorBloodGroup(BloodRequestModel request, DonorModel? donor) {
    if (donor == null) {
      return true;
    }

    return request.bloodGroupRequired.compatibleDonors.contains(
      donor.bloodGroup,
    );
  }

  Widget _buildRequestFeedError(Object? error) {
    final message = _friendlyFeedError(error);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(18),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: Colors.orange.withAlpha(60)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.hourglass_top_rounded,
            size: 40,
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          const Text(
            'Requests are getting ready',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _friendlyFeedError(Object? error) {
    final raw = error?.toString().toLowerCase() ?? '';
    if (raw.contains('failed-precondition') && raw.contains('index')) {
      return 'Firestore is still creating the request index. Once it finishes, matching blood requests will appear here automatically.';
    }

    return 'We could not load nearby blood requests right now. Please try again shortly.';
  }

  Widget _buildBloodBadge(String bg) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
          color: AppColors.primaryRed.withAlpha(25), shape: BoxShape.circle),
      child: Center(
          child: Text(bg,
              style: const TextStyle(
                  color: AppColors.primaryRed, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildUrgencyChip(String label) {
    final color = label == 'CRITICAL'
        ? AppColors.error
        : (label == 'URGENT' ? AppColors.warning : Colors.blue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: [
        _buildActionItem(Icons.history, 'History',
            () => context.push(AppRoutes.donorHistory)),
        _buildActionItem(Icons.location_city, 'Blood Drives',
          () => context.push(AppRoutes.donorBloodDrives)),
        _buildActionItem(Icons.edit, 'Update Profile',
            () => context.push(AppRoutes.editDonorProfile)),
        _buildActionItem(Icons.emergency_share, 'Emergency',
            () => context.push(AppRoutes.activeRequests)),
      ],
    );
  }

  Widget _buildActionItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.primaryRed),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), label: 'Profile'),
        BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
      ],
      currentIndex: 0,
      onTap: (index) {
        if (index == 1) context.push(AppRoutes.donorHistory);
        if (index == 2) context.push(AppRoutes.donorProfile);
        if (index == 3) context.push(AppRoutes.donorSettings);
      },
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 260,
      color: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LifeLink',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryRed,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Donor dashboard',
                    style: TextStyle(
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: NavigationRail(
                selectedIndex: 0,
                labelType: NavigationRailLabelType.all,
                backgroundColor: Colors.white,
                onDestinationSelected: (index) {
                  if (index == 1) context.push(AppRoutes.donorHistory);
                  if (index == 2) context.push(AppRoutes.donorProfile);
                  if (index == 3) context.push(AppRoutes.donorSettings);
                },
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_filled),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.history_outlined),
                    selectedIcon: Icon(Icons.history),
                    label: Text('History'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: Text('Profile'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.more_horiz),
                    selectedIcon: Icon(Icons.more_horiz),
                    label: Text('More'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateAvailability(
      BuildContext context, DonorModel donor, bool available) async {
    try {
      await ref
          .read(donorServiceProvider)
          .updateAvailability(donor.donorId, available);
      if (context.mounted) {
        setState(() {});
        _showMessage(
            context,
            available
                ? 'You are available to donate.'
                : 'You are marked unavailable.');
      }
    } catch (e) {
      if (context.mounted) {
        _showMessage(context, 'Could not update availability: $e');
      }
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
