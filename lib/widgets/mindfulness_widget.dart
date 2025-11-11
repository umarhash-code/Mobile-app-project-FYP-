import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/mindfulness_exercise.dart';
import '../services/mindfulness_service.dart';
import '../screens/mindfulness/mindfulness_screen.dart';
import '../screens/mindfulness/exercise_detail_screen.dart';

class MindfulnessWidget extends StatefulWidget {
  const MindfulnessWidget({super.key});

  @override
  State<MindfulnessWidget> createState() => _MindfulnessWidgetState();
}

class _MindfulnessWidgetState extends State<MindfulnessWidget> {
  final MindfulnessService _mindfulnessService = MindfulnessService();

  List<MindfulnessExercise> _recommendedExercises = [];
  Map<String, dynamic> _todayStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final recommended = await _mindfulnessService.getRecommendedExercises();
      final stats = await _mindfulnessService.getExerciseStats();

      setState(() {
        _recommendedExercises = recommended.take(3).toList();
        _todayStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          margin: const EdgeInsets.all(4),
          height: constraints.maxHeight,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.self_improvement,
                          color: Colors.green,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mindfulness & Patience',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_todayStats.isNotEmpty)
                              Text(
                                '${_todayStats['completedToday'] ?? 0} exercises today',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const MindfulnessScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Today's Progress
                if (_todayStats.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                            'Streak',
                            '${_todayStats['currentStreak'] ?? 0}',
                            Icons.local_fire_department),
                        _buildStatItem('Minutes',
                            '${_todayStats['totalMinutes'] ?? 0}', Icons.timer),
                        _buildStatItem(
                            'Sessions',
                            '${_todayStats['totalSessions'] ?? 0}',
                            Icons.play_circle),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                // Recommended Exercises
                if (_recommendedExercises.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          'Recommended for You',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _recommendedExercises.length,
                      itemBuilder: (context, index) {
                        final exercise = _recommendedExercises[index];
                        return _buildExerciseCard(exercise);
                      },
                    ),
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Icon(
                          Icons.self_improvement,
                          size: 32,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Start your mindfulness journey',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const MindfulnessScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Explore Exercises',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.green,
          size: 16,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseCard(MindfulnessExercise exercise) {
    final typeColor = _getTypeColor(exercise.type);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ExerciseDetailScreen(exercise: exercise),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: typeColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: typeColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getTypeIcon(exercise.type),
                  color: typeColor,
                  size: 16,
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    exercise.durationText,
                    style: GoogleFonts.poppins(
                      fontSize: 8,
                      color: typeColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              exercise.title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              exercise.typeDisplayName,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: typeColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
