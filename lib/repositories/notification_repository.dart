import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepository(this._firestore);

  CollectionReference get _notifications => _firestore.collection('notifications');

  Future<void> createNotification(NotificationModel notification) async {
    await _notifications.doc(notification.notificationId).set(notification.toJson());
  }

  Future<void> markAsRead(String notificationId) async {
    await _notifications.doc(notificationId).update({
      'isRead': true,
      'readAt': DateTime.now().toIso8601String(),
      'status': 'read',
    });
  }

  Future<void> deleteNotification(String notificationId) async {
    await _notifications.doc(notificationId).update({
      'status': 'deleted',
      'deletedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _notifications
        .where('recipientId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .where('status', isNotEqualTo: 'deleted')
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': DateTime.now().toIso8601String(),
        'status': 'read',
      });
    }
    await batch.commit();
  }

  Future<void> deleteAllByUser(String userId) async {
    final snapshot = await _notifications
        .where('recipientId', isEqualTo: userId)
        .where('status', isNotEqualTo: 'deleted')
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'status': 'deleted',
        'deletedAt': DateTime.now().toIso8601String(),
      });
    }
    await batch.commit();
  }

  Future<void> hideRequestNotificationsForOtherDonors({
    required String requestId,
    required String acceptedDonorUserId,
  }) async {
    final snapshot = await _notifications
        .where('requestId', isEqualTo: requestId)
        .where('type', isEqualTo: 'bloodRequest')
        .get();

    final batch = _firestore.batch();
    final now = DateTime.now().toIso8601String();

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final recipientId = data['recipientId']?.toString();
      final isDeleted = data['status']?.toString() == 'deleted';
      if (isDeleted || recipientId == acceptedDonorUserId) {
        continue;
      }

      batch.update(doc.reference, {
        'status': 'deleted',
        'deletedAt': now,
        'data.hiddenReason': 'accepted_by_other_donor',
      });
    }

    await batch.commit();
  }

  Stream<List<NotificationModel>> watchNotifications(String userId) {
    return _notifications
        .where('recipientId', isEqualTo: userId)
        .where('status', isNotEqualTo: 'deleted')
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Stream<int> watchUnreadCount(String userId) {
    return _notifications
        .where('recipientId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .where('status', isNotEqualTo: 'deleted')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<List<NotificationModel>> getNotificationsByUser(String userId) async {
    final snapshot = await _notifications
        .where('recipientId', isEqualTo: userId)
        .where('status', isNotEqualTo: 'deleted')
        .orderBy('sentAt', descending: true)
        .get();
        
    return snapshot.docs
        .map((doc) => NotificationModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }
}
