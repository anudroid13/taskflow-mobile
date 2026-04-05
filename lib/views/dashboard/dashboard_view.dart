import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/dashboard/dashboard_cubit.dart';
import '../../cubits/dashboard/dashboard_state.dart';
import '../../models/dashboard.dart';
import '../../models/user.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  void _loadDashboard() {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      context.read<DashboardCubit>().fetchAll(authState.user.role);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: () async => _loadDashboard(),
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is DashboardError) {
              return Center(child: Text(state.message));
            }
            if (state is DashboardLoaded) {
              return _buildDashboard(context, state);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, DashboardLoaded state) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          _SummaryCards(summary: state.summary),
          const SizedBox(height: 24),

          // Completion rate
          Text('Completion Rate',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _CompletionRateChart(rate: state.completionRate),
          const SizedBox(height: 24),

          // Priority breakdown
          Text('Tasks by Priority',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _PriorityChart(breakdown: state.priorityBreakdown),
          const SizedBox(height: 24),

          // Team overview (admin/manager only)
          if (state.userCounts != null) ...[
            Text('Team Overview',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _TeamOverview(users: state.userCounts!),
            const SizedBox(height: 24),
          ],

          // Date range filter
          _DateRangeSection(state: state),
        ],
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final DashboardSummary summary;

  const _SummaryCards({required this.summary});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _SummaryCard(
            label: 'Total', value: summary.total, color: Colors.blue),
        _SummaryCard(
            label: 'To Do', value: summary.todo, color: Colors.blue.shade300),
        _SummaryCard(
            label: 'In Progress',
            value: summary.inProgress,
            color: Colors.orange),
        _SummaryCard(
            label: 'Done', value: summary.done, color: Colors.green),
        _SummaryCard(
            label: 'Overdue', value: summary.overdue, color: Colors.red),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label, style: TextStyle(color: color, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _CompletionRateChart extends StatelessWidget {
  final CompletionRate rate;

  const _CompletionRateChart({required this.rate});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Row(
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    value: rate.completionPercentage,
                    color: Colors.green,
                    title: '${rate.completionPercentage.toInt()}%',
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    radius: 35,
                  ),
                  PieChartSectionData(
                    value: 100 - rate.completionPercentage,
                    color: Colors.grey.shade300,
                    title: '',
                    radius: 30,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${rate.completedTasks} of ${rate.totalTasks} tasks',
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 4),
              Text('completed',
                  style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriorityChart extends StatelessWidget {
  final PriorityBreakdown breakdown;

  const _PriorityChart({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final maxVal = [breakdown.low, breakdown.medium, breakdown.high]
        .reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (maxVal + 2).toDouble(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  switch (value.toInt()) {
                    case 0:
                      return const Text('Low');
                    case 1:
                      return const Text('Medium');
                    case 2:
                      return const Text('High');
                    default:
                      return const SizedBox.shrink();
                  }
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 30),
            ),
            topTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            _barGroup(0, breakdown.low.toDouble(), Colors.teal),
            _barGroup(1, breakdown.medium.toDouble(), Colors.amber.shade700),
            _barGroup(2, breakdown.high.toDouble(), Colors.red),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 28,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }
}

class _TeamOverview extends StatelessWidget {
  final List<UserTaskCount> users;

  const _TeamOverview({required this.users});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: users
            .map((u) => ListTile(
                  leading: CircleAvatar(
                    child: Text(u.fullName.isNotEmpty
                        ? u.fullName[0].toUpperCase()
                        : '?'),
                  ),
                  title: Text(u.fullName),
                  subtitle: Text(u.email),
                  trailing: Chip(
                    label: Text('${u.taskCount}'),
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _DateRangeSection extends StatefulWidget {
  final DashboardLoaded state;

  const _DateRangeSection({required this.state});

  @override
  State<_DateRangeSection> createState() => _DateRangeSectionState();
}

class _DateRangeSectionState extends State<_DateRangeSection> {
  DateTimeRange? _selectedRange;

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final role =
        authState is Authenticated ? authState.user.role : UserRole.employee;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Date Range Stats',
                style: Theme.of(context).textTheme.titleMedium),
            TextButton.icon(
              onPressed: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (range != null && mounted) {
                  setState(() => _selectedRange = range);
                  context.read<DashboardCubit>().fetchDateRange(
                        role,
                        startDate: range.start.toIso8601String().split('T')[0],
                        endDate: range.end.toIso8601String().split('T')[0],
                      );
                }
              },
              icon: const Icon(Icons.date_range, size: 18),
              label: const Text('Select Range'),
            ),
          ],
        ),
        if (_selectedRange != null && widget.state.dateRangeStats != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatColumn(
                    label: 'Total',
                    value: widget.state.dateRangeStats!.total.toString(),
                  ),
                  _StatColumn(
                    label: 'Completed',
                    value: widget.state.dateRangeStats!.completed.toString(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }
}
