import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../../../providers/user_provider.dart';

class DonorBloodDrivesScreen extends ConsumerWidget {
  const DonorBloodDrivesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Drives'),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('blood_drives')
                  .orderBy('eventDate', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];
                final drives = docs.where((doc) {
                  final data = doc.data();
                  final isActive = data['isActive'] ?? true;
                  final city = (data['city'] ?? '').toString().toLowerCase();
                  final userCity = (user.metadata['city'] ?? '').toLowerCase();
                  final targetRole = (data['targetRole'] ?? 'all').toString();

                  final matchesRole = targetRole == 'all' || targetRole == 'donor';
                  final matchesCity = city.isEmpty || userCity.isEmpty || city == userCity;
                  return isActive == true && matchesRole && matchesCity;
                }).toList();

                if (drives.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {},
                    child: ListView(
                      children: const [
                        SizedBox(height: 180),
                        Center(
                          child: Text('No blood drives available right now.'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: drives.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = drives[index].data();
                    final title = (data['title'] ?? 'Blood Drive').toString();
                    final venue = (data['venue'] ?? data['location'] ?? 'Venue').toString();
                    final city = (data['city'] ?? 'City').toString();
                    final description = (data['description'] ?? 'Help save lives by donating blood.').toString();
                    final dateValue = data['eventDate'];
                    final startDate = dateValue is Timestamp
                        ? dateValue.toDate()
                        : dateValue is String
                            ? DateTime.tryParse(dateValue)
                            : null;
                    final dateText = startDate == null
                        ? 'Date not set'
                        : DateFormat('EEE, d MMM yyyy').format(startDate);

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryRed.withAlpha(25),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.favorite,
                                    color: AppColors.primaryRed,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text('$venue • $city'),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  dateText,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textTertiaryDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(description),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _infoChip(Icons.schedule, _formatTimeRange(data)),
                                _infoChip(Icons.people_alt_outlined,
                                    (data['audience'] ?? 'All donors').toString()),
                                _infoChip(Icons.location_on_outlined, city),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () => _showInterestDialog(
                                  context,
                                  title,
                                  venue,
                                  city,
                                ),
                                icon: const Icon(Icons.thumb_up_outlined),
                                label: const Text('Show Interest'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Chip(
      avatar: Icon(icon, size: 16, color: AppColors.primaryRed),
      label: Text(text),
      backgroundColor: AppColors.primaryRed.withAlpha(20),
    );
  }

  String _formatTimeRange(Map<String, dynamic> data) {
    final start = data['startTime'];
    final end = data['endTime'];
    if (start == null && end == null) return 'Time pending';
    return '${start ?? 'Start'} - ${end ?? 'End'}';
  }

  void _showInterestDialog(
    BuildContext context,
    String title,
    String venue,
    String city,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(
          'You have shown interest in:\n$venue\n$city\n\nThis will help you keep track of upcoming donation events. Contact organizers directly when available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
