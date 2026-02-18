import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_usage_service.dart';
import '../widgets/app_usage_widget.dart';

class AppUsageScreen extends StatelessWidget {
  const AppUsageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'App Usage',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showUsageInfo(context),
          ),
        ],
      ),
      body: Consumer<AppUsageService>(
        builder: (context, usageService, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Usage Widget (Detailed View)
                const AppUsageWidget(showDetailed: true),
                const SizedBox(height: 24),

                // Quick Stats Cards
                _buildQuickStats(context, usageService),
                const SizedBox(height: 24),

                // Usage Insights
                _buildUsageInsights(context, usageService),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, AppUsageService service) {
    final weeklyData = service.getLast7DaysUsage();
    final weeklyTotal = weeklyData.values
        .fold<Duration>(Duration.zero, (sum, duration) => sum + duration);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Stats',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Weekly Total',
                _formatDurationShort(weeklyTotal),
                Icons.calendar_view_week_outlined,
                Theme.of(context).colorScheme.secondaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Daily Average',
                _formatDurationShort(
                    Duration(seconds: weeklyTotal.inSeconds ~/ 7)),
                Icons.timeline_outlined,
                Theme.of(context).colorScheme.tertiaryContainer,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Longest Session',
                _formatDurationShort(service.longestSessionToday),
                Icons.timer_outlined,
                Colors.orange.withValues(alpha: 0.1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Sessions Today',
                '${service.totalSessions}',
                Icons.play_circle_outline,
                Colors.purple.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color backgroundColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 24,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageInsights(BuildContext context, AppUsageService service) {
    final totalToday = service.totalDailyUsage + service.currentSessionDuration;
    final insights = _generateInsights(service, totalToday);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insights',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        ...insights.map((insight) => _buildInsightCard(context, insight)),
      ],
    );
  }

  Widget _buildInsightCard(BuildContext context, UsageInsight insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: insight.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: insight.color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            insight.icon,
            color: insight.color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  insight.description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<UsageInsight> _generateInsights(
      AppUsageService service, Duration totalToday) {
    final insights = <UsageInsight>[];
    final weeklyData = service.getLast7DaysUsage();
    final weeklyTotal = weeklyData.values
        .fold<Duration>(Duration.zero, (sum, duration) => sum + duration);
    final dailyAverage = Duration(seconds: weeklyTotal.inSeconds ~/ 7);

    // Current session insight
    if (service.isSessionActive &&
        service.currentSessionDuration.inMinutes > 30) {
      insights.add(UsageInsight(
        title: 'Long Session Alert',
        description:
            'You\'ve been using the app for ${_formatDurationShort(service.currentSessionDuration)}. Consider taking a break!',
        icon: Icons.schedule_outlined,
        color: Colors.orange,
      ));
    }

    // Daily comparison
    if (totalToday > dailyAverage) {
      final difference = totalToday - dailyAverage;
      insights.add(UsageInsight(
        title: 'Above Average Usage',
        description:
            'You\'ve used the app ${_formatDurationShort(difference)} more than your daily average.',
        icon: Icons.trending_up,
        color: Colors.blue,
      ));
    } else if (dailyAverage.inMinutes > 0) {
      insights.add(UsageInsight(
        title: 'Balanced Usage',
        description: 'Your usage today is within your normal range.',
        icon: Icons.balance,
        color: Colors.green,
      ));
    }

    // Session pattern insight
    if (service.totalSessions > 10) {
      insights.add(UsageInsight(
        title: 'Frequent Check-ins',
        description:
            'You\'ve opened the app ${service.totalSessions} times today. You\'re staying engaged!',
        icon: Icons.touch_app,
        color: Colors.purple,
      ));
    } else if (service.totalSessions > 0 &&
        service.averageSessionDuration.inMinutes > 10) {
      insights.add(UsageInsight(
        title: 'Focused Sessions',
        description:
            'Your sessions average ${_formatDurationShort(service.averageSessionDuration)}. Great focus!',
        icon: Icons.center_focus_strong,
        color: Colors.teal,
      ));
    }

    return insights;
  }

  void _showUsageInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'About App Usage',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This feature tracks how much time you spend using Every Day Chronicles. '
          'It helps you understand your journaling habits and maintain a healthy balance.\n\n'
          '• Sessions are tracked when the app is active\n'
          '• Data is stored locally on your device\n'
          '• Weekly statistics show your usage patterns\n'
          '• Insights help you maintain healthy habits',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
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

class UsageInsight {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  UsageInsight({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
