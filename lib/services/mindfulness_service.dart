import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mindfulness_exercise.dart';

class MindfulnessService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Collection references
  CollectionReference get _sessionsCollection =>
      _firestore.collection('exercise_sessions');

  // Get all mindfulness exercises
  Future<List<MindfulnessExercise>> getAllExercises() async {
    try {
      // Return predefined exercises for now
      return _getPredefinedExercises();
    } catch (e) {
      // Debug: Error getting exercises: $e
      return _getPredefinedExercises();
    }
  }

  // Get exercises by type
  Future<List<MindfulnessExercise>> getExercisesByType(
      ExerciseType type) async {
    final allExercises = await getAllExercises();
    return allExercises.where((exercise) => exercise.type == type).toList();
  }

  // Get exercises by difficulty
  Future<List<MindfulnessExercise>> getExercisesByDifficulty(
      ExerciseDifficulty difficulty) async {
    final allExercises = await getAllExercises();
    return allExercises
        .where((exercise) => exercise.difficulty == difficulty)
        .toList();
  }

  // Start an exercise session
  Future<String> startExerciseSession(String exerciseId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final session = ExerciseSession(
        id: '', // Will be set by Firestore
        exerciseId: exerciseId,
        userId: currentUserId!,
        startTime: DateTime.now(),
        completed: false,
      );

      DocumentReference docRef = await _sessionsCollection.add(session.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to start session: $e');
    }
  }

  // Complete an exercise session
  Future<void> completeExerciseSession({
    required String sessionId,
    int? rating,
    String? notes,
  }) async {
    try {
      await _sessionsCollection.doc(sessionId).update({
        'endTime': Timestamp.fromDate(DateTime.now()),
        'completed': true,
        'rating': rating,
        'notes': notes,
      });
    } catch (e) {
      throw Exception('Failed to complete session: $e');
    }
  }

  // Get user's exercise sessions
  Future<List<ExerciseSession>> getUserSessions() async {
    try {
      if (currentUserId == null) return [];

      final QuerySnapshot querySnapshot = await _sessionsCollection
          .where('userId', isEqualTo: currentUserId)
          .orderBy('startTime', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ExerciseSession.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get recent sessions with limit
  Future<List<ExerciseSession>> getRecentSessions({int limit = 10}) async {
    try {
      if (currentUserId == null) return [];

      final QuerySnapshot querySnapshot = await _sessionsCollection
          .where('userId', isEqualTo: currentUserId)
          .orderBy('startTime', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => ExerciseSession.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get sessions for today
  Future<List<ExerciseSession>> getTodaySessions() async {
    try {
      if (currentUserId == null) return [];

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final QuerySnapshot querySnapshot = await _sessionsCollection
          .where('userId', isEqualTo: currentUserId)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('startTime', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ExerciseSession.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get exercise statistics
  Future<Map<String, dynamic>> getExerciseStats() async {
    try {
      final sessions = await getUserSessions();
      final completedSessions = sessions.where((s) => s.completed).toList();

      final totalSessions = completedSessions.length;
      final totalMinutes = completedSessions.fold<int>(
          0, (total, session) => total + (session.actualDurationMinutes ?? 0));

      final averageRating = completedSessions.isNotEmpty
          ? completedSessions
                  .where((s) => s.rating != null)
                  .fold<double>(0, (total, session) => total + session.rating!) /
              completedSessions.where((s) => s.rating != null).length
          : 0.0;

      // Calculate streak (consecutive days with at least one session)
      int currentStreak = 0;
      // Simple implementation - count consecutive days from today backwards
      final today = DateTime.now();
      for (int i = 0; i < 30; i++) {
        final checkDate = today.subtract(Duration(days: i));
        final hasSessionOnDate = completedSessions.any((session) {
          final sessionDate = session.startTime;
          return sessionDate.year == checkDate.year &&
                 sessionDate.month == checkDate.month &&
                 sessionDate.day == checkDate.day;
        });
        if (hasSessionOnDate) {
          currentStreak++;
        } else if (i > 0) { // Don't break on first day (today) if no session
          break;
        }
      }

      return {
        'totalSessions': totalSessions,
        'totalMinutes': totalMinutes,
        'averageRating': averageRating,
        'currentStreak': currentStreak,
        'completedToday':
            (await getTodaySessions()).where((s) => s.completed).length,
      };
    } catch (e) {
      // Error getting stats - return default values
      return {
        'totalSessions': 0,
        'totalMinutes': 0,
        'averageRating': 0.0,
        'currentStreak': 0,
        'completedToday': 0,
      };
    }
  }

  // Get recommended exercises based on user's history
  Future<List<MindfulnessExercise>> getRecommendedExercises() async {
    try {
      final allExercises = await getAllExercises();
      final sessions = await getUserSessions();

      if (sessions.isEmpty) {
        // Return beginner exercises for new users
        return allExercises
            .where((e) => e.difficulty == ExerciseDifficulty.beginner)
            .take(3)
            .toList();
      }

      // Find exercises the user hasn't tried recently
      final recentExerciseIds =
          sessions.take(10).map((s) => s.exerciseId).toSet();
      final untriedExercises =
          allExercises.where((e) => !recentExerciseIds.contains(e.id)).toList();

      if (untriedExercises.isNotEmpty) {
        return untriedExercises.take(3).toList();
      }

      // Return popular exercises
      return allExercises.take(3).toList();
    } catch (e) {
      // Error getting recommendations - return default exercises
      final allExercises = await getAllExercises();
      return allExercises.take(3).toList();
    }
  }

  // Predefined exercises
  List<MindfulnessExercise> _getPredefinedExercises() {
    return [
      // Breathing Exercises
      MindfulnessExercise(
        id: 'breathing_4_7_8',
        title: '4-7-8 Breathing',
        description:
            'A simple yet powerful breathing technique to calm your mind and reduce stress.',
        type: ExerciseType.breathing,
        difficulty: ExerciseDifficulty.beginner,
        durationMinutes: 5,
        instructions: [
          'Sit comfortably with your back straight',
          'Exhale completely through your mouth',
          'Close your mouth and inhale through your nose for 4 counts',
          'Hold your breath for 7 counts',
          'Exhale through your mouth for 8 counts',
          'Repeat this cycle 4 times'
        ],
        benefits: [
          'Reduces anxiety',
          'Improves sleep quality',
          'Promotes deep relaxation'
        ],
      ),

      MindfulnessExercise(
        id: 'box_breathing',
        title: 'Box Breathing',
        description:
            'A structured breathing pattern that helps balance your nervous system.',
        type: ExerciseType.breathing,
        difficulty: ExerciseDifficulty.beginner,
        durationMinutes: 8,
        instructions: [
          'Sit in a comfortable position',
          'Inhale for 4 counts',
          'Hold for 4 counts',
          'Exhale for 4 counts',
          'Hold empty for 4 counts',
          'Visualize drawing a square as you breathe',
          'Continue for 8 minutes'
        ],
        benefits: [
          'Improves focus',
          'Reduces stress',
          'Enhances mental clarity'
        ],
      ),

      // Patience Exercises
      MindfulnessExercise(
        id: 'patience_waiting',
        title: 'Mindful Waiting',
        description:
            'Transform waiting time into an opportunity for mindfulness and patience.',
        type: ExerciseType.patience,
        difficulty: ExerciseDifficulty.beginner,
        durationMinutes: 10,
        instructions: [
          'When you find yourself waiting, pause and breathe',
          'Notice your immediate reaction to waiting',
          'Accept the present moment without resistance',
          'Focus on your breathing',
          'Observe your surroundings mindfully',
          'Practice gratitude for this pause in your day',
          'Let go of the need to rush'
        ],
        benefits: [
          'Builds patience',
          'Reduces frustration',
          'Increases mindfulness'
        ],
      ),

      // Meditation Exercises
      MindfulnessExercise(
        id: 'body_scan_meditation',
        title: 'Body Scan Meditation',
        description:
            'A comprehensive practice to connect with your body and release tension.',
        type: ExerciseType.meditation,
        difficulty: ExerciseDifficulty.intermediate,
        durationMinutes: 20,
        instructions: [
          'Lie down comfortably on your back',
          'Close your eyes and take three deep breaths',
          'Start at the top of your head',
          'Slowly scan down through each part of your body',
          'Notice sensations without judgment',
          'Send breath and relaxation to tense areas',
          'End at your toes, feeling completely relaxed'
        ],
        benefits: [
          'Reduces physical tension',
          'Increases body awareness',
          'Promotes relaxation'
        ],
      ),

      // Gratitude Exercises
      MindfulnessExercise(
        id: 'gratitude_three_things',
        title: 'Three Good Things',
        description:
            'Focus on positive experiences to cultivate gratitude and joy.',
        type: ExerciseType.gratitude,
        difficulty: ExerciseDifficulty.beginner,
        durationMinutes: 10,
        instructions: [
          'Sit quietly and breathe deeply',
          'Think of three good things from your day',
          'For each thing, reflect on why it was meaningful',
          'Feel the positive emotions in your body',
          'Express gratitude for these experiences',
          'Let the feeling of gratitude fill your heart',
          'Carry this appreciation with you'
        ],
        benefits: [
          'Increases happiness',
          'Boosts positive emotions',
          'Improves life satisfaction'
        ],
      ),
    ];
  }
}