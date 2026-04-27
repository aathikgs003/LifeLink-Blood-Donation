import '../enums.dart';

class DonorModel {
  final String donorId;
  final String userId;
  final String name;
  final String email;
  final String? phone;
  final BloodGroup bloodGroup;
  final RhFactor rhFactor; // "positive", "negative"
  final String city;
  final String? district;
  final String? state;
  final String? address;
  final double? latitude;
  final double? longitude;
  final bool isAvailable;
  final DateTime? lastDonationDate;
  final int donationCount;
  final DateTime? nextEligibleDonationDate;
  final int age;
  final double weight;
  final List<String> healthConditions;
  final List<String> allergies;
  final List<String> medications;
  final bool verified;
  final DateTime? verificationDate;
  final int ratingsCount;
  final double averageRating;
  final String? profileImageUrl;
  final ContactMethod preferredContactMethod; // "call", "sms", "push"
  final Map<String, String> emergencyContact; // name, relationship, phone
  final List<Map<String, dynamic>> donationHistory;
  final Map<String, bool> notificationPreferences;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deactivatedAt;

  DonorModel({
    required this.donorId,
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    required this.bloodGroup,
    required this.rhFactor,
    required this.city,
    this.district,
    this.state,
    this.address,
    this.latitude,
    this.longitude,
    this.isAvailable = false,
    this.lastDonationDate,
    this.donationCount = 0,
    this.nextEligibleDonationDate,
    required this.age,
    required this.weight,
    this.healthConditions = const [],
    this.allergies = const [],
    this.medications = const [],
    this.verified = false,
    this.verificationDate,
    this.ratingsCount = 0,
    this.averageRating = 0.0,
    this.profileImageUrl,
    this.preferredContactMethod = ContactMethod.push,
    this.emergencyContact = const {},
    this.donationHistory = const [],
    this.notificationPreferences = const {
      'emergencyAlerts': true,
      'campaignNotifications': true,
      'reminderNotifications': true,
    },
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.deactivatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'donorId': donorId,
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'bloodGroup': bloodGroup.name,
      'rhFactor': rhFactor.name,
      'city': city,
      'district': district,
      'state': state,
      'address': address,
      'location': {
        'latitude': latitude,
        'longitude': longitude,
      },
      'isAvailable': isAvailable,
      'lastDonationDate': lastDonationDate?.toIso8601String(),
      'donationCount': donationCount,
      'nextEligibleDonationDate': nextEligibleDonationDate?.toIso8601String(),
      'age': age,
      'weight': weight,
      'healthConditions': healthConditions,
      'allergies': allergies,
      'medications': medications,
      'verified': verified,
      'verificationDate': verificationDate?.toIso8601String(),
      'ratingsCount': ratingsCount,
      'averageRating': averageRating,
      'profileImageUrl': profileImageUrl,
      'preferredContactMethod': preferredContactMethod.name,
      'emergencyContact': emergencyContact,
      'donationHistory': donationHistory,
      'notificationPreferences': notificationPreferences,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deactivatedAt': deactivatedAt?.toIso8601String(),
    };
  }

  factory DonorModel.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>?;
    return DonorModel(
      donorId: json['donorId'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      bloodGroup: BloodGroup.fromString(json['bloodGroup'] ?? 'oPositive'),
      rhFactor: RhFactor.fromString(json['rhFactor'] ?? 'positive'),
      city: json['city'] ?? '',
      district: json['district'],
      state: json['state'],
      address: json['address'],
      latitude: location?['latitude']?.toDouble(),
      longitude: location?['longitude']?.toDouble(),
      isAvailable: json['isAvailable'] ?? false,
      lastDonationDate: json['lastDonationDate'] != null ? DateTime.parse(json['lastDonationDate']) : null,
      donationCount: json['donationCount'] ?? 0,
      nextEligibleDonationDate: json['nextEligibleDonationDate'] != null ? DateTime.parse(json['nextEligibleDonationDate']) : null,
      age: json['age'] ?? 18,
      weight: json['weight']?.toDouble() ?? 50.0,
      healthConditions: List<String>.from(json['healthConditions'] ?? []),
      allergies: List<String>.from(json['allergies'] ?? []),
      medications: List<String>.from(json['medications'] ?? []),
      verified: json['verified'] ?? false,
      verificationDate: json['verificationDate'] != null ? DateTime.parse(json['verificationDate']) : null,
      ratingsCount: json['ratingsCount'] ?? 0,
      averageRating: json['averageRating']?.toDouble() ?? 0.0,
      profileImageUrl: json['profileImageUrl'],
      preferredContactMethod: ContactMethod.fromString(json['preferredContactMethod'] ?? 'push'),
      emergencyContact: Map<String, String>.from(json['emergencyContact'] ?? {}),
      donationHistory: List<Map<String, dynamic>>.from(json['donationHistory'] ?? []),
      notificationPreferences: Map<String, bool>.from(json['notificationPreferences'] ?? {}),
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      deactivatedAt: json['deactivatedAt'] != null ? DateTime.parse(json['deactivatedAt']) : null,
    );
  }

  DonorModel copyWith({
    String? donorId,
    String? userId,
    String? name,
    String? email,
    String? phone,
    BloodGroup? bloodGroup,
    RhFactor? rhFactor,
    String? city,
    String? district,
    String? state,
    String? address,
    double? latitude,
    double? longitude,
    bool? isAvailable,
    DateTime? lastDonationDate,
    int? donationCount,
    DateTime? nextEligibleDonationDate,
    int? age,
    double? weight,
    List<String>? healthConditions,
    List<String>? allergies,
    List<String>? medications,
    bool? verified,
    DateTime? verificationDate,
    int? ratingsCount,
    double? averageRating,
    String? profileImageUrl,
    ContactMethod? preferredContactMethod,
    Map<String, String>? emergencyContact,
    List<Map<String, dynamic>>? donationHistory,
    Map<String, bool>? notificationPreferences,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deactivatedAt,
  }) {
    return DonorModel(
      donorId: donorId ?? this.donorId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      rhFactor: rhFactor ?? this.rhFactor,
      city: city ?? this.city,
      district: district ?? this.district,
      state: state ?? this.state,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isAvailable: isAvailable ?? this.isAvailable,
      lastDonationDate: lastDonationDate ?? this.lastDonationDate,
      donationCount: donationCount ?? this.donationCount,
      nextEligibleDonationDate: nextEligibleDonationDate ?? this.nextEligibleDonationDate,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      healthConditions: healthConditions ?? this.healthConditions,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      verified: verified ?? this.verified,
      verificationDate: verificationDate ?? this.verificationDate,
      ratingsCount: ratingsCount ?? this.ratingsCount,
      averageRating: averageRating ?? this.averageRating,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      preferredContactMethod: preferredContactMethod ?? this.preferredContactMethod,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      donationHistory: donationHistory ?? this.donationHistory,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deactivatedAt: deactivatedAt ?? this.deactivatedAt,
    );
  }
}
