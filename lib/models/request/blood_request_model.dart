import '../enums.dart';

class BloodRequestModel {
  final String requestId;
  final String userId;
  final String patientName;
  final int patientAge;
  final BloodGroup bloodGroupRequired;
  final int unitsRequired;
  final int unitsCollected;
  final String hospitalName;
  final String hospitalPhone;
  final String city;
  final String? district;
  final String? state;
  final String address;
  final double? latitude;
  final double? longitude;
  final UrgencyLevel urgencyLevel;
  final String? urgencyDescription;
  final String contactNumber;
  final String? alternateContactNumber;
  final String? medicalDetails; // Encrypted
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime expiresAt;
  final DateTime? completedAt;
  final List<Map<String, dynamic>> matchedDonors;
  final List<Map<String, dynamic>> acceptedDonors;
  final DateTime? notificationBroadcastAt;
  final int broadcastRadius; // km
  final bool isActive;
  final Map<String, dynamic> metadata;

  BloodRequestModel({
    required this.requestId,
    required this.userId,
    required this.patientName,
    required this.patientAge,
    required this.bloodGroupRequired,
    required this.unitsRequired,
    this.unitsCollected = 0,
    required this.hospitalName,
    required this.hospitalPhone,
    required this.city,
    this.district,
    this.state,
    required this.address,
    this.latitude,
    this.longitude,
    required this.urgencyLevel,
    this.urgencyDescription,
    required this.contactNumber,
    this.alternateContactNumber,
    this.medicalDetails,
    this.status = RequestStatus.pending,
    required this.createdAt,
    required this.updatedAt,
    required this.expiresAt,
    this.completedAt,
    this.matchedDonors = const [],
    this.acceptedDonors = const [],
    this.notificationBroadcastAt,
    this.broadcastRadius = 50,
    this.isActive = true,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'userId': userId,
      'patientName': patientName,
      'patientAge': patientAge,
      'bloodGroupRequired': bloodGroupRequired.name,
      'unitsRequired': unitsRequired,
      'unitsCollected': unitsCollected,
      'hospitalName': hospitalName,
      'hospitalPhone': hospitalPhone,
      'city': city,
      'district': district,
      'state': state,
      'address': address,
      'location': {
        'latitude': latitude,
        'longitude': longitude,
      },
      'urgencyLevel': urgencyLevel.name,
      'urgencyDescription': urgencyDescription,
      'contactNumber': contactNumber,
      'alternateContactNumber': alternateContactNumber,
      'medicalDetails': medicalDetails,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'matchedDonors': matchedDonors,
      'acceptedDonors': acceptedDonors,
      'notificationBroadcastAt': notificationBroadcastAt?.toIso8601String(),
      'broadcastRadius': broadcastRadius,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  factory BloodRequestModel.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>?;
    return BloodRequestModel(
      requestId: json['requestId'] ?? '',
      userId: json['userId'] ?? '',
      patientName: json['patientName'] ?? '',
      patientAge: json['patientAge'] ?? 0,
      bloodGroupRequired: BloodGroup.fromString(json['bloodGroupRequired'] ?? 'oPositive'),
      unitsRequired: json['unitsRequired'] ?? 0,
      unitsCollected: json['unitsCollected'] ?? 0,
      hospitalName: json['hospitalName'] ?? '',
      hospitalPhone: json['hospitalPhone'] ?? '',
      city: json['city'] ?? '',
      district: json['district'],
      state: json['state'],
      address: json['address'] ?? '',
      latitude: location?['latitude']?.toDouble(),
      longitude: location?['longitude']?.toDouble(),
      urgencyLevel: UrgencyLevel.fromString(json['urgencyLevel'] ?? 'normal'),
      urgencyDescription: json['urgencyDescription'],
      contactNumber: json['contactNumber'] ?? '',
      alternateContactNumber: json['alternateContactNumber'],
      medicalDetails: json['medicalDetails'],
      status: RequestStatus.fromString(json['status'] ?? 'pending'),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : DateTime.now().add(const Duration(days: 7)),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      matchedDonors: List<Map<String, dynamic>>.from(json['matchedDonors'] ?? []),
      acceptedDonors: List<Map<String, dynamic>>.from(json['acceptedDonors'] ?? []),
      notificationBroadcastAt: json['notificationBroadcastAt'] != null ? DateTime.parse(json['notificationBroadcastAt']) : null,
      broadcastRadius: json['broadcastRadius'] ?? 50,
      isActive: json['isActive'] ?? true,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  BloodRequestModel copyWith({
    String? requestId,
    String? userId,
    String? patientName,
    int? patientAge,
    BloodGroup? bloodGroupRequired,
    int? unitsRequired,
    int? unitsCollected,
    String? hospitalName,
    String? hospitalPhone,
    String? city,
    String? district,
    String? state,
    String? address,
    double? latitude,
    double? longitude,
    UrgencyLevel? urgencyLevel,
    String? urgencyDescription,
    String? contactNumber,
    String? alternateContactNumber,
    String? medicalDetails,
    RequestStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    DateTime? completedAt,
    List<Map<String, dynamic>>? matchedDonors,
    List<Map<String, dynamic>>? acceptedDonors,
    DateTime? notificationBroadcastAt,
    int? broadcastRadius,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return BloodRequestModel(
      requestId: requestId ?? this.requestId,
      userId: userId ?? this.userId,
      patientName: patientName ?? this.patientName,
      patientAge: patientAge ?? this.patientAge,
      bloodGroupRequired: bloodGroupRequired ?? this.bloodGroupRequired,
      unitsRequired: unitsRequired ?? this.unitsRequired,
      unitsCollected: unitsCollected ?? this.unitsCollected,
      hospitalName: hospitalName ?? this.hospitalName,
      hospitalPhone: hospitalPhone ?? this.hospitalPhone,
      city: city ?? this.city,
      district: district ?? this.district,
      state: state ?? this.state,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      urgencyDescription: urgencyDescription ?? this.urgencyDescription,
      contactNumber: contactNumber ?? this.contactNumber,
      alternateContactNumber: alternateContactNumber ?? this.alternateContactNumber,
      medicalDetails: medicalDetails ?? this.medicalDetails,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      completedAt: completedAt ?? this.completedAt,
      matchedDonors: matchedDonors ?? this.matchedDonors,
      acceptedDonors: acceptedDonors ?? this.acceptedDonors,
      notificationBroadcastAt: notificationBroadcastAt ?? this.notificationBroadcastAt,
      broadcastRadius: broadcastRadius ?? this.broadcastRadius,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }
}
