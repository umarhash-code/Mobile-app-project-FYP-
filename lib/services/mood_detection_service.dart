import 'package:flutter/foundation.dart';
import '../ai/pure_dart_emotion_ai.dart';

class MoodDetectionResult {
  final String emotion;
  final double confidence;
  final Map<String, double> allProbabilities;
  final String? error;
  final String reasoning;

  MoodDetectionResult({
    required this.emotion,
    required this.confidence,
    required this.allProbabilities,
    this.error,
    this.reasoning = '',
  });

  factory MoodDetectionResult.fromEmotionResult(EmotionResult result) {
    return MoodDetectionResult(
      emotion: result.emotion,
      confidence: result.confidence,
      allProbabilities: result.allEmotions,
      reasoning: result.reasoning,
    );
  }

  factory MoodDetectionResult.error(String error) {
    return MoodDetectionResult(
      emotion: 'neutral',
      confidence: 0.5,
      allProbabilities: {'neutral': 0.5},
      error: error,
    );
  }

  factory MoodDetectionResult.fromJson(Map<String, dynamic> json) {
    return MoodDetectionResult(
      emotion: json['emotion'] ?? 'neutral',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      allProbabilities: Map<String, double>.from(
        json['all_probabilities']?.map(
                (key, value) => MapEntry(key, (value as num).toDouble())) ??
            {},
      ),
      error: json['error'],
      reasoning: json['reasoning'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emotion': emotion,
      'confidence': confidence,
      'all_probabilities': allProbabilities,
      'error': error,
      'reasoning': reasoning,
    };
  }

  // Check if the detection was successful
  bool get isSuccess => error == null;

  // Get mood color based on emotion
  String get moodColor => PureDartEmotionAI.getEmotionColor(emotion);

  // Get mood emoji based on emotion
  String get moodEmoji => PureDartEmotionAI.getEmotionEmoji(emotion);
  // Get human-readable confidence level
  String get confidenceLevel {
    if (confidence >= 0.8) return 'Very High';
    if (confidence >= 0.6) return 'High';
    if (confidence >= 0.4) return 'Medium';
    if (confidence >= 0.2) return 'Low';
    return 'Very Low';
  }

  // Check if mood detection was successful
  bool get hasMoodDetection => error == null;
}

class MoodDetectionService {
  static bool _initialized = false;

  /// Initialize the offline AI service
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await PureDartEmotionAI.initialize();
      _initialized = true;
      debugPrint('✅ Offline AI Mood Detection Service initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize Offline AI service: $e');
    }
  }

  /// Detect mood using pure Dart AI (completely offline)
  Future<MoodDetectionResult> detectMood(String text) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      if (text.trim().isEmpty) {
        return MoodDetectionResult.error('Text is empty');
      }

      // Use pure Dart AI - NO API calls, NO internet needed
      final result = await PureDartEmotionAI.detectEmotion(text);

      debugPrint(
          '🧠 Offline AI detected: ${result.emotion} (${(result.confidence * 100).toStringAsFixed(0)}%)');

      return MoodDetectionResult.fromEmotionResult(result);
    } catch (e) {
      debugPrint('❌ Offline mood detection error: $e');
      return MoodDetectionResult.error('Detection failed: $e');
    }
  }

  /// Detect moods for multiple texts (batch processing)
  Future<List<MoodDetectionResult>> detectMoodsBatch(List<String> texts) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      final results = await PureDartEmotionAI.detectEmotionsBatch(texts);
      return results
          .map((r) => MoodDetectionResult.fromEmotionResult(r))
          .toList();
    } catch (e) {
      debugPrint('❌ Batch mood detection error: $e');
      return texts
          .map((t) => MoodDetectionResult.error('Batch detection failed'))
          .toList();
    }
  }

  /// Get mood statistics for a list of results
  Map<String, double> getMoodStatistics(List<MoodDetectionResult> results) {
    if (results.isEmpty) return {};

    final emotionCounts = <String, int>{};
    for (final result in results) {
      if (result.hasMoodDetection) {
        emotionCounts[result.emotion] =
            (emotionCounts[result.emotion] ?? 0) + 1;
      }
    }

    final total = emotionCounts.values.fold(0, (sum, count) => sum + count);
    if (total == 0) return {};

    return emotionCounts
        .map((emotion, count) => MapEntry(emotion, count / total));
  }

  /// Check if service is ready
  static bool get isInitialized =>
      _initialized && PureDartEmotionAI.isInitialized;

  /// Get supported emotions
  static List<String> get supportedEmotions =>
      PureDartEmotionAI.supportedEmotions;

  /// Test the AI with sample texts
  Future<void> runDiagnostics() async {
    debugPrint('🔧 Running Offline AI diagnostics...');

    final testTexts = [
      'I am so happy and excited about this!',
      'I feel really sad and disappointed today.',
      'This makes me absolutely furious and angry!',
      'I am scared and worried about the exam.',
      'I love spending time with my family.',
      'Wow, this is such an incredible surprise!',
      'I went to work and had a meeting.',
    ];

    for (final text in testTexts) {
      final result = await detectMood(text);
      debugPrint(
          '📝 "$text" → ${result.emotion} (${(result.confidence * 100).toStringAsFixed(0)}%)');
    }

    debugPrint('✅ Offline AI diagnostics completed');
  }

  /// Dispose resources (not needed for offline AI, but kept for compatibility)
  void dispose() {
    // Nothing to dispose for offline AI
    debugPrint('🗑️ MoodDetectionService disposed');
  }

  /// Analyze journal entry content and return mood with confidence
  Future<MoodDetectionResult> analyzeJournalEntry(
      String title, String content) async {
    // Combine title and content for analysis
    final combinedText = '$title. $content'.trim();

    if (combinedText.isEmpty || combinedText == '.') {
      return MoodDetectionResult.error('No content to analyze');
    }

    return await detectMood(combinedText);
  }
}
