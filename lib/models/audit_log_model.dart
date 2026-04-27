class AuditLogModel {
  final String logId;
  final String userId;
  final String action;
  final String resource; // Collection name
  final String resourceId;
  final DateTime timestamp;
  final Map<String, dynamic> changes; // Before/after values
  final String? ipAddress;
  final String status; // success, failure
  final String? errorMessage;

  AuditLogModel({
    required this.logId,
    required this.userId,
    required this.action,
    required this.resource,
    required this.resourceId,
    required this.timestamp,
    this.changes = const {},
    this.ipAddress,
    this.status = 'success',
    this.errorMessage,
  });

  Map<String, dynamic> toJson() {
    return {
      'logId': logId,
      'userId': userId,
      'action': action,
      'resource': resource,
      'resourceId': resourceId,
      'timestamp': timestamp.toIso8601String(),
      'changes': changes,
      'ipAddress': ipAddress,
      'status': status,
      'errorMessage': errorMessage,
    };
  }

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      logId: json['logId'] ?? '',
      userId: json['userId'] ?? '',
      action: json['action'] ?? '',
      resource: json['resource'] ?? '',
      resourceId: json['resourceId'] ?? '',
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
      changes: Map<String, dynamic>.from(json['changes'] ?? {}),
      ipAddress: json['ipAddress'],
      status: json['status'] ?? 'success',
      errorMessage: json['errorMessage'],
    );
  }
}
