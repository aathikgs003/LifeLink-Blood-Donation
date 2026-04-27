enum UserRole {
  donor,
  requester,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.donor:
        return 'Donor';
      case UserRole.requester:
        return 'Requester';
      case UserRole.admin:
        return 'Admin';
    }
  }

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.requester,
    );
  }
}

enum BloodGroup {
  oPositive,
  oNegative,
  aPositive,
  aNegative,
  bPositive,
  bNegative,
  abPositive,
  abNegative;

  String get displayName {
    switch (this) {
      case BloodGroup.oPositive:  return 'O+';
      case BloodGroup.oNegative:  return 'O-';
      case BloodGroup.aPositive:  return 'A+';
      case BloodGroup.aNegative:  return 'A-';
      case BloodGroup.bPositive:  return 'B+';
      case BloodGroup.bNegative:  return 'B-';
      case BloodGroup.abPositive: return 'AB+';
      case BloodGroup.abNegative: return 'AB-';
    }
  }

  String get firestoreValue => name;

  static BloodGroup fromString(String value) {
    return BloodGroup.values.firstWhere(
      (e) => e.name == value || e.displayName == value,
      orElse: () => BloodGroup.oPositive,
    );
  }

  /// Returns compatible donor blood groups for this recipient blood group
  List<BloodGroup> get compatibleDonors {
    switch (this) {
      case BloodGroup.oPositive:
        return [BloodGroup.oPositive, BloodGroup.oNegative];
      case BloodGroup.oNegative:
        return [BloodGroup.oNegative];
      case BloodGroup.aPositive:
        return [BloodGroup.aPositive, BloodGroup.aNegative, BloodGroup.oPositive, BloodGroup.oNegative];
      case BloodGroup.aNegative:
        return [BloodGroup.aNegative, BloodGroup.oNegative];
      case BloodGroup.bPositive:
        return [BloodGroup.bPositive, BloodGroup.bNegative, BloodGroup.oPositive, BloodGroup.oNegative];
      case BloodGroup.bNegative:
        return [BloodGroup.bNegative, BloodGroup.oNegative];
      case BloodGroup.abPositive:
        return BloodGroup.values; // Universal recipient
      case BloodGroup.abNegative:
        return [BloodGroup.aNegative, BloodGroup.bNegative, BloodGroup.oNegative, BloodGroup.abNegative];
    }
  }
}

enum UrgencyLevel {
  normal,
  urgent,
  critical;

  String get displayName {
    switch (this) {
      case UrgencyLevel.normal:   return 'Normal';
      case UrgencyLevel.urgent:   return 'Urgent';
      case UrgencyLevel.critical: return 'Critical';
    }
  }

  static UrgencyLevel fromString(String value) {
    return UrgencyLevel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UrgencyLevel.normal,
    );
  }
}

enum RequestStatus {
  pending,
  accepted,
  inProgress,
  partiallyFulfilled,
  completed,
  cancelled,
  expired;

  String get displayName {
    switch (this) {
      case RequestStatus.pending:             return 'Pending';
      case RequestStatus.accepted:            return 'Accepted';
      case RequestStatus.inProgress:          return 'In Progress';
      case RequestStatus.partiallyFulfilled:  return 'Partially Fulfilled';
      case RequestStatus.completed:           return 'Completed';
      case RequestStatus.cancelled:           return 'Cancelled';
      case RequestStatus.expired:             return 'Expired';
    }
  }

  static RequestStatus fromString(String value) {
    return RequestStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RequestStatus.pending,
    );
  }
}

enum DonorMatchStatus {
  invited,
  accepted,
  declined,
  noResponse,
  collected;

  String get displayName {
    switch (this) {
      case DonorMatchStatus.invited:    return 'Invited';
      case DonorMatchStatus.accepted:   return 'Accepted';
      case DonorMatchStatus.declined:   return 'Declined';
      case DonorMatchStatus.noResponse: return 'No Response';
      case DonorMatchStatus.collected:  return 'Collected';
    }
  }

  static DonorMatchStatus fromString(String value) {
    return DonorMatchStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DonorMatchStatus.invited,
    );
  }
}

enum NotificationType {
  bloodRequest,
  donorMatched,
  donorAccepted,
  requestAccepted,
  requestCompleted,
  requestCancelled,
  verificationApproved,
  verificationRejected,
  chat,
  reminder,
  emergency,
  payment,
  system;

  String get displayName {
    switch (this) {
      case NotificationType.bloodRequest:         return 'Blood Request';
      case NotificationType.donorMatched:         return 'Donor Matched';
      case NotificationType.donorAccepted:        return 'Donor Accepted';
      case NotificationType.requestAccepted:      return 'Request Accepted';
      case NotificationType.requestCompleted:     return 'Request Completed';
      case NotificationType.requestCancelled:     return 'Request Cancelled';
      case NotificationType.verificationApproved: return 'Verification Approved';
      case NotificationType.verificationRejected: return 'Verification Rejected';
      case NotificationType.chat:                 return 'Message';
      case NotificationType.reminder:             return 'Reminder';
      case NotificationType.emergency:            return 'Emergency Alert';
      case NotificationType.payment:              return 'Payment';
      case NotificationType.system:               return 'System';
    }
  }

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationType.system,
    );
  }
}

enum PaymentType {
  monetaryDonation,
  subscriptionFee,
  tip;

  String get displayName {
    switch (this) {
      case PaymentType.monetaryDonation: return 'Donation';
      case PaymentType.subscriptionFee:  return 'Subscription';
      case PaymentType.tip:              return 'Tip';
    }
  }

  static PaymentType fromString(String value) {
    return PaymentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentType.monetaryDonation,
    );
  }
}

enum PaymentStatus {
  pending,
  success,
  failed,
  refunded;

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:  return 'Pending';
      case PaymentStatus.success:  return 'Success';
      case PaymentStatus.failed:   return 'Failed';
      case PaymentStatus.refunded: return 'Refunded';
    }
  }

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentStatus.pending,
    );
  }
}

enum MessageType {
  text,
  image,
  location,
  system;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessageType.text,
    );
  }
}

enum VerificationStatus {
  pending,
  verified,
  rejected,
  moreInfoRequired;

  String get displayName {
    switch (this) {
      case VerificationStatus.pending:          return 'Pending';
      case VerificationStatus.verified:         return 'Verified';
      case VerificationStatus.rejected:         return 'Rejected';
      case VerificationStatus.moreInfoRequired: return 'More Info Required';
    }
  }

  static VerificationStatus fromString(String value) {
    return VerificationStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => VerificationStatus.pending,
    );
  }
}

enum PasswordStrength {
  weak,
  fair,
  good,
  strong;

  String get displayName {
    switch (this) {
      case PasswordStrength.weak:   return 'Weak';
      case PasswordStrength.fair:   return 'Fair';
      case PasswordStrength.good:   return 'Good';
      case PasswordStrength.strong: return 'Strong';
    }
  }
}

enum ThemeModeOption {
  system,
  light,
  dark;

  String get displayName {
    switch (this) {
      case ThemeModeOption.system: return 'System';
      case ThemeModeOption.light:  return 'Light';
      case ThemeModeOption.dark:   return 'Dark';
    }
  }
}

enum RhFactor {
  positive,
  negative;

  String get displayName => name;

  static RhFactor fromString(String value) {
    return RhFactor.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RhFactor.positive,
    );
  }
}

enum SubscriptionStatus {
  free,
  premium,
  admin;

  static SubscriptionStatus fromString(String value) {
    return SubscriptionStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SubscriptionStatus.free,
    );
  }
}

enum ContactMethod {
  call,
  sms,
  push;

  static ContactMethod fromString(String value) {
    return ContactMethod.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ContactMethod.push,
    );
  }
}
