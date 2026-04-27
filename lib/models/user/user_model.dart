import '../enums.dart';

class UserModel {
  final String userId;
  final String email;
  final String? phone;
  final UserRole role;
  final bool isActive;
  final bool emailVerified;
  final bool profileCompleted;
  final DateTime lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? fcmToken;
  final Map<String, String> metadata;
  final SubscriptionStatus subscriptionStatus; // "free", "premium", "admin"
  final DateTime? deactivatedAt;
  final String? fullName; // Added for UI
  final String? profileImageUrl; // Added for UI

  String? get phoneNumber => phone;

  UserModel({
    required this.userId,
    required this.email,
    this.phone,
    required this.role,
    this.isActive = true,
    this.emailVerified = false,
    this.profileCompleted = false,
    required this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
    this.fcmToken,
    this.metadata = const {},
    this.subscriptionStatus = SubscriptionStatus.free,
    this.deactivatedAt,
    this.fullName,
    this.profileImageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'phone': phone,
      'role': role.name,
      'isActive': isActive,
      'emailVerified': emailVerified,
      'profileCompleted': profileCompleted,
      'lastLogin': lastLogin.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'fcmToken': fcmToken,
      'metadata': metadata,
      'subscriptionStatus': subscriptionStatus.name,
      'deactivatedAt': deactivatedAt?.toIso8601String(),
      'fullName': fullName,
      'profileImageUrl': profileImageUrl,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? json['phoneNumber'],
      role: UserRole.fromString(json['role'] ?? 'requester'),
      isActive: json['isActive'] ?? true,
      emailVerified: json['emailVerified'] ?? false,
      profileCompleted: json['profileCompleted'] ?? json['isProfileCompleted'] ?? false,
      lastLogin: json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : DateTime.now(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      fcmToken: json['fcmToken'],
      metadata: Map<String, String>.from(json['metadata'] ?? {}),
      subscriptionStatus: SubscriptionStatus.fromString(json['subscriptionStatus'] ?? 'free'),
      deactivatedAt: json['deactivatedAt'] != null ? DateTime.parse(json['deactivatedAt']) : null,
      fullName: json['fullName'],
      profileImageUrl: json['profileImageUrl'],
    );
  }

  UserModel copyWith({
    String? userId,
    String? email,
    String? phone,
    UserRole? role,
    bool? isActive,
    bool? emailVerified,
    bool? profileCompleted,
    DateTime? lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fcmToken,
    Map<String, String>? metadata,
    SubscriptionStatus? subscriptionStatus,
    DateTime? deactivatedAt,
    String? fullName,
    String? profileImageUrl,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      emailVerified: emailVerified ?? this.emailVerified,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fcmToken: fcmToken ?? this.fcmToken,
      metadata: metadata ?? this.metadata,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      deactivatedAt: deactivatedAt ?? this.deactivatedAt,
      fullName: fullName ?? this.fullName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
