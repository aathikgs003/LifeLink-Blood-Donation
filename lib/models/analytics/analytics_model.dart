class AnalyticsModel {
  final String date; // YYYY-MM-DD
  final int totalRequests;
  final int newDonors;
  final int completedRequests;
  final int activeRequests;
  final int cancelledRequests;
  final Map<String, int> requestsByBloodGroup;
  final Map<String, int> requestsByCity;
  final Map<String, int> requestsByUrgency;
  final double averageResponseTime; // Seconds
  final double completionRate; // Percentage
  final int totalDonations;
  final DateTime timestamp;

  AnalyticsModel({
    required this.date,
    this.totalRequests = 0,
    this.newDonors = 0,
    this.completedRequests = 0,
    this.activeRequests = 0,
    this.cancelledRequests = 0,
    this.requestsByBloodGroup = const {},
    this.requestsByCity = const {},
    this.requestsByUrgency = const {},
    this.averageResponseTime = 0.0,
    this.completionRate = 0.0,
    this.totalDonations = 0,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'totalRequests': totalRequests,
      'newDonors': newDonors,
      'completedRequests': completedRequests,
      'activeRequests': activeRequests,
      'cancelledRequests': cancelledRequests,
      'requestsByBloodGroup': requestsByBloodGroup,
      'requestsByCity': requestsByCity,
      'requestsByUrgency': requestsByUrgency,
      'averageResponseTime': averageResponseTime,
      'completionRate': completionRate,
      'totalDonations': totalDonations,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AnalyticsModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsModel(
      date: json['date'] ?? '',
      totalRequests: json['totalRequests'] ?? 0,
      newDonors: json['newDonors'] ?? 0,
      completedRequests: json['completedRequests'] ?? 0,
      activeRequests: json['activeRequests'] ?? 0,
      cancelledRequests: json['cancelledRequests'] ?? 0,
      requestsByBloodGroup: Map<String, int>.from(json['requestsByBloodGroup'] ?? {}),
      requestsByCity: Map<String, int>.from(json['requestsByCity'] ?? {}),
      requestsByUrgency: Map<String, int>.from(json['requestsByUrgency'] ?? {}),
      averageResponseTime: (json['averageResponseTime'] as num?)?.toDouble() ?? 0.0,
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0.0,
      totalDonations: json['totalDonations'] ?? 0,
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
    );
  }
}

class SystemAnalytics {
  final int totalUsers;
  final int totalDonors;
  final int activeRequests;
  final int completedDonations;
  final List<int> dailyRequests;

  SystemAnalytics({
    required this.totalUsers,
    required this.totalDonors,
    required this.activeRequests,
    required this.completedDonations,
    required this.dailyRequests,
  });

  factory SystemAnalytics.fromJson(Map<String, dynamic> json) {
    return SystemAnalytics(
      totalUsers: json['totalUsers'] ?? 0,
      totalDonors: json['totalDonors'] ?? 0,
      activeRequests: json['activeRequests'] ?? 0,
      completedDonations: json['completedDonations'] ?? 0,
      dailyRequests: List<int>.from(json['dailyRequests'] ?? []),
    );
  }
}
