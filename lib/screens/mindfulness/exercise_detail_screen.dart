import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/mindfulness_exercise.dart';
import 'exercise_session_screen.dart';

class ExerciseDetailScreen extends StatelessWidget {
  final MindfulnessExercise exercise;

  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
  });

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
    final typeColor = _getTypeColor(exercise.type);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // App Bar with gradient
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            elevation: 0,
            backgroundColor: typeColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      typeColor.withValues(alpha: 0.8),
                      typeColor.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40), // Account for status bar
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          _getTypeIcon(exercise.type),
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        exercise.title,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        exercise.typeDisplayName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Info Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          'Duration',
                          exercise.durationText,
                          Icons.timer,
                          context,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoCard(
                          'Difficulty',
                          exercise.difficultyDisplayName,
                          Icons.trending_up,
                          context,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Description
                  _buildSection(
                    'About This Exercise',
                    exercise.description,
                    Icons.info_outline,
                    context,
                  ),

                  const SizedBox(height: 24),

                  // Instructions
                  _buildSection(
                    'How to Practice',
                    null,
                    Icons.list_alt,
                    context,
                    children:
                        exercise.instructions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final instruction = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: typeColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                instruction,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  height: 1.5,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Benefits
                  if (exercise.benefits.isNotEmpty)
                    _buildSection(
                      'Benefits',
                      null,
                      Icons.favorite_outline,
                      context,
                      children: exercise.benefits.map((benefit) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 20,
                                color: typeColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  benefit,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    height: 1.4,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),

      // Start Exercise Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      ExerciseSessionScreen(exercise: exercise),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: typeColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_arrow, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Start Exercise',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      String title, String value, IconData icon, BuildContext context) {
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
        children: [
          Icon(
            icon,
            color: _getTypeColor(exercise.type),
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
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

  Widget _buildSection(
      String title, String? content, IconData icon, BuildContext context,
      {List<Widget>? children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: _getTypeColor(exercise.type),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (content != null)
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.6,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        if (children != null) ...children,
      ],
    );
  }
}
