class AppConstants {
  // App Info
  static const String appName = 'LifeLink';
  static const String appTagline = 'Connecting Lives, Saving Hearts';
  static const String appVersion = '1.0.0';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String donorsCollection = 'donors';
  static const String requestsCollection = 'blood_requests';
  static const String notificationsCollection = 'notifications';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String paymentsCollection = 'payments';
  static const String auditLogsCollection = 'audit_logs';
  static const String analyticsCollection = 'analytics';

  // Firebase Storage Paths
  static const String profileImagesPath = 'profile_images';
  static const String requestDocumentsPath = 'request_documents';
  static const String receiptPath = 'receipts';

  // Pagination
  static const int defaultPageSize = 20;
  static const int chatPageSize = 50;
  static const int notificationPageSize = 30;

  // Donation eligibility
  static const int donationIntervalDays = 90; // 90 days between donations
  static const int minimumAge = 18;
  static const int maximumAge = 65;
  static const double minimumWeightKg = 50.0;

  // Blood request limits
  static const int minUnitsRequired = 1;
  static const int maxUnitsRequired = 10;
  static const int requestExpiryHours = 72; // 3 days
  static const int broadcastCooldownHours = 6;

  // Chat
  static const int typingIndicatorTimeoutSeconds = 5;
  static const int maxMessageLength = 1000;
  static const int maxImageSizeMb = 5;

  // Payment
  static const int minimumDonationAmount = 10; // INR
  static const String currency = 'INR';
  static const String currencySymbol = '₹';

  // Search
  static const int searchDebounceMs = 500;
  static const double defaultSearchRadiusKm = 25.0;
  static const double maxSearchRadiusKm = 100.0;

  // OTP / Auth
  static const int otpResendCooldownSeconds = 60;
  static const int sessionTimeoutMinutes = 30;
  static const int maxLoginAttempts = 5;

  // Shared Preferences Keys
  static const String keyOnboardingCompleted = 'onboarding_completed';
  static const String keyThemeMode = 'theme_mode';
  static const String keyUserRole = 'user_role';
  static const String keyFcmToken = 'fcm_token';
  static const String keyLastSyncTime = 'last_sync_time';

  // Predefined Amounts for Donation
  static const List<int> predefinedAmounts = [100, 500, 1000, 2000, 5000];

  // Indian States
  static const List<String> indianStates = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand',
    'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur',
    'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab',
    'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura',
    'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
    'Andaman and Nicobar Islands', 'Chandigarh', 'Dadra and Nagar Haveli',
    'Daman and Diu', 'Delhi', 'Lakshadweep', 'Puducherry', 'Ladakh', 'Jammu and Kashmir'
  ];

  // Health Conditions
  static const List<String> healthConditions = [
    'None', 'Diabetes', 'Hypertension', 'Heart Disease', 'Asthma',
    'Anemia', 'Kidney Disease', 'Liver Disease', 'Cancer', 'HIV/AIDS',
    'Hepatitis B', 'Hepatitis C', 'Tuberculosis', 'Other'
  ];

  // Emergency Contact Relationships
  static const List<String> relationships = [
    'Spouse', 'Parent', 'Child', 'Sibling', 'Friend',
    'Colleague', 'Relative', 'Other'
  ];

  // Relation to Patient (for blood requests)
  static const List<String> patientRelations = [
    'Self', 'Spouse', 'Parent', 'Child', 'Sibling',
    'Friend', 'Relative', 'Other'
  ];

  // Rejection reasons (admin)
  static const List<String> verificationRejectionReasons = [
    'Incomplete profile',
    'Invalid age (must be 18-65)',
    'Weight below minimum (50kg)',
    'Unclear profile picture',
    'Invalid blood group',
    'Providing false information',
    'Health conditions disqualify donation',
    'Other'
  ];

  // Request cancellation reasons
  static const List<String> requestCancellationReasons = [
    'Blood found from other source',
    'Patient condition changed',
    'Request created by mistake',
    'Hospital changed',
    'No longer required',
    'Other'
  ];

  // Unavailability reasons
  static const List<String> unavailabilityReasons = [
    'Traveling', 'Health issues', 'Recently donated',
    'Busy schedule', 'Personal reasons', 'Other'
  ];
}
