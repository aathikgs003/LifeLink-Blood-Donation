import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifelink_blood/config/theme.dart';
import 'package:lifelink_blood/config/routes.dart';
import 'package:lifelink_blood/providers/user_provider.dart';
import 'package:lifelink_blood/providers/service_providers.dart';
import 'package:lifelink_blood/models/request/blood_request_model.dart';
import 'package:lifelink_blood/models/enums.dart';
import '../../widgets/common_widgets.dart';

class RequesterHomeScreen extends ConsumerWidget {
  const RequesterHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final requestService = ref.watch(requestServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: user == null
          ? CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(context, ref, 'Requester'),
                ),
                const SliverPadding(
                  padding: EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: LoadingListPlaceholder(itemCount: 5, itemHeight: 96),
                  ),
                ),
              ],
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child:
                      _buildHeader(context, ref, user.fullName ?? 'Requester'),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: StreamBuilder<List<BloodRequestModel>>(
                      stream: requestService.watchRequestsByUser(user.userId),
                      builder: (context, snapshot) {
                        final requests = snapshot.data ?? [];
                        final activeRequests = requests
                            .where((r) => !_isClosedRequest(r.status))
                            .toList();
                        final pastRequests = requests
                            .where((r) => _isClosedRequest(r.status))
                            .toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatsRow(requests),
                            const SizedBox(height: 12),
                            _buildInsightRow(requests),
                            const SizedBox(height: 24),
                            _buildSectionHeader('Your Active Requests'),
                            const SizedBox(height: 16),
                            if (activeRequests.isEmpty)
                              _buildEmptyState('No active requests')
                            else
                              ...activeRequests.map(
                                  (req) => _buildRequestCard(context, req)),
                            const SizedBox(height: 24),
                            _buildSectionHeader('Past Requests'),
                            const SizedBox(height: 16),
                            if (pastRequests.isEmpty)
                              _buildEmptyState('No past history')
                            else
                              ...pastRequests
                                  .map((req) => _buildHistoryItem(req)),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createRequest),
        label: const Text('New Request'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primaryRed,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, String name) {
    return Container(
      width: double.infinity,
      height: 200,
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
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('My Requests',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.settings_outlined,
                            color: Colors.white),
                        tooltip: 'Settings',
                        onPressed: () => context.push(AppRoutes.requesterSettings),
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_outline,
                            color: Colors.white),
                        tooltip: 'Profile',
                        onPressed: () => context.push(AppRoutes.requesterProfile),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: () async {
                          await ref.read(authServiceProvider).signOut();
                          if (context.mounted) context.go(AppRoutes.splash);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Manage your requests, $name',
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Text(message,
            style: const TextStyle(color: AppColors.textTertiaryDark)),
      ),
    );
  }

  Widget _buildStatsRow(List<BloodRequestModel> requests) {
    final activeCount =
        requests.where((r) => !_isClosedRequest(r.status)).length;
    final successRate = requests.isEmpty
        ? '0%'
        : '${((requests.where((r) => r.status == RequestStatus.completed).length / requests.length) * 100).toInt()}%';

    return Row(
      children: [
        _statBox(activeCount.toString(), 'Active', Icons.pending_actions,
            AppColors.warning),
        const SizedBox(width: 12),
        _statBox(
            requests.length.toString(), 'Total', Icons.history, AppColors.info),
        const SizedBox(width: 12),
        _statBox(successRate, 'Success', Icons.check_circle_outline,
            AppColors.success),
      ],
    );
  }

  Widget _buildInsightRow(List<BloodRequestModel> requests) {
    final now = DateTime.now();
    final last30 = now.subtract(const Duration(days: 30));
    final last7 = now.subtract(const Duration(days: 7));

    final criticalActive = requests
        .where((r) =>
            !_isClosedRequest(r.status) &&
            r.urgencyLevel == UrgencyLevel.critical)
        .length;

    final completedLast30 = requests
        .where((r) =>
            r.status == RequestStatus.completed &&
            r.updatedAt.isAfter(last30))
        .length;

    final createdLast7 = requests.where((r) => r.createdAt.isAfter(last7)).length;

    final trendLabel = createdLast7 == 0
        ? 'No new requests this week'
        : '$createdLast7 created this week';

    return Column(
      children: [
        Row(
          children: [
            _statBox(criticalActive.toString(), 'Critical', Icons.warning_amber,
                AppColors.error),
            const SizedBox(width: 12),
            _statBox(completedLast30.toString(), 'Completed (30d)',
                Icons.check_circle, AppColors.success),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Row(
            children: [
              const Icon(Icons.insights_outlined, color: AppColors.info),
              const SizedBox(width: 10),
              Text(
                trendLabel,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statBox(String val, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDark)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(val,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textTertiaryDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildRequestCard(BuildContext context, BloodRequestModel request) {
    final progress = _requestProgress(request.status);

    return Card(
      child: InkWell(
        onTap: () =>
            context.push('${AppRoutes.requestDetail}?id=${request.requestId}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                        color: AppColors.primaryRed.withAlpha(25),
                        shape: BoxShape.circle),
                    child: Center(
                        child: Text(request.bloodGroupRequired.displayName,
                            style: const TextStyle(
                                color: AppColors.primaryRed,
                                fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(request.patientName,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        Text(request.hospitalName,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiaryDark)),
                      ],
                    ),
                  ),
                  _urgencyBadge(request.urgencyLevel),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Status', style: TextStyle(fontSize: 12)),
                  Text(request.status.displayName.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                  value: progress, borderRadius: BorderRadius.circular(4)),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: AppColors.textTertiaryDark),
                  const SizedBox(width: 4),
                  Text(request.city,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textTertiaryDark)),
                  const Spacer(),
                  const Text('View Details',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryRed,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _urgencyBadge(UrgencyLevel level) {
    final label = level.displayName.toUpperCase();
    final color = level == UrgencyLevel.critical
        ? AppColors.error
        : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(51),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildHistoryItem(BloodRequestModel request) {
    final bool isSuccess = request.status == RequestStatus.completed;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
          backgroundColor: AppColors.cardDark,
          child: Text(request.bloodGroupRequired.displayName,
              style: const TextStyle(fontSize: 12))),
      title: Text('Request for ${request.patientName}'),
      subtitle: Text(request.createdAt.toString().split(' ')[0],
          style: const TextStyle(fontSize: 12)),
      trailing: Text(request.status.displayName.toUpperCase(),
          style: TextStyle(
              color: isSuccess ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.bold,
              fontSize: 12)),
    );
  }

  bool _isClosedRequest(RequestStatus status) {
    return status == RequestStatus.accepted ||
        status == RequestStatus.completed ||
        status == RequestStatus.cancelled ||
        status == RequestStatus.expired;
  }

  double _requestProgress(RequestStatus status) {
    switch (status) {
      case RequestStatus.accepted:
        return 0.85;
      case RequestStatus.completed:
        return 1.0;
      case RequestStatus.partiallyFulfilled:
        return 0.65;
      case RequestStatus.inProgress:
        return 0.4;
      case RequestStatus.pending:
        return 0.2;
      case RequestStatus.cancelled:
      case RequestStatus.expired:
        return 1.0;
    }
  }
}
