import '../../models/notification/notification_model.dart';
import '../../repositories/notification_repository.dart';

class NotificationService {
  final NotificationRepository _notificationRepository;

  NotificationService(this._notificationRepository);

  Future<void> sendNotification(NotificationModel notification) async {
    await _notificationRepository.createNotification(notification);
  }

  Future<void> markAsRead(String notificationId) async {
    await _notificationRepository.markAsRead(notificationId);
  }

  Future<void> deleteNotification(String notificationId) async {
    await _notificationRepository.deleteNotification(notificationId);
  }

  Future<void> markAllAsRead(String userId) async {
    await _notificationRepository.markAllAsRead(userId);
  }

  Future<void> deleteAllByUser(String userId) async {
    await _notificationRepository.deleteAllByUser(userId);
  }

  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _notificationRepository.watchNotifications(userId);
  }

  Stream<int> getUnreadCount(String userId) {
    return _notificationRepository.watchUnreadCount(userId);
  }

  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    return await _notificationRepository.getNotificationsByUser(userId);
  }
}
