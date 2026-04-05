import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/error_handler.dart';
import '../../models/dashboard.dart';
import '../../models/user.dart';
import '../../services/dashboard_service.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardService _dashboardService;

  DashboardCubit({DashboardService? dashboardService})
      : _dashboardService = dashboardService ?? DashboardService(),
        super(DashboardInitial());

  Future<void> fetchAll(UserRole role) async {
    emit(DashboardLoading());
    try {
      final results = await Future.wait([
        _dashboardService.getSummary(),
        _dashboardService.getCompletionRate(),
        _dashboardService.getByPriority(),
      ]);

      List<UserTaskCount>? userCounts;
      if (role == UserRole.admin || role == UserRole.manager) {
        userCounts = await _dashboardService.getByUser();
      }

      emit(DashboardLoaded(
        summary: results[0] as DashboardSummary,
        completionRate: results[1] as CompletionRate,
        priorityBreakdown: results[2] as PriorityBreakdown,
        userCounts: userCounts,
      ));
    } catch (e) {
      emit(DashboardError(ErrorHandler.getMessage(e)));
    }
  }

  Future<void> fetchDateRange(
    UserRole role, {
    String? startDate,
    String? endDate,
  }) async {
    final currentState = state;
    try {
      final dateRangeStats = await _dashboardService.getDateRange(
        startDate: startDate,
        endDate: endDate,
      );
      if (currentState is DashboardLoaded) {
        emit(DashboardLoaded(
          summary: currentState.summary,
          completionRate: currentState.completionRate,
          priorityBreakdown: currentState.priorityBreakdown,
          userCounts: currentState.userCounts,
          dateRangeStats: dateRangeStats,
        ));
      }
    } catch (e) {
      emit(DashboardError(ErrorHandler.getMessage(e)));
    }
  }
}
