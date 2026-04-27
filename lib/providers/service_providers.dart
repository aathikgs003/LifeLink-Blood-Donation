import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_providers.dart';
import 'repository_providers.dart';
import '../services/auth/auth_service.dart';
import '../services/donor/donor_service.dart';
import '../services/request/blood_request_service.dart';
import '../services/notification/notification_service.dart';
import '../services/notification/push_notification_service.dart';
import '../services/chat/chat_service.dart';
import '../services/payment/payment_service.dart';
import '../services/analytics/analytics_service.dart';
import '../services/admin/admin_service.dart';
import '../services/user/user_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(authRepositoryProvider),
    ref.watch(userRepositoryProvider),
  );
});

final donorServiceProvider = Provider<DonorService>((ref) {
  return DonorService(ref.watch(donorRepositoryProvider));
});

final requestServiceProvider = Provider<RequestService>((ref) {
  return RequestService(
    ref.watch(requestRepositoryProvider),
    ref.watch(donorRepositoryProvider),
    ref.watch(notificationRepositoryProvider),
  );
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.watch(notificationRepositoryProvider));
});

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(ref.watch(chatRepositoryProvider));
});

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(ref.watch(paymentRepositoryProvider));
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(ref.watch(analyticsRepositoryProvider));
});

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService(ref.watch(adminRepositoryProvider));
});

final userServiceProvider = Provider<UserService>((ref) {
  return UserService(ref.watch(userRepositoryProvider));
});

final flutterLocalNotificationsProvider =
    Provider<FlutterLocalNotificationsPlugin>((ref) {
  return FlutterLocalNotificationsPlugin();
});

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(
    ref.watch(firebaseMessagingProvider),
    ref.watch(flutterLocalNotificationsProvider),
    ref.watch(firebaseAuthProvider),
    ref.watch(userRepositoryProvider),
    ref.watch(donorRepositoryProvider),
  );
});
