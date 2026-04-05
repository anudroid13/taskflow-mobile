import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/dashboard.dart';

class DashboardService {
  final Dio _dio = ApiClient().dio;

  Future<DashboardSummary> getSummary() async {
    final response = await _dio.get('/dashboard/summary');
    return DashboardSummary.fromJson(response.data);
  }

  Future<CompletionRate> getCompletionRate() async {
    final response = await _dio.get('/dashboard/completion-rate');
    return CompletionRate.fromJson(response.data);
  }

  Future<PriorityBreakdown> getByPriority() async {
    final response = await _dio.get('/dashboard/by-priority');
    return PriorityBreakdown.fromJson(response.data);
  }

  Future<List<UserTaskCount>> getByUser() async {
    final response = await _dio.get('/dashboard/by-user');
    return (response.data as List)
        .map((e) => UserTaskCount.fromJson(e))
        .toList();
  }

  Future<DateRangeStats> getDateRange({
    String? startDate,
    String? endDate,
  }) async {
    final params = <String, dynamic>{};
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;

    final response = await _dio.get(
      '/dashboard/date-range',
      queryParameters: params,
    );
    return DateRangeStats.fromJson(response.data);
  }
}
