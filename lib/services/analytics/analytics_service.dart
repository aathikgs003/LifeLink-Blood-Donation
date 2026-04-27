import '../../models/analytics/analytics_model.dart';
import '../../models/audit_log_model.dart';
import '../../repositories/analytics_repository.dart';

class AnalyticsService {
  final AnalyticsRepository _analyticsRepository;

  AnalyticsService(this._analyticsRepository);

  Future<AnalyticsModel?> getDailyStats(String date) async {
    return await _analyticsRepository.getAnalyticsByDate(date);
  }

  Future<List<AnalyticsModel>> getStatsForPeriod(DateTime start, DateTime end) async {
    return await _analyticsRepository.getAnalyticsRange(start, end);
  }

  Future<void> logAction(String userId, String action, String resource, String resourceId, {Map<String, dynamic> changes = const {}}) async {
    final log = AuditLogModel(
      logId: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      action: action,
      resource: resource,
      resourceId: resourceId,
      timestamp: DateTime.now(),
      changes: changes,
    );
    await _analyticsRepository.createAuditLog(log);
  }

  Future<List<AuditLogModel>> getSystemLogs() {
    return _analyticsRepository.getAllAuditLogs();
  }

  Future<SystemAnalytics> getSystemAnalytics() async {
    final data = await _analyticsRepository.getSystemSummary();
    return SystemAnalytics.fromJson(data);
  }
}
