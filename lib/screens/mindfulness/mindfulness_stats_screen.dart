import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/mindfulness_service.dart';
import '../../models/mindfulness_exercise.dart';

class MindfulnessStatsScreen extends StatefulWidget {
  const MindfulnessStatsScreen({super.key});

  @override
  State<MindfulnessStatsScreen> createState() => _MindfulnessStatsScreenState();
}

class _MindfulnessStatsScreenState extends State<MindfulnessStatsScreen> {
  final MindfulnessService _mindfulnessService = MindfulnessService();

  Map<String, dynamic> _stats = {};
  List<ExerciseSession> _recentSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _mindfulnessService.getExerciseStats();
      final sessions = await _mindfulnessService.getRecentSessions(limit: 10);

      setState(() {
        _stats = stats;
        _recentSessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error loading stats: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Mindfulness Stats',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Cards
                  _buildOverviewCards(),

                  const SizedBox(height: 24),

                  // Weekly Progress Chart
                  _buildWeeklyChart(),

                  const SizedBox(height: 24),

                  // Exercise Type Breakdown
                  _buildExerciseTypeBreakdown(),

                  const SizedBox(height: 24),

                  // Recent Sessions
                  _buildRecentSessions(),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Total Sessions',
              '${_stats['totalSessions'] ?? 0}',
              Icons.play_circle,
              Colors.blue,
            ),
            _buildStatCard(
              'Total Minutes',
              '${_stats['totalMinutes'] ?? 0}',
              Icons.timer,
              Colors.green,
            ),
            _buildStatCard(
              'Current Streak',
              '${_stats['currentStreak'] ?? 0} days',
              Icons.local_fire_department,
              Colors.orange,
            ),
            _buildStatCard(
              'Today',
              '${_stats['completedToday'] ?? 0} exercises',
              Icons.today,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
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
            'Weekly Progress',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'Chart visualization would go here\n(Requires fl_chart package)',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color:
                      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseTypeBreakdown() {
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
            'Exercise Types',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...ExerciseType.values.map((type) => _buildTypeRow(type)),
        ],
      ),
    );
  }

  Widget _buildTypeRow(ExerciseType type) {
    final typeColor = _getTypeColor(type);
    final typeIcon = _getTypeIcon(type);
    final typeName = _getTypeDisplayName(type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              typeIcon,
              color: typeColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              typeName,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${_getTypeCount(type)}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: typeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSessions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Sessions',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (_recentSessions.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.history,
                    size: 48,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No sessions yet',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start practicing mindfulness to see your progress here',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentSessions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final session = _recentSessions[index];
              return _buildSessionCard(session);
            },
          ),
      ],
    );
  }

  Widget _buildSessionCard(ExerciseSession session) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: session.completed
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              session.completed ? Icons.check_circle : Icons.access_time,
              color: session.completed ? Colors.green : Colors.orange,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exercise Session',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(session.startTime),
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
          if (session.completed && session.endTime != null)
            Text(
              '${session.endTime!.difference(session.startTime).inMinutes} min',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.green,
              ),
            ),
        ],
      ),
    );
  }

  Color _getTypeColor(ExerciseType type) {
    switch (type) {
      case ExerciseType.breathing:
        return Colors.lightBlue;
      case ExerciseType.meditation:
        return Colors.purple;
      case ExerciseType.patience:
        return Colors.green;
      case ExerciseType.gratitude:
        return Colors.orange;
      case ExerciseType.affirmation:
        return Colors.pink;
      case ExerciseType.visualization:
        return Colors.indigo;
      case ExerciseType.bodyRelaxation:
        return Colors.teal;
    }
  }

  IconData _getTypeIcon(ExerciseType type) {
    switch (type) {
      case ExerciseType.breathing:
        return Icons.air;
      case ExerciseType.meditation:
        return Icons.self_improvement;
      case ExerciseType.patience:
        return Icons.hourglass_empty;
      case ExerciseType.gratitude:
        return Icons.favorite;
      case ExerciseType.affirmation:
        return Icons.psychology;
      case ExerciseType.visualization:
        return Icons.visibility;
      case ExerciseType.bodyRelaxation:
        return Icons.spa;
    }
  }

  String _getTypeDisplayName(ExerciseType type) {
    switch (type) {
      case ExerciseType.breathing:
        return 'Breathing';
      case ExerciseType.meditation:
        return 'Meditation';
      case ExerciseType.patience:
        return 'Patience';
      case ExerciseType.gratitude:
        return 'Gratitude';
      case ExerciseType.affirmation:
        return 'Affirmation';
      case ExerciseType.visualization:
        return 'Visualization';
      case ExerciseType.bodyRelaxation:
        return 'Body Relaxation';
    }
  }

  int _getTypeCount(ExerciseType type) {
    // This would normally query the database for counts by type
    // For now, return a placeholder
    return 0;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDate = DateTime(date.year, date.month, date.day);

    if (sessionDate == today) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (sessionDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

