import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_usage_service.dart';

class AppUsageWidget extends StatelessWidget {
  final bool showDetailed;

  const AppUsageWidget({
    super.key,
    this.showDetailed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppUsageService>(
      builder: (context, usageService, child) {
        if (showDetailed) {
          return _buildDetailedView(context, usageService);
        } else {
          return _buildCompactView(context, usageService);
        }
      },
    );
  }

  Widget _buildCompactView(BuildContext context, AppUsageService service) {
    final totalToday = service.totalDailyUsage + service.currentSessionDuration;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Usage',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  _formatDuration(totalToday),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (service.isSessionActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Active',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.green[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailedView(BuildContext context, AppUsageService service) {
    final totalToday = service.totalDailyUsage + service.currentSessionDuration;
    final last7Days = service.getLast7DaysUsage();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          '📱 App Usage Statistics',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),

        // Today's Summary
        _buildSummaryCard(context, service, totalToday),
        const SizedBox(height: 16),

        // Current Session (if active)
        if (service.isSessionActive) ...[
          _buildCurrentSessionCard(context, service),
          const SizedBox(height: 16),
        ],

        // Today's Sessions
        if (service.todaySessions.isNotEmpty) ...[
          _buildSessionsCard(context, service),
          const SizedBox(height: 16),
        ],

        // Weekly Chart
        _buildWeeklyChart(context, last7Days),
      ],
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, AppUsageService service, Duration totalToday) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Total',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              Icon(
                Icons.today_outlined,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatDuration(totalToday),
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatItem(
                context,
                'Sessions',
                '${service.totalSessions}',
                Icons.play_circle_outline,
              ),
              const SizedBox(width: 16),
              if (service.totalSessions > 0)
                _buildStatItem(
                  context,
                  'Average',
                  _formatDurationShort(service.averageSessionDuration),
                  Icons.bar_chart_outlined,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSessionCard(
      BuildContext context, AppUsageService service) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            color: Colors.green[600],
            size: 12,
          ),
          const SizedBox(width: 8),
          Text(
            'Current Session: ',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.green[700],
            ),
          ),
          Text(
            _formatDuration(service.currentSessionDuration),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.green[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsCard(BuildContext context, AppUsageService service) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Sessions',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...service.todaySessions.take(5).map(
                (session) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        session.timeRange,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        session.formattedDuration,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (service.todaySessions.length > 5)
            Text(
              '... and ${service.todaySessions.length - 5} more sessions',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(
      BuildContext context, Map<String, Duration> weeklyData) {
    final maxDuration = weeklyData.values.isEmpty
        ? Duration.zero
        : weeklyData.values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last 7 Days',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: weeklyData.entries.map((entry) {
              final percentage = maxDuration.inSeconds > 0
                  ? entry.value.inSeconds / maxDuration.inSeconds
                  : 0.0;
              final height = (percentage * 60).clamp(4.0, 60.0);

              return Column(
                children: [
                  Container(
                    width: 24,
                    height: height,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.key.split('-')[2], // Day only
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context)
              .colorScheme
              .onPrimaryContainer
              .withValues(alpha: 0.7),
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Theme.of(context)
                    .colorScheme
                    .onPrimaryContainer
                    .withValues(alpha: 0.7),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _formatDurationShort(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}
