import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../../models/donor/donor_model.dart';
import '../../../models/enums.dart';
import '../../../providers/service_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/user_provider.dart';
import '../../widgets/common_widgets.dart';

class DonationHistoryScreen extends ConsumerWidget {
  const DonationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Donation History')),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: LoadingListPlaceholder(itemCount: 5, itemHeight: 84),
        ),
      );
    }

    final donorRepository = ref.watch(donorRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Donation History')),
      body: StreamBuilder<DonorModel?>(
        stream: donorRepository.watchDonorByUserId(user.userId),
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

          final donor = snapshot.data;
          final history = donor?.donationHistory ?? const <Map<String, dynamic>>[];
          final sortedHistory = [...history]
            ..sort((a, b) {
              final aDate = _parseDate(_pickFirst(a, const ['date', 'donatedAt', 'createdAt']));
              final bDate = _parseDate(_pickFirst(b, const ['date', 'donatedAt', 'createdAt']));
              if (aDate == null && bDate == null) return 0;
              if (aDate == null) return 1;
              if (bDate == null) return -1;
              return bDate.compareTo(aDate);
            });

          final totalDonations = donor?.donationCount ?? sortedHistory.length;
          final totalUnits = _sumUnits(sortedHistory);
          final lastDonation = donor?.lastDonationDate ?? _latestHistoryDate(sortedHistory);
            final nextEligible = donor?.nextEligibleDonationDate ??
              lastDonation?.add(const Duration(days: 90));
          final averageRating = donor?.averageRating ?? _averageRating(sortedHistory);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _summaryGrid(
                totalDonations: totalDonations,
                totalUnits: totalUnits,
                averageRating: averageRating,
                nextEligible: nextEligible,
              ),
              const SizedBox(height: 20),
              if (sortedHistory.isEmpty)
                const Center(child: Text('No donation history available yet.'))
              else
                ...sortedHistory.asMap().entries.map((entry) {
                  final index = entry.key;
                  final donation = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _asString(
                                          _pickFirst(donation, const ['hospitalName', 'centerName', 'facilityName', 'location']),
                                          fallback: 'Donation Center',
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${_asString(_pickFirst(donation, const ['donationType', 'type', 'component']), fallback: 'Blood Donation')} - ${_asString(_pickFirst(donation, const ['units', 'unitCount']), fallback: '1')} Unit',
                                        style: const TextStyle(
                                          color: AppColors.textTertiaryDark,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _formatDate(_parseDate(_pickFirst(donation, const ['date', 'donatedAt', 'createdAt']))),
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      _resolvedStatus(donation),
                                      style: TextStyle(
                                        color: _statusColor(_resolvedStatus(donation)),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  _ratingText(_parseDouble(_pickFirst(donation, const ['rating', 'feedbackRating']))),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                if (_resolvedStatus(donation).toLowerCase() == 'accepted')
                                  IconButton(
                                    icon: const Icon(Icons.chat_bubble_outline),
                                    tooltip: 'Chat with requester',
                                    onPressed: () => _openChatFromHistory(
                                      context,
                                      ref,
                                      user.userId,
                                      donation,
                                    ),
                                  ),
                                TextButton(
                                  onPressed: () => _showReceipt(context, donation, index),
                                  child: const Text('View Receipt'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openChatFromHistory(
    BuildContext context,
    WidgetRef ref,
    String donorUserId,
    Map<String, dynamic> donation,
  ) async {
    final requestId = _pickFirst(donation, const ['requestId'])?.toString();
    if (requestId == null || requestId.isEmpty) {
      _showMessage(context, 'Request reference not found for this donation.');
      return;
    }

    try {
      final request = await ref.read(requestServiceProvider).getRequestById(requestId);
      if (request == null) {
        if (context.mounted) {
          _showMessage(context, 'Request details are unavailable for chat.');
        }
        return;
      }

      if (request.status == RequestStatus.completed) {
        if (context.mounted) {
          _showMessage(context, 'Chat is disabled after request completion.');
        }
        return;
      }

      final chat = await ref
          .read(chatServiceProvider)
          .getOrCreateChat(donorUserId, request.userId, request.requestId);

      if (context.mounted) {
        context.push(AppRoutes.chatDetail, extra: chat.chatId);
      }
    } catch (e) {
      if (context.mounted) {
        _showMessage(context, 'Could not open chat: $e');
      }
    }
  }

  Widget _summaryGrid({
    required int totalDonations,
    required int totalUnits,
    required double averageRating,
    required DateTime? nextEligible,
  }) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _summaryCard('Donations', '$totalDonations', Icons.volunteer_activism),
        _summaryCard('Units', '$totalUnits', Icons.bloodtype),
        _summaryCard(
          'Rating',
          averageRating == 0 ? '-' : averageRating.toStringAsFixed(1),
          Icons.star,
        ),
        _summaryCard(
          'Next Eligible',
          nextEligible == null ? 'N/A' : DateFormat('d MMM').format(nextEligible),
          Icons.event_available,
        ),
      ],
    );
  }

  Widget _summaryCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppColors.primaryRed),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textTertiaryDark,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReceipt(BuildContext context, Map<String, dynamic> entry, int index) {
    final receiptId = _asString(
      _pickFirst(entry, const ['receiptId', 'id', 'donationId']),
      fallback: 'DON-${index + 1}',
    );
    final units = _asString(_pickFirst(entry, const ['units', 'unitCount']), fallback: '1');
    final status = _resolvedStatus(entry);
    final donationType = _asString(
      _pickFirst(entry, const ['donationType', 'type', 'component']),
      fallback: 'Blood Donation',
    );
    final dateText = _formatDate(_parseDate(_pickFirst(entry, const ['date', 'donatedAt', 'createdAt'])));
    final centerName = _asString(
      _pickFirst(entry, const ['hospitalName', 'centerName', 'facilityName', 'location']),
      fallback: 'Donation Center',
    );
    final rating = _ratingText(_parseDouble(_pickFirst(entry, const ['rating', 'feedbackRating'])));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Donation Receipt'),
        content: Text(
          'Receipt #$receiptId\n'
          'Date: $dateText\n'
          'Location: $centerName\n'
          'Donation: $donationType - $units unit\n'
          'Status: $status\n'
          'Rating: $rating\n\n'
          'Thank you for saving lives.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
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

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int _sumUnits(List<Map<String, dynamic>> history) {
    var total = 0;
    for (final entry in history) {
      final raw = _pickFirst(entry, const ['units', 'unitCount']);
      final parsed = int.tryParse(_asString(raw, fallback: '0')) ?? 0;
      total += parsed;
    }
    return total;
  }

  static double _averageRating(List<Map<String, dynamic>> history) {
    final ratings = history
        .map((entry) => _parseDouble(_pickFirst(entry, const ['rating', 'feedbackRating'])))
        .whereType<double>()
        .toList();
    if (ratings.isEmpty) return 0;
    final total = ratings.reduce((a, b) => a + b);
    return total / ratings.length;
  }

  static DateTime? _latestHistoryDate(List<Map<String, dynamic>> history) {
    final dates = history
        .map((entry) => _parseDate(_pickFirst(entry, const ['date', 'donatedAt', 'createdAt'])))
        .whereType<DateTime>()
        .toList();
    if (dates.isEmpty) return null;
    dates.sort((a, b) => b.compareTo(a));
    return dates.first;
  }

  static String _formatDate(DateTime? value) {
    if (value == null) return 'Unknown date';
    return DateFormat('d MMM yyyy').format(value);
  }

  static Color _statusColor(String status) {
    final lower = status.toLowerCase();
    if (lower == 'completed') return AppColors.success;
    if (lower == 'accepted') return AppColors.primaryRed;
    if (lower == 'cancelled') return AppColors.error;
    return AppColors.textSecondaryDark;
  }

  static String _resolvedStatus(Map<String, dynamic> entry) {
    final rawStatus =
        _asString(_pickFirst(entry, const ['status']), fallback: 'Accepted');
    if (rawStatus.toLowerCase() != 'completed') {
      return rawStatus;
    }

    final completedAt = _pickFirst(entry, const ['completedAt']);
    if (completedAt == null || completedAt.toString().isEmpty) {
      return 'Accepted';
    }

    return rawStatus;
  }

  static String _ratingText(double? value) {
    if (value == null || value == 0) return '-';
    return value.toStringAsFixed(1);
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
