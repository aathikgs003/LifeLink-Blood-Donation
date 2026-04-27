import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../../models/notification/notification_model.dart';
import '../../../providers/service_providers.dart';
import '../../../providers/user_provider.dart';
import '../../widgets/common_widgets.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  String _selectedCategory = 'all';
  bool _showUnreadOnly = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: LoadingListPlaceholder(itemCount: 6, itemHeight: 76),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'readAll') {
                _markAllAsRead(user.userId);
              } else if (value == 'clearAll') {
                _confirmClearAll(user.userId);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'readAll',
                child: Text('Mark all as read'),
              ),
              PopupMenuItem(
                value: 'clearAll',
                child: Text('Clear all'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: ref.watch(notificationServiceProvider).getNotifications(user.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: LoadingListPlaceholder(itemCount: 6, itemHeight: 76),
            );
          }

          final notifications = snapshot.data ?? [];
          final filtered = notifications.where(_matchesFilters).toList();

          return Column(
            children: [
              _buildFilters(),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No notifications for selected filters'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final notification = filtered[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 6),
                            leading: CircleAvatar(
                              backgroundColor: _iconColor(notification).withAlpha(26),
                              child: Icon(
                                _getIcon(notification.type),
                                color: _iconColor(notification),
                              ),
                            ),
                            title: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(notification.body),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'read') {
                                  _markAsRead(notification.notificationId);
                                } else if (value == 'delete') {
                                  _delete(notification.notificationId);
                                }
                              },
                              itemBuilder: (context) => [
                                if (!notification.isRead)
                                  const PopupMenuItem(
                                    value: 'read',
                                    child: Text('Mark as read'),
                                  ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                            onTap: () {
                              if (!notification.isRead) {
                                _markAsRead(notification.notificationId);
                              }

                              final requestId = notification.requestId;
                              if (requestId != null && requestId.isNotEmpty) {
                                context.push('${AppRoutes.requestDetail}?id=$requestId');
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _categoryChip('all', 'All'),
              _categoryChip('emergency', 'Emergency'),
              _categoryChip('request', 'Request'),
              _categoryChip('verification', 'Verification'),
              _categoryChip('system', 'System'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilterChip(
                selected: _showUnreadOnly,
                label: const Text('Unread only'),
                onSelected: (selected) {
                  setState(() => _showUnreadOnly = selected);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String key, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedCategory == key,
      onSelected: (_) {
        setState(() => _selectedCategory = key);
      },
    );
  }

  bool _matchesFilters(NotificationModel n) {
    if (_showUnreadOnly && n.isRead) return false;
    if (_selectedCategory == 'all') return true;

    final normalizedType = n.type.toLowerCase();
    switch (_selectedCategory) {
      case 'emergency':
        return normalizedType.contains('emergency');
      case 'request':
        return normalizedType.contains('request');
      case 'verification':
        return normalizedType.contains('verification');
      case 'system':
        return !(normalizedType.contains('emergency') ||
            normalizedType.contains('request') ||
            normalizedType.contains('verification'));
      default:
        return true;
    }
  }

  Color _iconColor(NotificationModel n) {
    final type = n.type.toLowerCase();
    if (type.contains('emergency')) return AppColors.error;
    if (type.contains('verification')) return AppColors.info;
    if (type.contains('request')) return AppColors.warning;
    return AppColors.primaryRed;
  }

  IconData _getIcon(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('emergency')) return Icons.emergency;
    if (normalized.contains('verification')) return Icons.verified_user;
    if (normalized.contains('request')) return Icons.bloodtype;
    if (normalized.contains('payment')) return Icons.payment;
    return Icons.notifications;
  }

  Future<void> _markAsRead(String notificationId) async {
    await ref.read(notificationServiceProvider).markAsRead(notificationId);
  }

  Future<void> _delete(String notificationId) async {
    await ref.read(notificationServiceProvider).deleteNotification(notificationId);
  }

  Future<void> _markAllAsRead(String userId) async {
    await ref.read(notificationServiceProvider).markAllAsRead(userId);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('All marked as read.')));
    }
  }

  Future<void> _confirmClearAll(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text('This will hide all notifications from your feed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear')),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(notificationServiceProvider).deleteAllByUser(userId);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Notifications cleared.')));
    }
  }
}
