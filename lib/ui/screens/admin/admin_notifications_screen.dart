import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../models/notification/notification_model.dart';
import '../../../providers/service_providers.dart';
import '../../../providers/user_provider.dart';
import '../../widgets/common_widgets.dart';

class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState
    extends ConsumerState<AdminNotificationsScreen> {
  bool _showUnreadOnly = false;
  bool _isProcessing = false;
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Notifications'),
        actions: [
          IconButton(
            tooltip: 'Mark all as read',
            icon: const Icon(Icons.done_all),
            onPressed: user == null || _isProcessing
                ? null
                : () => _markAllAsRead(user.userId),
          ),
          IconButton(
            tooltip: 'Clear all',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: user == null || _isProcessing
                ? null
                : () => _deleteAllNotifications(user.userId),
          ),
        ],
      ),
      body: user == null
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: LoadingListPlaceholder(itemCount: 6, itemHeight: 76),
            )
          : StreamBuilder<List<NotificationModel>>(
              stream: ref
                  .watch(notificationServiceProvider)
                  .getNotifications(user.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: LoadingListPlaceholder(itemCount: 6, itemHeight: 76),
                  );
                }

                final allNotifications = snapshot.data ?? [];
                final notifications = allNotifications
                    .where(_isAllowedNotification)
                    .where((n) =>
                        !_showUnreadOnly ||
                        (_showUnreadOnly && !n.isRead))
                    .where(_matchesCategory)
                    .toList();

                if (notifications.isEmpty) {
                  return const Center(child: Text('No admin notifications yet'));
                }

                return Column(
                  children: [
                    _buildToolbar(notifications),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          return ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 6),
                            leading: CircleAvatar(
                              backgroundColor: notification.isRead
                                  ? Colors.grey.shade200
                                  : AppColors.primaryRed.withAlpha(20),
                              child: Icon(
                                _iconForType(notification.type),
                                color: notification.isRead
                                    ? Colors.grey
                                    : AppColors.primaryRed,
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
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text(notification.body),
                                const SizedBox(height: 4),
                                Text(
                                  _metaText(notification),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textTertiaryDark,
                                  ),
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'read') {
                                  _markAsRead(notification.notificationId);
                                } else if (value == 'delete') {
                                  _deleteOne(notification.notificationId);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'read',
                                  child: Text('Mark as read'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                            onTap: () =>
                                _markAsRead(notification.notificationId),
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

  Widget _buildToolbar(List<NotificationModel> notifications) {
    final unreadCount = notifications.where((n) => !n.isRead).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$unreadCount unread',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondaryDark,
                ),
              ),
              const Spacer(),
              FilterChip(
                label: const Text('Unread only'),
                selected: _showUnreadOnly,
                onSelected: (v) => setState(() => _showUnreadOnly = v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _categoryChip('all', 'All'),
              _categoryChip('emergency', 'Emergency'),
              _categoryChip('verification', 'Verification'),
              _categoryChip('system', 'System'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String category, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedCategory == category,
      onSelected: (selected) {
        if (!selected) return;
        setState(() => _selectedCategory = category);
      },
    );
  }

  bool _isAllowedNotification(NotificationModel notification) {
    if (notification.type == 'payment') return false;
    return true;
  }

  bool _matchesCategory(NotificationModel notification) {
    if (_selectedCategory == 'all') return true;
    if (_selectedCategory == 'emergency') {
      return notification.type == 'emergency' ||
          notification.type == 'emergencyAlert';
    }
    if (_selectedCategory == 'verification') {
      return notification.type == 'verification';
    }
    if (_selectedCategory == 'system') {
      return notification.type != 'emergency' &&
          notification.type != 'emergencyAlert' &&
          notification.type != 'verification';
    }
    return true;
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'emergency':
      case 'emergencyAlert':
        return Icons.emergency;
      case 'verification':
        return Icons.verified_user;
      case 'payment':
        return Icons.payment;
      case 'requestUpdate':
        return Icons.bloodtype;
      case 'campaign':
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }

  String _metaText(NotificationModel notification) {
    final date =
        '${notification.sentAt.day}/${notification.sentAt.month}/${notification.sentAt.year}';
    final priority = notification.priority.toUpperCase();
    return '$priority priority • $date';
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await ref.read(notificationServiceProvider).markAsRead(notificationId);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not mark notification as read: $e');
    }
  }

  Future<void> _deleteOne(String notificationId) async {
    try {
      await ref.read(notificationServiceProvider).deleteNotification(notificationId);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not delete notification: $e');
    }
  }

  Future<void> _markAllAsRead(String userId) async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(notificationServiceProvider).markAllAsRead(userId);
      if (mounted) _showMessage('All notifications marked as read.');
    } catch (e) {
      if (mounted) _showMessage('Could not mark all as read: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _deleteAllNotifications(String userId) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Clear all notifications?'),
            content: const Text(
                'This will hide all your notifications from the admin list.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Clear All'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) return;

    setState(() => _isProcessing = true);
    try {
      await ref.read(notificationServiceProvider).deleteAllByUser(userId);
      if (mounted) _showMessage('All notifications cleared.');
    } catch (e) {
      if (mounted) _showMessage('Could not clear notifications: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
