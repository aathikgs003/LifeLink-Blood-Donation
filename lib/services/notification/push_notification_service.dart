import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../config/routes.dart';
import '../../repositories/donor_repository.dart';
import '../../repositories/user_repository.dart';

class PushNotificationService {
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final FirebaseAuth _auth;
  final UserRepository _userRepository;
  final DonorRepository _donorRepository;

  bool _initialized = false;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _openedAppMessageSubscription;

  PushNotificationService(
    this._messaging,
    this._localNotifications,
    this._auth,
    this._userRepository,
    this._donorRepository,
  );

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _initializeLocalNotifications();
    await _syncCurrentUserToken();

    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) {
      _syncTokenForCurrentUser(token);
    });

    _authSubscription = _auth.authStateChanges().listen((user) async {
      if (user == null) {
        return;
      }
      await _syncCurrentUserToken();
    });

    _foregroundMessageSubscription =
        FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    _openedAppMessageSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _openRequestFromData(message.data);
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _openRequestFromData(initialMessage.data);
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _authSubscription?.cancel();
    await _foregroundMessageSubscription?.cancel();
    await _openedAppMessageSubscription?.cancel();
  }

  Future<void> _initializeLocalNotifications() async {
    const androidChannel = AndroidNotificationChannel(
      'emergency_blood_requests',
      'Emergency Blood Requests',
      description: 'Urgent blood request notifications',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        _openFromPayload(response.payload);
      },
    );
  }

  void _openFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      return;
    }

    final parsed = Uri.splitQueryString(payload);
    _openRequestFromData(parsed);
  }

  void _openRequestFromData(Map<String, dynamic> data) {
    final requestId = data['requestId']?.toString();
    if (requestId == null || requestId.isEmpty) {
      return;
    }

    AppRoutes.router.go('${AppRoutes.requestDetail}?id=$requestId');
  }

  Future<void> _syncCurrentUserToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        return;
      }

      await _syncTokenForCurrentUser(token);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('FCM token sync skipped: $error');
      }
    }
  }

  Future<void> _syncTokenForCurrentUser(String token) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      return;
    }

    try {
      await _userRepository.updateFCMToken(firebaseUser.uid, token);
      await _donorRepository.updateFcmTokenByUserId(firebaseUser.uid, token);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('FCM token persistence failed: $error');
      }
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) {
      return;
    }

    final title = notification.title ?? 'LifeLink';
    final body = notification.body ?? '';
    final payloadData = message.data.map(
      (key, value) => MapEntry(key, value.toString()),
    );
    final payload = Uri(queryParameters: payloadData).query;

    const androidDetails = AndroidNotificationDetails(
      'emergency_blood_requests',
      'Emergency Blood Requests',
      channelDescription: 'Urgent blood request notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    final notificationId = message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;

    await _localNotifications.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: payload,
    );

    if (kDebugMode) {
      debugPrint('Foreground push: $title');
    }
  }
}
