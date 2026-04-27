import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifelink_blood/config/routes.dart';
import 'package:lifelink_blood/providers/service_providers.dart';
import 'package:lifelink_blood/models/request/blood_request_model.dart';
import 'package:lifelink_blood/models/enums.dart';
import 'package:lifelink_blood/config/theme.dart';

class RequestMonitoringScreen extends ConsumerWidget {
  const RequestMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestService = ref.watch(requestServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('All Blood Requests')),
      body: StreamBuilder<List<BloodRequestModel>>(
        stream: requestService
            .watchActiveRequests(), // In a real app, you might want a 'watchAllRequests'
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return const Center(child: Text('No active requests monitored'));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryRed.withAlpha(25),
                    child: Text(req.bloodGroupRequired.displayName,
                        style: const TextStyle(
                            color: AppColors.primaryRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                  title: Text(req.patientName),
                  subtitle: Text('${req.hospitalName} - ${req.city}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(req.status.displayName.toUpperCase(),
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: req.status == RequestStatus.pending
                                  ? AppColors.warning
                                  : AppColors.success)),
                      const SizedBox(height: 4),
                      Text(req.createdAt.toString().split(' ')[0],
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textTertiaryDark)),
                    ],
                  ),
                  onTap: () => context
                      .push('${AppRoutes.requestDetail}?id=${req.requestId}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
