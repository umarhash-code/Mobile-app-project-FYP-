import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/step_data.dart';

class StepCounterService extends ChangeNotifier {
  static const String _stepDataKey = 'step_data';
  static const String _initialStepsKey = 'initial_steps_today';

  StepData _stepData = StepData.initial();
  StreamSubscription<StepCount>? _stepCountStream;
  int _initialStepsToday = 0;
  bool _isListening = false;
  String? _error;

  // Getters
  StepData get stepData => _stepData;
  bool get isListening => _isListening;
  String? get error => _error;

  StepCounterService() {
    _initializeService();
  }

  /// Initialize the step counter service
  Future<void> _initializeService() async {
    await _loadStepData();
    await _checkAndResetDailySteps();
    await startListening();
  }

  /// Load step data from SharedPreferences
  Future<void> _loadStepData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stepDataJson = prefs.getString(_stepDataKey);

      if (stepDataJson != null) {
        final data = jsonDecode(stepDataJson);
        _stepData = StepData.fromJson(data);
      }

      _initialStepsToday = prefs.getInt(_initialStepsKey) ?? 0;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load step data: $e';
      notifyListeners();
    }
  }

  /// Save step data to SharedPreferences
  Future<void> _saveStepData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_stepDataKey, jsonEncode(_stepData.toJson()));
      await prefs.setInt(_initialStepsKey, _initialStepsToday);
    } catch (e) {
      _error = 'Failed to save step data: $e';
      notifyListeners();
    }
  }

  /// Check if we need to reset daily steps (new day)
  Future<void> _checkAndResetDailySteps() async {
    if (!_stepData.isFromToday) {
      // Save yesterday's steps to weekly data
      final yesterday = _stepData.lastUpdated;
      final yesterdayKey =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      final updatedWeeklySteps = Map<String, int>.from(_stepData.weeklySteps);
      if (_stepData.currentSteps > 0) {
        updatedWeeklySteps[yesterdayKey] = _stepData.currentSteps;
      }

      // Clean up old data (keep only last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      updatedWeeklySteps.removeWhere((key, value) {
        final date = DateTime.parse(key);
        return date.isBefore(thirtyDaysAgo);
      });

      // Reset for new day
      _stepData = _stepData.copyWith(
        currentSteps: 0,
        lastUpdated: DateTime.now(),
        weeklySteps: updatedWeeklySteps,
      );

      _initialStepsToday = 0;
      await _saveStepData();
      notifyListeners();
    }
  }

  /// Request necessary permissions
  Future<bool> _requestPermissions() async {
    try {
      final activityPermission = await Permission.activityRecognition.request();
      return activityPermission.isGranted;
    } catch (e) {
      _error = 'Permission error: $e';
      notifyListeners();
      return false;
    }
  }

  /// Start listening to step count changes
  Future<void> startListening() async {
    if (_isListening) return;

    final hasPermission = await _requestPermissions();
    if (!hasPermission) {
      _error = 'Activity recognition permission denied';
      notifyListeners();
      return;
    }

    try {
      _stepCountStream = Pedometer.stepCountStream.listen(
        _onStepCountUpdate,
        onError: _onStepCountError,
      );

      _isListening = true;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to start step counting: $e';
      _isListening = false;
      notifyListeners();
    }
  }

  /// Stop listening to step count changes
  void stopListening() {
    _stepCountStream?.cancel();
    _stepCountStream = null;
    _isListening = false;
    notifyListeners();
  }

  /// Handle step count updates
  void _onStepCountUpdate(StepCount stepCount) async {
    await _checkAndResetDailySteps();

    // If this is the first reading today, set it as baseline
    if (_initialStepsToday == 0) {
      _initialStepsToday = stepCount.steps;
      await _saveStepData();
    }

    // Calculate daily steps (total steps - initial steps for today)
    final dailySteps = (stepCount.steps - _initialStepsToday)
        .clamp(0, double.infinity)
        .toInt();

    _stepData = _stepData.copyWith(
      currentSteps: dailySteps,
      lastUpdated: DateTime.now(),
    );

    await _saveStepData();
    notifyListeners();
  }

  /// Handle step count errors
  void _onStepCountError(error) {
    _error = 'Step counting error: $error';
    _isListening = false;
    notifyListeners();
  }

  /// Update daily goal
  Future<void> updateDailyGoal(int newGoal) async {
    if (newGoal <= 0) return;

    _stepData = _stepData.copyWith(dailyGoal: newGoal);
    await _saveStepData();
    notifyListeners();
  }

  /// Manually add steps (for testing or manual entry)
  Future<void> addSteps(int steps) async {
    if (steps <= 0) return;

    _stepData = _stepData.copyWith(
      currentSteps: _stepData.currentSteps + steps,
      lastUpdated: DateTime.now(),
    );

    await _saveStepData();
    notifyListeners();
  }

  /// Reset today's steps
  Future<void> resetTodaySteps() async {
    _stepData = _stepData.copyWith(
      currentSteps: 0,
      lastUpdated: DateTime.now(),
    );

    // Reset initial steps for today
    _initialStepsToday = 0;

    await _saveStepData();
    notifyListeners();
  }

  /// Get formatted step count
  String getFormattedStepCount() {
    if (_stepData.currentSteps >= 1000) {
      final thousands = (_stepData.currentSteps / 1000).toStringAsFixed(1);
      return '${thousands}k';
    }
    return _stepData.currentSteps.toString();
  }

  /// Get step count for a specific date
  int getStepsForDate(DateTime date) {
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    if (key == StepData.getTodayKey()) {
      return _stepData.currentSteps;
    }

    return _stepData.weeklySteps[key] ?? 0;
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
