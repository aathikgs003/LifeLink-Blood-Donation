import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_providers.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/donor_repository.dart';
import '../repositories/request_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/chat_repository.dart';
import '../repositories/payment_repository.dart';
import '../repositories/analytics_repository.dart';
import '../repositories/admin_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(firebaseAuthProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(firestoreProvider));
});

final donorRepositoryProvider = Provider<DonorRepository>((ref) {
  return DonorRepository(ref.watch(firestoreProvider));
});

final requestRepositoryProvider = Provider<RequestRepository>((ref) {
  return RequestRepository(ref.watch(firestoreProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(firestoreProvider));
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(firestoreProvider));
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.watch(firestoreProvider));
});

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(ref.watch(firestoreProvider));
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(firestoreProvider));
});
