import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/analytics/analytics_model.dart';
import '../models/audit_log_model.dart';

class AnalyticsRepository {
  final FirebaseFirestore _firestore;

  AnalyticsRepository(this._firestore);

  CollectionReference get _analytics => _firestore.collection('analytics');
  CollectionReference get _auditLogs => _firestore.collection('auditLogs');

  Future<AnalyticsModel?> getAnalyticsByDate(String date) async {
    final doc = await _analytics.doc(date).get();
    if (doc.exists) {
      return AnalyticsModel.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<List<AnalyticsModel>> getAnalyticsRange(DateTime start, DateTime end) async {
    final snapshot = await _analytics
        .where('timestamp', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('timestamp', isLessThanOrEqualTo: end.toIso8601String())
        .orderBy('timestamp', descending: true)
        .get();
    
    return snapshot.docs
        .map((doc) => AnalyticsModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> createAuditLog(AuditLogModel log) async {
    await _auditLogs.doc(log.logId).set(log.toJson());
  }

  Future<List<AuditLogModel>> getAuditLogsByUser(String userId) async {
    final snapshot = await _auditLogs
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();
        
    return snapshot.docs
        .map((doc) => AuditLogModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<AuditLogModel>> getAllAuditLogs({int limit = 100}) async {
    final snapshot = await _auditLogs
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
        
    return snapshot.docs
        .map((doc) => AuditLogModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getSystemSummary() async {
    final usersCount = await _firestore.collection('users').count().get();
    final donorsCount = await _firestore.collection('donors').count().get();
    final requestsCount = await _firestore.collection('requests').where('isActive', isEqualTo: true).count().get();
    final completedCount = await _firestore.collection('requests').where('status', isEqualTo: 'completed').count().get();

    // Calculate daily requests for last 7 days
    final List<int> dailyTrend = [];
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      
      final count = await _firestore.collection('requests')
          .where('createdAt', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('createdAt', isLessThan: end.toIso8601String())
          .count()
          .get();
      dailyTrend.add(count.count ?? 0);
    }

    return {
      'totalUsers': usersCount.count,
      'totalDonors': donorsCount.count,
      'activeRequests': requestsCount.count,
      'completedDonations': completedCount.count,
      'dailyRequests': dailyTrend,
    };
  }
}
