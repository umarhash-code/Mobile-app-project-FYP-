enum ExerciseType {
  breathing,
  meditation,
  patience,
  gratitude,
  affirmation,
  visualization,
  bodyRelaxation,
}

enum ExerciseDifficulty {
  beginner,
  intermediate,
  advanced,
}

class MindfulnessExercise {
  final String id;
  final String title;
  final String description;
  final ExerciseType type;
  final ExerciseDifficulty difficulty;
  final int durationMinutes;
  final List<String> instructions;
  final List<String> benefits;
  final bool isGuided;
  final String? imageUrl;

  MindfulnessExercise({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.durationMinutes,
    required this.instructions,
    required this.benefits,
    this.isGuided = true,
    this.imageUrl,
  });

  factory MindfulnessExercise.fromMap(Map<String, dynamic> map) {
    return MindfulnessExercise(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: ExerciseType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => ExerciseType.breathing,
      ),
      difficulty: ExerciseDifficulty.values.firstWhere(
        (e) => e.toString().split('.').last == map['difficulty'],
        orElse: () => ExerciseDifficulty.beginner,
      ),
      durationMinutes: map['durationMinutes'] ?? 5,
      instructions: List<String>.from(map['instructions'] ?? []),
      benefits: List<String>.from(map['benefits'] ?? []),
      isGuided: map['isGuided'] ?? true,
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'difficulty': difficulty.toString().split('.').last,
      'durationMinutes': durationMinutes,
      'instructions': instructions,
      'benefits': benefits,
      'isGuided': isGuided,
      'imageUrl': imageUrl,
    };
  }

  String get typeDisplayName {
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

  String get difficultyDisplayName {
    switch (difficulty) {
      case ExerciseDifficulty.beginner:
        return 'Beginner';
      case ExerciseDifficulty.intermediate:
        return 'Intermediate';
      case ExerciseDifficulty.advanced:
        return 'Advanced';
    }
  }

  bool get hasAudioPrompts => false;

  String get durationText {
    if (durationMinutes < 60) {
      return '${durationMinutes}min';
    } else {
      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;
      return minutes > 0 ? '${hours}h ${minutes}min' : '${hours}h';
    }
  }
}

class ExerciseSession {
  final String id;
  final String exerciseId;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final int? actualDurationMinutes;
  final bool completed;
  final int? rating; // 1-5 stars
  final String? notes;
  final Map<String, dynamic>? metadata;

  ExerciseSession({
    required this.id,
    required this.exerciseId,
    required this.userId,
    required this.startTime,
    this.endTime,
    this.actualDurationMinutes,
    this.completed = false,
    this.rating,
    this.notes,
    this.metadata,
  });

  factory ExerciseSession.fromMap(Map<String, dynamic> map, String documentId) {
    return ExerciseSession(
      id: documentId,
      exerciseId: map['exerciseId'] ?? '',
      userId: map['userId'] ?? '',
      startTime:
          DateTime.parse(map['startTime'] ?? DateTime.now().toIso8601String()),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      actualDurationMinutes: map['actualDurationMinutes'],
      completed: map['completed'] ?? false,
      rating: map['rating'],
      notes: map['notes'],
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'userId': userId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'actualDurationMinutes': actualDurationMinutes,
      'completed': completed,
      'rating': rating,
      'notes': notes,
      'metadata': metadata,
    };
  }

  Duration get actualDuration {
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    return Duration.zero;
  }
}
