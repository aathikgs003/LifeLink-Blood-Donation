class NotificationModel {
  final String notificationId;
  final String recipientId;
  final String? requestId;
  final String type; // emergencyAlert, requestUpdate, reminder, campaign, etc.
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final String status; // sent, read, deleted
  final DateTime sentAt;
  final DateTime? readAt;
  final DateTime? deletedAt;
  final bool isRead;
  final String priority; // high, normal, low
  final DateTime expiresAt;

  NotificationModel({
    required this.notificationId,
    required this.recipientId,
    this.requestId,
    required this.type,
    required this.title,
    required this.body,
    this.data = const {},
    this.status = 'sent',
    required this.sentAt,
    this.readAt,
    this.deletedAt,
    this.isRead = false,
    this.priority = 'normal',
    required this.expiresAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'recipientId': recipientId,
      'requestId': requestId,
      'type': type,
      'title': title,
      'body': body,
      'data': data,
      'status': status,
      'sentAt': sentAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'isRead': isRead,
      'priority': priority,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notificationId'] ?? json['id'] ?? '',
      recipientId: json['recipientId'] ?? json['userId'] ?? '',
      requestId: json['requestId'],
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      status: json['status'] ?? 'sent',
      sentAt: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'])
          : DateTime.now(),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      deletedAt:
          json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
      isRead: json['isRead'] ?? false,
      priority: json['priority'] ?? 'normal',
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : DateTime.now().add(const Duration(days: 30)),
    );
  }

  NotificationModel copyWith({
    String? notificationId,
    String? recipientId,
    String? requestId,
    String? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    String? status,
    DateTime? sentAt,
    DateTime? readAt,
    DateTime? deletedAt,
    bool? isRead,
    String? priority,
    DateTime? expiresAt,
  }) {
    return NotificationModel(
      notificationId: notificationId ?? this.notificationId,
      recipientId: recipientId ?? this.recipientId,
      requestId: requestId ?? this.requestId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
      deletedAt: deletedAt ?? this.deletedAt,
      isRead: isRead ?? this.isRead,
      priority: priority ?? this.priority,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
