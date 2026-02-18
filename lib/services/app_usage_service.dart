import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Real-time app usage tracking service
class AppUsageService extends ChangeNotifier {
  static final AppUsageService _instance = AppUsageService._internal();
  factory AppUsageService() => _instance;
  AppUsageService._internal();

  // Usage tracking variables
  DateTime? _sessionStartTime;
  Duration _totalDailyUsage = Duration.zero;
  Duration _currentSessionDuration = Duration.zero;
  Timer? _usageTimer;
  List<UsageSession> _todaySessions = [];
  Map<String, Duration> _weeklyUsage = {};

  // Preferences keys
  static const String _lastUsageDateKey = 'last_usage_date';
  static const String _dailyUsageKey = 'daily_usage_seconds';
  static const String _weeklyUsageKey = 'weekly_usage_data';
  static const String _sessionsKey = 'today_sessions';

  // Getters for UI
  Duration get totalDailyUsage => _totalDailyUsage;
  Duration get currentSessionDuration => _currentSessionDuration;
  List<UsageSession> get todaySessions => List.unmodifiable(_todaySessions);
  Map<String, Duration> get weeklyUsage => Map.unmodifiable(_weeklyUsage);
  bool get isSessionActive => _sessionStartTime != null;

  // Statistics
  int get totalSessions => _todaySessions.length;
  Duration get averageSessionDuration {
    if (_todaySessions.isEmpty) return Duration.zero;
    final totalSeconds = _todaySessions.fold<int>(
        0, (sum, session) => sum + session.duration.inSeconds);
    return Duration(seconds: (totalSeconds / _todaySessions.length).round());
  }

  Duration get longestSessionToday {
    if (_todaySessions.isEmpty) return Duration.zero;
    return _todaySessions
        .map((s) => s.duration)
        .reduce((a, b) => a > b ? a : b);
  }

  /// Initialize the service and load saved data
  Future<void> initialize() async {
    try {
      await _loadUsageData();
      _startUsageTracking();
      debugPrint('🚀 AppUsageService initialized');
    } catch (e) {
      debugPrint('❌ AppUsageService initialization failed: $e');
    }
  }

  /// Start tracking app usage
  void _startUsageTracking() {
    if (_sessionStartTime == null) {
      _sessionStartTime = DateTime.now();
      _currentSessionDuration = Duration.zero;

      // Start timer to update usage every second
      _usageTimer?.cancel();
      _usageTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _updateCurrentSession();
      });

      debugPrint('📱 Started app usage session at $_sessionStartTime');
    }
  }

  /// Stop tracking app usage
  void _stopUsageTracking() {
    if (_sessionStartTime != null) {
      final sessionDuration = DateTime.now().difference(_sessionStartTime!);

      // Add session to today's sessions
      _todaySessions.add(UsageSession(
        startTime: _sessionStartTime!,
        endTime: DateTime.now(),
        duration: sessionDuration,
      ));

      // Update total daily usage
      _totalDailyUsage += sessionDuration;

      _usageTimer?.cancel();
      _sessionStartTime = null;
      _currentSessionDuration = Duration.zero;

      // Save data
      _saveUsageData();

      debugPrint(
          '⏹️ Stopped app usage session. Duration: ${_formatDuration(sessionDuration)}');
      notifyListeners();
    }
  }

  /// Update current session duration
  void _updateCurrentSession() {
    if (_sessionStartTime != null) {
      _currentSessionDuration = DateTime.now().difference(_sessionStartTime!);
      notifyListeners();
    }
  }

  /// Handle app lifecycle changes
  void handleAppLifecycleChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _startUsageTracking();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _stopUsageTracking();
        break;
    }
  }

  /// Load usage data from SharedPreferences
  Future<void> _loadUsageData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = _dateToString(today);
    final lastUsageDate = prefs.getString(_lastUsageDateKey);

    // Reset daily data if it's a new day
    if (lastUsageDate != todayString) {
      await _resetDailyData(prefs, todayString);
    } else {
      // Load today's usage
      final dailySeconds = prefs.getInt(_dailyUsageKey) ?? 0;
      _totalDailyUsage = Duration(seconds: dailySeconds);

      // Load today's sessions
      final sessionsJson = prefs.getString(_sessionsKey);
      if (sessionsJson != null) {
        _loadSessionsFromJson(sessionsJson);
      }
    }

    // Load weekly usage
    _loadWeeklyUsage(prefs);
  }

  /// Reset daily data for new day
  Future<void> _resetDailyData(
      SharedPreferences prefs, String todayString) async {
    // Save yesterday's data to weekly usage before resetting
    if (_totalDailyUsage.inSeconds > 0) {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      _weeklyUsage[_dateToString(yesterday)] = _totalDailyUsage;
      await _saveWeeklyUsage(prefs);
    }

    // Reset daily counters
    _totalDailyUsage = Duration.zero;
    _todaySessions.clear();

    await prefs.setString(_lastUsageDateKey, todayString);
    await prefs.setInt(_dailyUsageKey, 0);
    await prefs.remove(_sessionsKey);
  }

  /// Load sessions from JSON
  void _loadSessionsFromJson(String json) {
    try {
      final List<dynamic> sessionsList = jsonDecode(json);
      _todaySessions = sessionsList.map((sessionData) {
        return UsageSession(
          startTime: DateTime.parse(sessionData['startTime']),
          endTime: DateTime.parse(sessionData['endTime']),
          duration: Duration(seconds: sessionData['duration']),
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Error loading sessions: $e');
      _todaySessions.clear();
    }
  }

  /// Load weekly usage data
  void _loadWeeklyUsage(SharedPreferences prefs) {
    final weeklyJson = prefs.getString(_weeklyUsageKey);
    if (weeklyJson != null) {
      try {
        final Map<String, dynamic> weeklyData = jsonDecode(weeklyJson);
        _weeklyUsage = weeklyData.map(
            (key, value) => MapEntry(key, Duration(seconds: value as int)));
      } catch (e) {
        debugPrint('❌ Error loading weekly usage: $e');
        _weeklyUsage.clear();
      }
    }
  }

  /// Save usage data to SharedPreferences
  Future<void> _saveUsageData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save daily usage
      await prefs.setInt(_dailyUsageKey, _totalDailyUsage.inSeconds);

      // Save today's sessions
      final sessionsJson = jsonEncode(_todaySessions
          .map((session) => {
                'startTime': session.startTime.toIso8601String(),
                'endTime': session.endTime.toIso8601String(),
                'duration': session.duration.inSeconds,
              })
          .toList());
      await prefs.setString(_sessionsKey, sessionsJson);

      // Save weekly usage
      await _saveWeeklyUsage(prefs);
    } catch (e) {
      debugPrint('❌ Error saving usage data: $e');
    }
  }

  /// Save weekly usage data
  Future<void> _saveWeeklyUsage(SharedPreferences prefs) async {
    final weeklyJson = jsonEncode(
        _weeklyUsage.map((key, value) => MapEntry(key, value.inSeconds)));
    await prefs.setString(_weeklyUsageKey, weeklyJson);
  }

  /// Get usage for last 7 days
  Map<String, Duration> getLast7DaysUsage() {
    final result = <String, Duration>{};
    final today = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateString = _dateToString(date);

      if (i == 0) {
        // Today's usage
        result[dateString] = _totalDailyUsage + _currentSessionDuration;
      } else {
        // Previous days
        result[dateString] = _weeklyUsage[dateString] ?? Duration.zero;
      }
    }

    return result;
  }

  /// Get formatted usage statistics
  String getUsageStats() {
    final buffer = StringBuffer();
    buffer.writeln('📱 App Usage Statistics');
    buffer.writeln(
        'Today: ${_formatDuration(_totalDailyUsage + _currentSessionDuration)}');
    buffer.writeln(
        'Current Session: ${_formatDuration(_currentSessionDuration)}');
    buffer.writeln('Total Sessions Today: $totalSessions');

    if (_todaySessions.isNotEmpty) {
      buffer.writeln(
          'Average Session: ${_formatDuration(averageSessionDuration)}');
      buffer
          .writeln('Longest Session: ${_formatDuration(longestSessionToday)}');
    }

    return buffer.toString();
  }

  /// Format duration for display
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

  /// Convert date to string
  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Dispose resources
  @override
  void dispose() {
    _usageTimer?.cancel();
    _stopUsageTracking();
    super.dispose();
  }
}

/// Represents a single app usage session
class UsageSession {
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;

  UsageSession({
    required this.startTime,
    required this.endTime,
    required this.duration,
  });

  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String get timeRange {
    final startFormatted =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endFormatted =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$startFormatted - $endFormatted';
  }
}
