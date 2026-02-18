import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/mindfulness_exercise.dart';
import '../../services/mindfulness_service.dart';
import 'exercise_detail_screen.dart';

class MindfulnessScreen extends StatefulWidget {
  const MindfulnessScreen({super.key});

  @override
  State<MindfulnessScreen> createState() => _MindfulnessScreenState();
}

class _MindfulnessScreenState extends State<MindfulnessScreen>
    with TickerProviderStateMixin {
  final MindfulnessService _mindfulnessService = MindfulnessService();
  late TabController _tabController;

  List<MindfulnessExercise> _allExercises = [];
  List<MindfulnessExercise> _recommendedExercises = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final exercises = await _mindfulnessService.getAllExercises();
      final recommended = await _mindfulnessService.getRecommendedExercises();
      final stats = await _mindfulnessService.getExerciseStats();

      setState(() {
        _allExercises = exercises;
        _recommendedExercises = recommended;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading exercises: $e',
                style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<MindfulnessExercise> _getExercisesByType(ExerciseType type) {
    return _allExercises.where((exercise) => exercise.type == type).toList();
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
          'Mindfulness & Patience',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Stats Card
                if (_stats.isNotEmpty)
                  SliverToBoxAdapter(child: _buildStatsCard()),

                // Recommended Exercises
                if (_recommendedExercises.isNotEmpty)
                  SliverToBoxAdapter(child: _buildRecommendedSection()),

                // Category Tabs
                SliverToBoxAdapter(child: _buildCategoryTabs()),

                // Exercise List
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildExerciseGrid(_allExercises),
                      _buildExerciseGrid(
                          _getExercisesByType(ExerciseType.breathing)),
                      _buildExerciseGrid(
                          _getExercisesByType(ExerciseType.patience)),
                      _buildExerciseGrid(
                          _getExercisesByType(ExerciseType.meditation)),
                      _buildExerciseGrid(
                          _getExercisesByType(ExerciseType.gratitude)),
                      _buildExerciseGrid(
                          _getExercisesByType(ExerciseType.affirmation)),
                      _buildExerciseGrid(
                          _getExercisesByType(ExerciseType.visualization)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Your Mindfulness Journey',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Sessions',
                '${_stats['totalSessions'] ?? 0}',
                Icons.play_circle,
              ),
              _buildStatItem(
                'Minutes',
                '${_stats['totalMinutes'] ?? 0}',
                Icons.timer,
              ),
              _buildStatItem(
                'Streak',
                '${_stats['currentStreak'] ?? 0}',
                Icons.local_fire_department,
              ),
              _buildStatItem(
                'Today',
                '${_stats['completedToday'] ?? 0}',
                Icons.today,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.onPrimary,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color:
                Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommended for You',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 130, // Increased from 120 to 130 to fix 4.0 pixel overflow
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _recommendedExercises.length,
              itemBuilder: (context, index) {
                final exercise = _recommendedExercises[index];
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  child: _buildExerciseCard(exercise, isCompact: true),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: Theme.of(context).colorScheme.primary,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor:
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            GoogleFonts.poppins(fontWeight: FontWeight.normal),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Breathing'),
          Tab(text: 'Patience'),
          Tab(text: 'Meditation'),
          Tab(text: 'Gratitude'),
          Tab(text: 'Affirmation'),
          Tab(text: 'Visualization'),
        ],
      ),
    );
  }

  Widget _buildExerciseGrid(List<MindfulnessExercise> exercises) {
    if (exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.self_improvement,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No exercises found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new exercises',
              style: GoogleFonts.poppins(
                fontSize: 14,
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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          return _buildExerciseCard(exercises[index]);
        },
      ),
    );
  }

  Widget _buildExerciseCard(MindfulnessExercise exercise,
      {bool isCompact = false}) {
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
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: typeColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and duration
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getTypeIcon(exercise.type),
                      color: typeColor,
                      size: isCompact ? 16 : 20,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      exercise.durationText,
                      style: GoogleFonts.poppins(
                        fontSize: isCompact ? 10 : 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Title
              Text(
                exercise.title,
                style: GoogleFonts.poppins(
                  fontSize: isCompact ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Description
              if (!isCompact) ...[
                Text(
                  exercise.description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
              ],

              // Difficulty and type
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      exercise.typeDisplayName,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: typeColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    exercise.difficulty == ExerciseDifficulty.beginner
                        ? Icons.circle
                        : exercise.difficulty == ExerciseDifficulty.intermediate
                            ? Icons.radio_button_unchecked
                            : Icons.radio_button_checked,
                    size: 12,
                    color: exercise.difficulty == ExerciseDifficulty.beginner
                        ? Colors.green
                        : exercise.difficulty == ExerciseDifficulty.intermediate
                            ? Colors.orange
                            : Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
