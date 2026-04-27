class PaymentModel {
  final String paymentId;
  final String userId;
  final String? orderId;
  final String? razorpayPaymentId;
  final String? razorpayOrderId;
  final String? razorpaySignature;
  final double amount;
  final String currency;
  final String type; // donation, subscription, tip
  final String status; // pending, success, failed, refunded
  final String? donorId;
  final String? requestId;
  final String? description;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? failureReason;

  PaymentModel({
    required this.paymentId,
    required this.userId,
    this.orderId,
    this.razorpayPaymentId,
    this.razorpayOrderId,
    this.razorpaySignature,
    required this.amount,
    this.currency = 'INR',
    required this.type,
    this.status = 'pending',
    this.donorId,
    this.requestId,
    this.description,
    this.metadata = const {},
    required this.createdAt,
    this.completedAt,
    this.failureReason,
  });

  Map<String, dynamic> toJson() {
    return {
      'paymentId': paymentId,
      'userId': userId,
      'orderId': orderId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpayOrderId': razorpayOrderId,
      'razorpaySignature': razorpaySignature,
      'amount': amount,
      'currency': currency,
      'type': type,
      'status': status,
      'donorId': donorId,
      'requestId': requestId,
      'description': description,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'failureReason': failureReason,
    };
  }

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      paymentId: json['paymentId'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      orderId: json['orderId'],
      razorpayPaymentId: json['razorpayPaymentId'],
      razorpayOrderId: json['razorpayOrderId'],
      razorpaySignature: json['razorpaySignature'],
      amount: json['amount']?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'INR',
      type: json['type'] ?? 'donation',
      status: json['status'] ?? 'pending',
      donorId: json['donorId'],
      requestId: json['requestId'],
      description: json['description'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      failureReason: json['failureReason'],
    );
  }

  PaymentModel copyWith({
    String? paymentId,
    String? userId,
    String? orderId,
    String? razorpayPaymentId,
    String? razorpayOrderId,
    String? razorpaySignature,
    double? amount,
    String? currency,
    String? type,
    String? status,
    String? donorId,
    String? requestId,
    String? description,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? completedAt,
    String? failureReason,
  }) {
    return PaymentModel(
      paymentId: paymentId ?? this.paymentId,
      userId: userId ?? this.userId,
      orderId: orderId ?? this.orderId,
      razorpayPaymentId: razorpayPaymentId ?? this.razorpayPaymentId,
      razorpayOrderId: razorpayOrderId ?? this.razorpayOrderId,
      razorpaySignature: razorpaySignature ?? this.razorpaySignature,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      status: status ?? this.status,
      donorId: donorId ?? this.donorId,
      requestId: requestId ?? this.requestId,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      failureReason: failureReason ?? this.failureReason,
    );
  }
}
