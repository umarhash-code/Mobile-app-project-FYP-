class StepData {
  final int currentSteps;
  final int dailyGoal;
  final DateTime lastUpdated;
  final Map<String, int> weeklySteps; // Format: "2025-11-03" -> steps
  
  const StepData({
    required this.currentSteps,
    required this.dailyGoal,
    required this.lastUpdated,
    required this.weeklySteps,
  });

  // Default constructor for initial state
  factory StepData.initial() {
    return StepData(
      currentSteps: 0,
      dailyGoal: 10000, // Default 10k steps goal
      lastUpdated: DateTime.now(),
      weeklySteps: {},
    );
  }

  // Create from JSON (for SharedPreferences)
  factory StepData.fromJson(Map<String, dynamic> json) {
    return StepData(
      currentSteps: json['currentSteps'] ?? 0,
      dailyGoal: json['dailyGoal'] ?? 10000,
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
      weeklySteps: Map<String, int>.from(json['weeklySteps'] ?? {}),
    );
  }

  // Convert to JSON (for SharedPreferences)
  Map<String, dynamic> toJson() {
    return {
      'currentSteps': currentSteps,
      'dailyGoal': dailyGoal,
      'lastUpdated': lastUpdated.toIso8601String(),
      'weeklySteps': weeklySteps,
    };
  }

  // Copy with new values
  StepData copyWith({
    int? currentSteps,
    int? dailyGoal,
    DateTime? lastUpdated,
    Map<String, int>? weeklySteps,
  }) {
    return StepData(
      currentSteps: currentSteps ?? this.currentSteps,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      weeklySteps: weeklySteps ?? this.weeklySteps,
    );
  }

  // Helper methods
  double get progressPercentage {
    if (dailyGoal == 0) return 0.0;
    return (currentSteps / dailyGoal).clamp(0.0, 1.0);
  }

  bool get goalAchieved => currentSteps >= dailyGoal;

  int get remainingSteps => (dailyGoal - currentSteps).clamp(0, dailyGoal);

  String get progressText {
    if (goalAchieved) {
      return 'Goal achieved! 🎉';
    } else if (currentSteps > 0) {
      return '$remainingSteps steps to go';
    } else {
      return 'Start walking!';
    }
  }

  // Get today's date key
  static String getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // Check if data is from today
  bool get isFromToday {
    final today = getTodayKey();
    final lastUpdatedKey = '${lastUpdated.year}-${lastUpdated.month.toString().padLeft(2, '0')}-${lastUpdated.day.toString().padLeft(2, '0')}';
    return today == lastUpdatedKey;
  }

  // Get weekly average
  double get weeklyAverage {
    if (weeklySteps.isEmpty) return 0.0;
    final total = weeklySteps.values.fold(0, (sum, steps) => sum + steps);
    return total / weeklySteps.length;
  }

  // Get this week's steps (last 7 days)
  Map<String, int> get thisWeekSteps {
    final Map<String, int> thisWeek = {};
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      thisWeek[key] = weeklySteps[key] ?? 0;
    }
    
    return thisWeek;
  }
}