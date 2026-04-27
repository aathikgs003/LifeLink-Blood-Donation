import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../../models/enums.dart';
import '../../../models/request/blood_request_model.dart';
import '../../../providers/service_providers.dart';
import '../../../providers/user_provider.dart';

class ActiveRequestsScreen extends ConsumerWidget {
  const ActiveRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Requests')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final requestService = ref.watch(requestServiceProvider);
    final isDonor = user.role == UserRole.donor;
    final requestsStream = isDonor
        ? requestService.watchActiveRequests(city: user.metadata['city'])
        : requestService.watchRequestsByUser(user.userId);

    return Scaffold(
      appBar: AppBar(title: const Text('Active Requests')),
      body: StreamBuilder<List<BloodRequestModel>>(
        stream: requestsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final requests = (snapshot.data ?? [])
              .where((request) =>
                request.status != RequestStatus.accepted &&
                  request.status != RequestStatus.completed &&
                  request.status != RequestStatus.cancelled &&
                  request.status != RequestStatus.expired)
              .toList();
          if (requests.isEmpty) {
            return Center(
                child: Text(isDonor
                    ? 'No active blood requests nearby right now.'
                    : 'You do not have any active requests right now.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryRed.withAlpha(25),
                    child: Text(
                      request.bloodGroupRequired.displayName,
                      style: const TextStyle(
                          color: AppColors.primaryRed,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                      '${request.bloodGroupRequired.displayName} Blood Request'),
                  subtitle: Text(
                      '${request.hospitalName} - ${request.unitsRequired - request.unitsCollected} unit(s) needed'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(
                      '${AppRoutes.requestDetail}?id=${request.requestId}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
