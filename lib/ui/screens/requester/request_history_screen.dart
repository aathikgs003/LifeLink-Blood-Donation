import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../../models/enums.dart';
import '../../../models/request/blood_request_model.dart';
import '../../../providers/service_providers.dart';
import '../../../providers/user_provider.dart';
import '../../widgets/common_widgets.dart';

class RequestHistoryScreen extends ConsumerWidget {
  const RequestHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Request History')),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: LoadingListPlaceholder(itemCount: 5, itemHeight: 84),
        ),
      );
    }

    final requestService = ref.watch(requestServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Request History')),
      body: StreamBuilder<List<BloodRequestModel>>(
        stream: requestService.watchRequestsByUser(user.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: LoadingListPlaceholder(itemCount: 5, itemHeight: 84),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final history = (snapshot.data ?? [])
              .where((request) =>
                request.status == RequestStatus.accepted ||
                  request.status == RequestStatus.completed ||
                  request.status == RequestStatus.cancelled ||
                  request.status == RequestStatus.expired)
              .toList();

          if (history.isEmpty) {
            return const Center(
                child: Text('No completed or cancelled requests yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final request = history[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryRed.withAlpha(25),
                    child: Text(request.bloodGroupRequired.displayName),
                  ),
                  title: Text(request.patientName),
                  subtitle: Text(
                      '${request.hospitalName} - ${request.status.displayName}'),
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
