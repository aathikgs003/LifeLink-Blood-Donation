import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../../models/enums.dart';
import '../../../models/request/blood_request_model.dart';
import '../../../providers/service_providers.dart';
import '../../../providers/user_provider.dart';

class RequestDetailScreen extends ConsumerWidget {
  final String? requestId;

  const RequestDetailScreen({super.key, this.requestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = requestId;
    final user = ref.watch(userProvider);
    if (id == null || id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Request Details')),
        body: const Center(child: Text('No request selected.')),
      );
    }

    final requestService = ref.watch(requestServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () async {
              final request = await requestService.getRequestById(id);
              if (request == null) {
                if (context.mounted) {
                  _showMessage(context, 'Request details are unavailable.');
                }
                return;
              }
              Share.share(
                'Blood request: ${request.bloodGroupRequired.displayName} needed for ${request.patientName} at ${request.hospitalName}, ${request.city}.',
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<BloodRequestModel?>(
        stream: requestService.watchRequest(id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final request = snapshot.data;
          if (request == null) {
            return const Center(child: Text('Request not found.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildStatusHeader(request),
                const SizedBox(height: 24),
                _buildPatientInfo(request),
                if (user != null) ...[
                  const SizedBox(height: 16),
                  _buildRoleAwareActionCard(context, ref, user, request),
                ],
                const SizedBox(height: 16),
                _buildProgressCard(request),
                const SizedBox(height: 16),
                _buildHospitalInfo(context, request),
                const SizedBox(height: 24),                if (user != null) ...[
                  _buildRequesterContactCard(context, ref, user, request),
                  const SizedBox(height: 16),
                ],                _buildDonorList(context, ref, request),
                const SizedBox(height: 32),
                _buildActions(context, ref, request),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoleAwareActionCard(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
    BloodRequestModel request,
  ) {
    final isRequester = user.userId == request.userId;
    final isDonor = user.role == UserRole.donor;
    final isClosed = request.status == RequestStatus.accepted ||
      request.status == RequestStatus.cancelled ||
        request.status == RequestStatus.completed ||
        request.status == RequestStatus.expired;
    final alreadyAccepted = request.acceptedDonors.any(
      (donor) =>
          donor['userId']?.toString() == user.userId ||
          donor['donorUserId']?.toString() == user.userId,
    );
    if (isRequester) {
      return const SizedBox.shrink();
    }

    if (!isDonor) {
      return _buildInfoCard(
        icon: Icons.info_outline,
        title: 'Request details',
        message: 'Only donor accounts can accept blood requests.',
        color: AppColors.warning,
      );
    }

    if (alreadyAccepted) {
      return _buildInfoCard(
        icon: Icons.verified,
        title: 'You accepted this request',
        message:
            'The receiver has been informed and this request has been closed for other donors.',
        color: AppColors.success,
      );
    }

    if (isClosed) {
      return _buildInfoCard(
        icon: Icons.check_circle_outline,
        title: 'Request closed',
        message: 'This blood request is no longer accepting donor responses.',
        color: AppColors.textSecondaryDark,
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Respond as Donor',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'If you accept, this request will be marked as accepted and other matched donors will be notified.',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _confirmDonorAcceptance(context, ref, request),
                icon: const Icon(Icons.volunteer_activism),
                label: const Text('I Can Donate'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(message),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(BloodRequestModel request) {
    final isCritical = request.urgencyLevel == UrgencyLevel.critical;
    final color = isCritical ? AppColors.error : AppColors.warning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: color.withAlpha(25), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(isCritical ? Icons.report_problem : Icons.pending_actions,
              color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${request.urgencyLevel.displayName.toUpperCase()} NEED',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${request.unitsRequired - request.unitsCollected} more unit(s) of ${request.bloodGroupRequired.displayName} needed',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildPatientInfo(BloodRequestModel request) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Patient',
                    style: TextStyle(
                        color: AppColors.textTertiaryDark, fontSize: 12)),
                Text('Blood Group',
                    style: TextStyle(
                        color: AppColors.textTertiaryDark, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: Text(request.patientName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold))),
                Text(
                  request.bloodGroupRequired.displayName,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryRed),
                ),
              ],
            ),
            const Divider(height: 32),
            _detailRow('Age', '${request.patientAge} Years'),
            _detailRow('Requested',
                DateFormat('d MMM, h:mm a').format(request.createdAt)),
            _detailRow('Contact', request.contactNumber),
            _detailRow('Status', request.status.displayName),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Flexible(
            child: Text(
              val,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(BloodRequestModel request) {
    final progress = request.unitsRequired == 0
        ? 0.0
        : (request.unitsCollected / request.unitsRequired)
            .clamp(0.0, 1.0)
            .toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Collection Progress',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '${request.unitsCollected}/${request.unitsRequired} Units',
                  style: const TextStyle(
                      color: AppColors.primaryRed, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.primaryRed.withAlpha(25),
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHospitalInfo(BuildContext context, BloodRequestModel request) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.cardDark,
          child: Icon(Icons.local_hospital, color: AppColors.primaryRed),
        ),
        title: Text(request.hospitalName),
        subtitle: Text('${request.address}, ${request.city}'),
        trailing: IconButton(
          icon: const Icon(Icons.directions),
          onPressed: () => _openDirections(context, request),
        ),
      ),
    );
  }

  Widget _buildDonorList(
      BuildContext context, WidgetRef ref, BloodRequestModel request) {
    if (request.acceptedDonors.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.person_search, color: AppColors.textTertiaryDark),
              SizedBox(width: 12),
              Expanded(
                  child: Text('No donors have accepted this request yet.')),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accepted Donors (${request.acceptedDonors.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...request.acceptedDonors
            .map((donor) => _donorItem(context, ref, request, donor)),
      ],
    );
  }

  Widget _donorItem(
    BuildContext context,
    WidgetRef ref,
    BloodRequestModel request,
    Map<String, dynamic> donor,
  ) {
    final name =
        donor['name'] ?? donor['fullName'] ?? donor['donorName'] ?? 'Donor';
    final distance = donor['distance']?.toString() ??
        donor['distanceText'] ??
        'Distance unavailable';
    final donorUserId =
        donor['userId'] ?? donor['donorUserId'] ?? donor['donorId'];
    final phone = donor['phone'] ?? donor['phoneNumber'];
    final chatDisabled = request.status == RequestStatus.completed;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(name.toString()),
        subtitle: Text(distance.toString()),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, size: 20),
              onPressed: chatDisabled
                  ? null
                  : () => _openChat(
                      context,
                      ref,
                      request,
                      donorUserId?.toString(),
                    ),
              tooltip: chatDisabled
                  ? 'Chat is disabled after request completion'
                  : 'Chat with donor',
            ),
            IconButton(
              icon: const Icon(Icons.phone_outlined, size: 20),
              onPressed: () => _callDonor(context, phone?.toString()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequesterContactCard(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
    BloodRequestModel request,
  ) {
    final isRequester = user.userId == request.userId;
    final isDonor = user.role == UserRole.donor;
    final hasAccepted = request.acceptedDonors.any(
      (donor) =>
          donor['userId']?.toString() == user.userId ||
          donor['donorUserId']?.toString() == user.userId,
    );

    // Only show for donors who have accepted the request
    if (isRequester || !isDonor || !hasAccepted) {
      return const SizedBox.shrink();
    }

    final chatDisabled = request.status == RequestStatus.completed;
    final requesterName = request.patientName; // Could be extended to get actual name from DB
    final requesterPhone = request.contactNumber;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact Information',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.cardDark,
              child: Icon(Icons.person_outline, color: AppColors.primaryRed),
            ),
            title: Text(requesterName),
            subtitle: const Text('Blood Request Requester'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, size: 20),
                  onPressed: chatDisabled
                      ? null
                      : () => _openChat(
                          context,
                          ref,
                          request,
                          request.userId,
                        ),
                  tooltip: chatDisabled
                      ? 'Chat is disabled after request completion'
                      : 'Chat with requester',
                ),
                IconButton(
                  icon: const Icon(Icons.phone_outlined, size: 20),
                  onPressed: () => _callDonor(context, requesterPhone),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(
      BuildContext context, WidgetRef ref, BloodRequestModel request) {
    final user = ref.watch(userProvider);
    final isTerminalClosed = request.status == RequestStatus.cancelled ||
      request.status == RequestStatus.completed ||
      request.status == RequestStatus.expired;
    final canCancel = !isTerminalClosed && request.status != RequestStatus.accepted;
    final canComplete = request.status == RequestStatus.accepted;
    final isRequester = user?.userId == request.userId;

    if (!isRequester) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: canCancel
                ? () => _confirmStatusChange(
                    context, ref, request, RequestStatus.cancelled)
                : null,
            child: const Text('Cancel Request'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: canComplete
                ? () => _confirmStatusChange(
                    context, ref, request, RequestStatus.completed)
                : null,
            child: const Text('Complete'),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmStatusChange(
    BuildContext context,
    WidgetRef ref,
    BloodRequestModel request,
    RequestStatus status,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(status == RequestStatus.cancelled
            ? 'Cancel request?'
            : 'Mark complete?'),
        content: Text(
          status == RequestStatus.cancelled
              ? 'This will close the request and stop donor matching.'
              : 'This will mark the request as completed.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final requestService = ref.read(requestServiceProvider);
      if (status == RequestStatus.cancelled) {
        await requestService.cancelRequest(request.requestId);
      } else {
        await requestService.completeRequest(request.requestId);
      }
      if (context.mounted) {
        _showMessage(
            context,
            status == RequestStatus.cancelled
                ? 'Request cancelled.'
                : 'Request completed.');
      }
    } catch (e) {
      if (context.mounted) _showMessage(context, 'Update failed: $e');
    }
  }

  Future<void> _confirmDonorAcceptance(
    BuildContext context,
    WidgetRef ref,
    BloodRequestModel request,
  ) async {
    final user = ref.read(userProvider);
    if (user == null) {
      _showMessage(context, 'Please sign in again and try once more.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept this request?'),
        content: const Text(
          'This will confirm that you will donate and will notify the other matched donors that this request is accepted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final accepted = await ref
          .read(requestServiceProvider)
          .donorAcceptRequest(request.requestId, user.userId);
      if (context.mounted) {
        _showMessage(context, accepted
          ? 'You accepted the request. It is now marked as accepted.'
            : 'This request was already closed by another donor.');
      }
    } catch (e) {
      if (context.mounted) {
        _showMessage(context, 'Could not accept request: $e');
      }
    }
  }

  Future<void> _openDirections(
      BuildContext context, BloodRequestModel request) async {
    final destination = request.latitude != null && request.longitude != null
        ? '${request.latitude},${request.longitude}'
        : Uri.encodeComponent(
            '${request.hospitalName}, ${request.address}, ${request.city}');
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$destination');

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      _showMessage(context, 'Could not open directions.');
    }
  }

  Future<void> _openChat(
    BuildContext context,
    WidgetRef ref,
    BloodRequestModel request,
    String? donorUserId,
  ) async {
    if (request.status == RequestStatus.completed) {
      _showMessage(context, 'Chat is disabled after request completion.');
      return;
    }

    final user = ref.read(userProvider);
    if (user == null || donorUserId == null || donorUserId.isEmpty) {
      _showMessage(context, 'Chat is unavailable for this donor.');
      return;
    }

    try {
      final chat = await ref
          .read(chatServiceProvider)
          .getOrCreateChat(user.userId, donorUserId, request.requestId);
      if (context.mounted) {
        context.push(AppRoutes.chatDetail, extra: chat.chatId);
      }
    } catch (e) {
      if (context.mounted) _showMessage(context, 'Could not open chat: $e');
    }
  }

  Future<void> _callDonor(BuildContext context, String? phone) async {
    if (phone == null || phone.isEmpty) {
      _showMessage(context, 'Phone number is not available.');
      return;
    }

    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri) && context.mounted) {
      _showMessage(context, 'Could not start a call.');
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
