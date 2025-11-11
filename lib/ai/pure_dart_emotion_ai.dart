/// Pure Dart AI Emotion Detection
/// No external dependencies - runs completely offline
library emotion_ai;

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class EmotionResult {
  final String emotion;
  final double confidence;
  final Map<String, double> allEmotions;
  final String reasoning;

  EmotionResult({
    required this.emotion,
    required this.confidence,
    required this.allEmotions,
    required this.reasoning,
  });

  Map<String, dynamic> toJson() => {
        'emotion': emotion,
        'confidence': confidence,
        'allEmotions': allEmotions,
        'reasoning': reasoning,
      };
}

class PureDartEmotionAI {
  static const List<String> _emotions = [
    'happy',
    'sad',
    'angry',
    'fear',
    'love',
    'surprise',
    'neutral'
  ];

  static Map<String, dynamic>? _emotionWeights;
  static bool _initialized = false;
  static final Map<String, int> _emotionLearningCounts = {};
  static final Map<String, List<String>> _emotionContextMemory = {};
  static final Map<String, double> _userEmotionPatterns = {};

  /// Initialize the AI with emotion weights
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      final weightsJson =
          await rootBundle.loadString('assets/emotion_weights.json');
      _emotionWeights = json.decode(weightsJson);
      _initialized = true;
      // Successfully loaded emotion weights
    } catch (e) {
      // Failed to load from primary path, try alternative
      try {
        final weightsJson2 =
            await rootBundle.loadString('lib/ai/emotion_weights.json');
        _emotionWeights = json.decode(weightsJson2);
        _initialized = true;
        // Successfully loaded with alternative path
      } catch (e2) {
        // Both paths failed, use fallback
        _initializeFallbackWeights();
      }
    }
  }

  static void _initializeFallbackWeights() {
    // Simplified fallback weights
    _emotionWeights = {
      'happy': {
        'keywords': {
          'happy': 2.0,
          'joy': 2.0,
          'great': 1.8,
          'amazing': 1.9,
          'wonderful': 1.9,
          'excellent': 1.8,
          'fantastic': 1.9,
          'awesome': 1.8,
          'love': 1.7,
          'good': 1.5,
          'excited': 1.8,
          'cheerful': 1.8,
          'delighted': 1.9,
          'pleased': 1.6,
          'glad': 1.7,
          'smile': 1.6,
          'laugh': 1.7,
          'fun': 1.5,
          'best': 1.6,
          'perfect': 1.8
        },
        'patterns': ['😊', '😀', '😁', '🎉', '❤️', '!'],
        'intensifiers': 1.3
      },
      'sad': {
        'keywords': {
          'sad': 2.0,
          'crying': 2.0,
          'depressed': 2.0,
          'down': 1.7,
          'upset': 1.8,
          'disappointed': 1.8,
          'hurt': 1.7,
          'lonely': 1.8,
          'blue': 1.5,
          'terrible': 1.9,
          'awful': 1.8,
          'miserable': 1.9,
          'heartbroken': 2.0,
          'devastated': 2.0,
          'grief': 2.0,
          'sorrow': 1.9,
          'despair': 2.0,
          'cry': 1.8,
          'tears': 1.7,
          'gloomy': 1.6
        },
        'patterns': ['😢', '😭', '💔', '😞', ':('],
        'intensifiers': 1.4
      },
      'angry': {
        'keywords': {
          'angry': 2.0,
          'mad': 1.9,
          'furious': 2.0,
          'annoyed': 1.7,
          'irritated': 1.7,
          'frustrated': 1.8,
          'hate': 1.9,
          'rage': 2.0,
          'pissed': 1.9,
          'outraged': 2.0,
          'livid': 2.0,
          'enraged': 2.0,
          'irate': 1.9,
          'bothered': 1.6,
          'infuriated': 2.0
        },
        'patterns': ['😠', '😡', '🤬', '!', 'damn'],
        'intensifiers': 1.4
      },
      'fear': {
        'keywords': {
          'scared': 1.9,
          'afraid': 1.8,
          'terrified': 2.0,
          'anxious': 1.8,
          'worried': 1.7,
          'nervous': 1.6,
          'frightened': 1.9,
          'panic': 2.0,
          'stress': 1.7,
          'concern': 1.5,
          'dread': 1.9,
          'horror': 2.0,
          'alarm': 1.8,
          'tension': 1.6,
          'uneasy': 1.6
        },
        'patterns': ['😰', '😨', '😱', '?', 'help'],
        'intensifiers': 1.2
      },
      'love': {
        'keywords': {
          'love': 2.0,
          'adore': 1.8,
          'cherish': 1.7,
          'romantic': 1.8,
          'affection': 1.7,
          'dear': 1.6,
          'beloved': 1.9,
          'caring': 1.6,
          'tender': 1.7,
          'passion': 1.8,
          'heart': 1.5,
          'kiss': 1.7,
          'hug': 1.6,
          'embrace': 1.7,
          'romance': 1.8
        },
        'patterns': ['❤️', '💕', '💖', '😘', '🥰'],
        'intensifiers': 1.3
      },
      'surprise': {
        'keywords': {
          'surprised': 1.8,
          'shocked': 1.9,
          'wow': 1.7,
          'amazing': 1.6,
          'incredible': 1.6
        },
        'patterns': ['!', 'wow'],
        'intensifiers': 1.2
      },
      'neutral': {
        'keywords': {
          'okay': 1.5,
          'fine': 1.4,
          'normal': 1.6,
          'work': 1.3,
          'day': 1.1
        },
        'patterns': ['.'],
        'intensifiers': 1.0
      }
    };
    _initialized = true;
    // Fallback emotion weights initialized
  }

  /// Advanced emotion detection method with intelligent analysis
  static Future<EmotionResult> detectEmotion(String text) async {
    if (!_initialized) {
      await initialize();
    }

    if (text.trim().isEmpty) {
      return EmotionResult(
        emotion: 'neutral',
        confidence: 0.5,
        allEmotions: {'neutral': 0.5},
        reasoning: 'Empty text provided',
      );
    }

    // Intelligent text analysis with multiple layers
    final processedText = _preprocessText(text);

    // Layer 1: Semantic Analysis - Understanding meaning and context
    final semanticScores = _performSemanticAnalysis(processedText, text);

    // Layer 2: Sentiment Analysis - Understanding emotional tone
    final sentimentScores = _performSentimentAnalysis(processedText);

    // Layer 3: Context Analysis - Understanding situational context
    final contextScores = _performContextualAnalysis(processedText, text);

    // Layer 4: Pattern Recognition - Understanding language patterns
    final patternScores = _performPatternAnalysis(processedText);

    // Intelligent fusion of all analysis layers
    final fusedScores = _intelligentScoreFusion(
        semanticScores, sentimentScores, contextScores, patternScores);

    // Apply machine learning-based confidence calculation
    final confidenceScores =
        _calculateIntelligentConfidence(fusedScores, processedText);

    // Normalize and select dominant emotion intelligently
    final probabilities = _normalizeToProbabilitiesAdvanced(confidenceScores);
    final dominantEmotion =
        _selectDominantEmotionIntelligently(probabilities, processedText);

    // Learn from this detection for continuous improvement
    _learnFromDetection(
        processedText, dominantEmotion.key, dominantEmotion.value);

    // Generate intelligent reasoning based on analysis
    final reasoning = _generateIntelligentReasoning(
        processedText, dominantEmotion.key, semanticScores, contextScores);

    return EmotionResult(
      emotion: dominantEmotion.key,
      confidence: dominantEmotion.value,
      allEmotions: probabilities,
      reasoning: reasoning,
    );
  }

  static String _preprocessText(String text) {
    return text
        .toLowerCase()
        .replaceAll(
            RegExp(r'[^a-zA-Z0-9\s!?.,❤️💕😊😄🎉😢😭💔😠😡🤬😰😨😱😲🤯😐]'),
            ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Extract words from text for analysis
  static List<String> _extractWords(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty && word.length > 1)
        .toList();
  }

  static Map<String, double> _calculateEmotionScores(
      String processedText, String originalText) {
    final scores = <String, double>{};

    for (final emotion in _emotions) {
      scores[emotion] = 0.0;

      final emotionData = _emotionWeights![emotion];
      final keywords = Map<String, double>.from(emotionData['keywords']);
      final patterns = List<String>.from(emotionData['patterns']);

      // Score based on keywords
      for (final entry in keywords.entries) {
        final keyword = entry.key;
        final weight = entry.value;

        if (processedText.contains(' $keyword ') ||
            processedText.startsWith('$keyword ') ||
            processedText.endsWith(' $keyword') ||
            processedText == keyword) {
          scores[emotion] = scores[emotion]! + weight;
        } else if (processedText.contains(keyword)) {
          scores[emotion] = scores[emotion]! + (weight * 0.7); // Partial match
        }
      }

      // Score based on patterns
      for (final pattern in patterns) {
        if (originalText.contains(pattern)) {
          scores[emotion] = scores[emotion]! + 0.5;
        }
      }

      // Apply intensifiers with smart detection
      final intensifierBoost =
          _calculateIntensifierBoost(processedText, emotionData);
      scores[emotion] = scores[emotion]! * intensifierBoost;

      // Special scoring rules
      scores[emotion] =
          scores[emotion]! + _applySpecialRules(processedText, emotion);
    }

    return scores;
  }

  static double _calculateIntensifierBoost(
      String text, Map<String, dynamic> emotionData) {
    // Handle intensifiers - could be single number or object
    double baseMultiplier = 1.0; // default (no boost)
    final intensifierData = emotionData['intensifiers'];

    if (intensifierData is double || intensifierData is int) {
      // Old structure with single multiplier
      if (_hasIntensifiers(text)) {
        baseMultiplier = intensifierData.toDouble();
      }
    } else if (intensifierData is Map) {
      // New JSON structure with intensifier objects
      final intensifierMap = Map<String, double>.from(intensifierData);
      double maxBoost = 1.0;

      for (final entry in intensifierMap.entries) {
        final intensifierWord = entry.key;
        final multiplier = entry.value;

        if (text.contains(' $intensifierWord ') ||
            text.startsWith('$intensifierWord ') ||
            text.endsWith(' $intensifierWord') ||
            text == intensifierWord) {
          maxBoost = math.max(maxBoost, multiplier);
        }
      }
      baseMultiplier = maxBoost;
    }

    return baseMultiplier;
  }

  static bool _hasIntensifiers(String text) {
    const intensifiers = [
      'very',
      'extremely',
      'absolutely',
      'incredibly',
      'so',
      'really',
      'truly'
    ];
    return intensifiers.any((intensifier) => text.contains(intensifier));
  }

  static double _applySpecialRules(String text, String emotion) {
    double bonus = 0.0;

    // Punctuation rules
    if (emotion == 'happy' && text.contains('!')) bonus += 0.3;
    if (emotion == 'angry' && text.contains('!')) bonus += 0.4;
    if (emotion == 'surprise' && text.contains('!')) bonus += 0.3;
    if (emotion == 'fear' && text.contains('?')) bonus += 0.2;

    // Negation handling
    if (text.contains('not ') ||
        text.contains("don't") ||
        text.contains("can't")) {
      if (emotion == 'happy') bonus -= 0.5;
      if (emotion == 'love') bonus -= 0.3;
      if (emotion == 'sad') bonus += 0.2;
    }

    // Length and complexity
    final wordCount = text.split(' ').length;
    if (wordCount > 10) {
      bonus += 0.1; // Longer texts get slight boost for detected emotion
    }

    return bonus;
  }

  /// Batch processing for multiple texts
  static Future<List<EmotionResult>> detectEmotionsBatch(
      List<String> texts) async {
    final results = <EmotionResult>[];

    for (final text in texts) {
      final result = await detectEmotion(text);
      results.add(result);
    }

    return results;
  }

  /// Get emotion emoji
  static String getEmotionEmoji(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😢';
      case 'angry':
        return '😠';
      case 'fear':
        return '😰';
      case 'love':
        return '❤️';
      case 'surprise':
        return '😲';
      case 'neutral':
        return '😐';
      default:
        return '🤔';
    }
  }

  /// Get emotion color
  static String getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return '#FFD700'; // Gold
      case 'sad':
        return '#4169E1'; // Royal Blue
      case 'angry':
        return '#DC143C'; // Crimson
      case 'fear':
        return '#9370DB'; // Medium Purple
      case 'love':
        return '#FF69B4'; // Hot Pink
      case 'surprise':
        return '#FF8C00'; // Dark Orange
      case 'neutral':
        return '#708090'; // Slate Gray
      default:
        return '#808080'; // Gray
    }
  }

  // ========== ADVANCED LEARNING METHODS ==========

  /// Apply context learning from previous detections
  static Map<String, double> _applyContextLearning(
      String text, Map<String, double> scores) {
    final contextScores = Map<String, double>.from(scores);

    // Apply context memory learning
    for (final emotion in _emotions) {
      final contexts = _emotionContextMemory[emotion] ?? [];
      for (final context in contexts) {
        if (text.contains(context) ||
            context.contains(text.substring(0, math.min(text.length, 10)))) {
          contextScores[emotion] = (contextScores[emotion] ?? 0) * 1.2;
          // Context boost applied
        }
      }
    }

    return contextScores;
  }

  /// Apply user-specific pattern learning
  static Map<String, double> _applyUserPatternLearning(
      Map<String, double> scores) {
    final learnedScores = Map<String, double>.from(scores);

    // Apply user emotional patterns
    for (final entry in _userEmotionPatterns.entries) {
      final emotion = entry.key;
      final userPattern = entry.value;

      if (learnedScores.containsKey(emotion)) {
        // Boost emotions the user frequently experiences
        learnedScores[emotion] =
            (learnedScores[emotion] ?? 0) * (1 + userPattern * 0.3);
        // User pattern boost applied
      }
    }

    return learnedScores;
  }

  /// Apply advanced analysis with temporal patterns
  static Map<String, double> _applyAdvancedAnalysis(
      Map<String, double> scores, String text) {
    final enhancedScores = Map<String, double>.from(scores);

    // Apply my enhanced AI analysis methods
    final cleanText = _preprocessText(text);
    final sentences = _extractSentences(cleanText);

    for (String emotion in _emotions) {
      final emotionData = _emotionWeights![emotion];
      if (emotionData == null) continue;

      double enhancementBonus = 0.0;

      // Apply pattern recognition enhancement
      enhancementBonus += _calculatePatternScore(text, emotionData) * 0.3;

      // Apply contextual analysis enhancement
      enhancementBonus += _calculateContextScore(sentences, emotionData) * 0.25;

      // Apply sentiment flow analysis enhancement
      enhancementBonus += _calculateSentimentFlow(sentences, emotionData) * 0.2;

      // Apply negation penalty
      final negationPenalty =
          _calculateNegationPenalty(cleanText, emotion, emotionData);

      // Apply personality and temporal bonuses
      enhancementBonus += _calculatePersonalityBonus(emotion) * 0.15;
      enhancementBonus += _calculateTemporalBonus(emotion) * 0.1;

      // Calculate enhanced score with negation handling
      double enhancedValue =
          (enhancedScores[emotion] ?? 0.0) + enhancementBonus;
      enhancedValue *= (1.0 - negationPenalty);

      enhancedScores[emotion] = math.max(0.0, enhancedValue);
    }

    // Original punctuation analysis (still useful)
    final exclamationCount = '!'.allMatches(text).length;
    final questionCount = '?'.allMatches(text).length;

    if (exclamationCount > 1) {
      enhancedScores['happy'] = (enhancedScores['happy'] ?? 0) * 1.1;
      enhancedScores['angry'] = (enhancedScores['angry'] ?? 0) * 1.05;
    }

    if (questionCount > 1) {
      enhancedScores['fear'] = (enhancedScores['fear'] ?? 0) * 1.1;
      enhancedScores['surprise'] = (enhancedScores['surprise'] ?? 0) * 1.05;
    }

    return enhancedScores;
  }

  /// Advanced probability normalization with confidence boosting
  static Map<String, double> _normalizeToProbabilitiesAdvanced(
      Map<String, double> scores) {
    final totalScore =
        scores.values.fold(0.0, (sum, score) => sum + math.max(0, score));

    if (totalScore == 0) {
      return {
        for (final emotion in _emotions)
          emotion: emotion == 'neutral' ? 0.7 : 0.043
      };
    }

    final probabilities = <String, double>{};
    for (final entry in scores.entries) {
      final normalizedScore = math.max(0, entry.value) / totalScore;
      probabilities[entry.key] = normalizedScore;
    }

    // Apply confidence boosting for clear winners
    final maxEntry =
        probabilities.entries.reduce((a, b) => a.value > b.value ? a : b);
    if (maxEntry.value > 0.5) {
      // Boost confidence for clear emotional signals
      probabilities[maxEntry.key] = math.min(0.95, maxEntry.value * 1.2);

      // Redistribute remaining probability
      final remaining = 1.0 - probabilities[maxEntry.key]!;
      final otherEmotions = _emotions.where((e) => e != maxEntry.key).toList();
      final redistributed = remaining / otherEmotions.length;

      for (final emotion in otherEmotions) {
        probabilities[emotion] = redistributed;
      }
    }

    return probabilities;
  }

  /// Select dominant emotion with advanced logic
  static MapEntry<String, double> _selectDominantEmotion(
      Map<String, double> probabilities) {
    final sorted = probabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final first = sorted[0];
    final second =
        sorted.length > 1 ? sorted[1] : const MapEntry('neutral', 0.0);

    // If the difference is too small, consider mixed emotions
    if (first.value - second.value < 0.1 && first.value < 0.6) {
      // Mixed emotion scenario - choose based on learning bias
      final firstLearning = _userEmotionPatterns[first.key] ?? 0;
      final secondLearning = _userEmotionPatterns[second.key] ?? 0;

      if (secondLearning > firstLearning) {
        return second;
      }
    }

    return first;
  }

  /// Learn from detection for continuous improvement
  static void _learnFromDetection(
      String text, String emotion, double confidence) {
    // Update emotion learning counts
    _emotionLearningCounts[emotion] =
        (_emotionLearningCounts[emotion] ?? 0) + 1;

    // Update user emotion patterns (exponential moving average)
    final currentPattern = _userEmotionPatterns[emotion] ?? 0;
    _userEmotionPatterns[emotion] = currentPattern * 0.9 + confidence * 0.1;

    // Store context for future learning (keep last 10 contexts per emotion)
    if (!_emotionContextMemory.containsKey(emotion)) {
      _emotionContextMemory[emotion] = [];
    }

    final contexts = _emotionContextMemory[emotion]!;
    final shortContext = text.length > 50 ? text.substring(0, 50) : text;
    contexts.add(shortContext);

    // Keep only last 10 contexts to prevent memory bloat
    if (contexts.length > 10) {
      contexts.removeAt(0);
    }

    // Learning completed for emotion detection
  }

  /// Generate advanced reasoning with learning context
  static String _generateAdvancedReasoning(
      String text, String emotion, Map<String, double> scores) {
    final reasoning = StringBuffer();

    // Basic reasoning
    reasoning.write('Detected "$emotion" emotion');

    // Add confidence level
    final confidence = scores[emotion] ?? 0;
    if (confidence > 2.0) {
      reasoning.write(' with high confidence');
    } else if (confidence > 1.0) {
      reasoning.write(' with moderate confidence');
    } else {
      reasoning.write(' with low confidence');
    }

    // Add learning context
    final learningCount = _emotionLearningCounts[emotion] ?? 0;
    if (learningCount > 5) {
      reasoning.write(
          '. This emotion has been detected $learningCount times, improving accuracy');
    }

    // Add pattern information
    final userPattern = _userEmotionPatterns[emotion];
    if (userPattern != null && userPattern > 0.3) {
      reasoning.write(
          '. User frequently experiences this emotion (pattern strength: ${(userPattern * 100).toInt()}%)');
    }

    // Add context information
    final contexts = _emotionContextMemory[emotion];
    if (contexts != null && contexts.isNotEmpty) {
      reasoning.write('. Similar emotional contexts have been observed before');
    }

    reasoning.write('.');

    return reasoning.toString();
  }

  // ========== INTELLIGENT AI ANALYSIS METHODS ==========

  /// Semantic Analysis - Understanding meaning beyond keywords
  static Map<String, double> _performSemanticAnalysis(
      String processedText, String originalText) {
    final scores = <String, double>{};

    // Initialize all emotion scores
    for (final emotion in _emotions) {
      scores[emotion] = 0.0;
    }

    // Analyze sentence structure and meaning
    final sentences = _splitIntoSentences(originalText);

    for (final sentence in sentences) {
      final sentenceEmotion = _analyzeSentenceSemantics(sentence.toLowerCase());

      // Add weighted scores based on sentence position and length
      final sentenceWeight = _calculateSentenceWeight(sentence, sentences);

      for (final emotion in sentenceEmotion.keys) {
        scores[emotion] = (scores[emotion] ?? 0.0) +
            (sentenceEmotion[emotion]! * sentenceWeight);
      }
    }

    return scores;
  }

  /// Sentiment Analysis - Understanding emotional tone and intensity
  static Map<String, double> _performSentimentAnalysis(String text) {
    final scores = <String, double>{};

    // Initialize scores
    for (final emotion in _emotions) {
      scores[emotion] = 0.0;
    }

    // Analyze positive vs negative sentiment
    final positiveScore = _calculatePositiveSentiment(text);
    final negativeScore = _calculateNegativeSentiment(text);
    final neutralScore = 1.0 - (positiveScore + negativeScore).abs();

    // Map sentiment to emotions intelligently
    if (positiveScore > negativeScore) {
      scores['happy'] = positiveScore * 0.7;
      scores['love'] = positiveScore * 0.5;
      scores['surprise'] = positiveScore * 0.3;
    } else if (negativeScore > positiveScore) {
      scores['sad'] = negativeScore * 0.6;
      scores['angry'] = negativeScore * 0.4;
      scores['fear'] = negativeScore * 0.3;
    }

    scores['neutral'] = neutralScore;

    return scores;
  }

  /// Contextual Analysis - Understanding situational context
  static Map<String, double> _performContextualAnalysis(
      String processedText, String originalText) {
    final scores = <String, double>{};

    // Initialize scores
    for (final emotion in _emotions) {
      scores[emotion] = 0.0;
    }

    // Detect different life contexts
    final contexts = _detectLifeContexts(processedText);

    for (final context in contexts.entries) {
      final contextType = context.key;
      final contextStrength = context.value;

      // Apply context-specific emotion mappings
      switch (contextType) {
        case 'school':
          scores['fear'] = scores['fear']! + (contextStrength * 0.3);
          scores['angry'] = scores['angry']! + (contextStrength * 0.2);
          break;
        case 'family':
          scores['love'] = scores['love']! + (contextStrength * 0.4);
          scores['happy'] = scores['happy']! + (contextStrength * 0.3);
          break;
        case 'work':
          scores['neutral'] = scores['neutral']! + (contextStrength * 0.4);
          scores['angry'] = scores['angry']! + (contextStrength * 0.2);
          break;
        case 'relationship':
          scores['love'] = scores['love']! + (contextStrength * 0.5);
          scores['sad'] = scores['sad']! + (contextStrength * 0.3);
          break;
      }
    }

    return scores;
  }

  /// Pattern Analysis - Understanding language patterns and structure
  static Map<String, double> _performPatternAnalysis(String text) {
    final scores = <String, double>{};

    // Initialize scores
    for (final emotion in _emotions) {
      scores[emotion] = 0.0;
    }

    // Analyze exclamation patterns (excitement/anger)
    final exclamationCount = '!'.allMatches(text).length;
    if (exclamationCount > 0) {
      scores['happy'] = scores['happy']! + (exclamationCount * 0.2);
      scores['angry'] = scores['angry']! + (exclamationCount * 0.15);
      scores['surprise'] = scores['surprise']! + (exclamationCount * 0.1);
    }

    // Analyze question patterns (confusion/fear)
    final questionCount = '?'.allMatches(text).length;
    if (questionCount > 0) {
      scores['fear'] = scores['fear']! + (questionCount * 0.15);
      scores['neutral'] = scores['neutral']! + (questionCount * 0.1);
    }

    // Analyze repetition patterns (emphasis)
    final repetitions = _findRepetitions(text);
    if (repetitions.isNotEmpty) {
      scores['angry'] =
          scores['angry']! + (repetitions.length * 0.1); // Repetition often indicates strong emotion
    }

    // Analyze capitalization patterns (shouting/emphasis)
    final capsRatio = _calculateCapsRatio(text);
    if (capsRatio > 0.3) {
      scores['angry'] = scores['angry']! + (capsRatio * 0.3);
      scores['surprise'] = scores['surprise']! + (capsRatio * 0.2);
    }

    return scores;
  }

  /// Intelligent Score Fusion - Combines all analysis layers intelligently
  static Map<String, double> _intelligentScoreFusion(
      Map<String, double> semantic,
      Map<String, double> sentiment,
      Map<String, double> contextual,
      Map<String, double> pattern) {
    final fusedScores = <String, double>{};

    for (final emotion in _emotions) {
      // Weight different analysis types based on their reliability
      final semanticWeight = 0.4; // Most important
      final sentimentWeight = 0.3; // Very important
      final contextualWeight = 0.2; // Important
      final patternWeight = 0.1; // Supporting evidence

      fusedScores[emotion] = (semantic[emotion]! * semanticWeight) +
          (sentiment[emotion]! * sentimentWeight) +
          (contextual[emotion]! * contextualWeight) +
          (pattern[emotion]! * patternWeight);
    }

    return fusedScores;
  }

  // ========== INTELLIGENT HELPER METHODS ==========

  /// Split text into sentences for analysis
  static List<String> _splitIntoSentences(String text) {
    return text
        .split(RegExp(r'[.!?]+'))
        .where((sentence) => sentence.trim().isNotEmpty)
        .map((sentence) => sentence.trim())
        .toList();
  }

  /// Analyze individual sentence semantics
  static Map<String, double> _analyzeSentenceSemantics(String sentence) {
    final scores = <String, double>{};

    // Initialize scores
    for (final emotion in _emotions) {
      scores[emotion] = 0.0;
    }

    // Intelligent keyword analysis with context
    for (final emotion in _emotions) {
      final emotionData = _emotionWeights![emotion];
      final keywords = Map<String, double>.from(emotionData['keywords']);

      for (final entry in keywords.entries) {
        final keyword = entry.key;
        final weight = entry.value;

        // Smart matching - consider word boundaries and context
        if (_isKeywordMatch(sentence, keyword)) {
          // Apply contextual weight based on surrounding words
          final contextWeight = _calculateContextualWeight(sentence, keyword);
          scores[emotion] = scores[emotion]! + (weight * contextWeight);
        }
      }
    }

    return scores;
  }

  /// Calculate sentence weight based on position and characteristics
  static double _calculateSentenceWeight(
      String sentence, List<String> allSentences) {
    double weight = 1.0;

    // First and last sentences are more important
    final index = allSentences.indexOf(sentence);
    if (index == 0 || index == allSentences.length - 1) {
      weight += 0.2;
    }

    // Longer sentences carry more weight
    if (sentence.length > 50) {
      weight += 0.1;
    }

    // Sentences with strong emotional indicators
    if (sentence.contains('!') || sentence.contains('?')) {
      weight += 0.15;
    }

    return weight;
  }

  /// Calculate positive sentiment score
  static double _calculatePositiveSentiment(String text) {
    final positiveWords = [
      'good',
      'great',
      'awesome',
      'amazing',
      'wonderful',
      'fantastic',
      'love',
      'like',
      'enjoy',
      'happy',
      'glad',
      'excited',
      'perfect',
      'best',
      'excellent',
      'brilliant',
      'superb',
      'outstanding'
    ];

    double score = 0.0;
    for (final word in positiveWords) {
      if (text.contains(word)) {
        score += 0.1;
      }
    }

    return math.min(1.0, score);
  }

  /// Calculate negative sentiment score
  static double _calculateNegativeSentiment(String text) {
    final negativeWords = [
      'bad',
      'terrible',
      'awful',
      'horrible',
      'worst',
      'hate',
      'dislike',
      'sad',
      'angry',
      'frustrated',
      'annoyed',
      'upset',
      'disappointed',
      'worried',
      'scared',
      'afraid',
      'anxious'
    ];

    double score = 0.0;
    for (final word in negativeWords) {
      if (text.contains(word)) {
        score += 0.1;
      }
    }

    return math.min(1.0, score);
  }

  /// Detect different life contexts in text
  static Map<String, double> _detectLifeContexts(String text) {
    final contexts = <String, double>{};

    // School context
    final schoolWords = [
      'school',
      'class',
      'teacher',
      'exam',
      'test',
      'homework',
      'study',
      'grade'
    ];
    contexts['school'] = _calculateContextStrength(text, schoolWords);

    // Family context
    final familyWords = [
      'family',
      'mom',
      'dad',
      'mother',
      'father',
      'parent',
      'sibling',
      'home'
    ];
    contexts['family'] = _calculateContextStrength(text, familyWords);

    // Work context
    final workWords = [
      'work',
      'job',
      'office',
      'boss',
      'colleague',
      'meeting',
      'project'
    ];
    contexts['work'] = _calculateContextStrength(text, workWords);

    // Relationship context
    final relationshipWords = [
      'boyfriend',
      'girlfriend',
      'partner',
      'date',
      'crush',
      'relationship'
    ];
    contexts['relationship'] =
        _calculateContextStrength(text, relationshipWords);

    return contexts;
  }

  /// Calculate context strength based on keyword presence
  static double _calculateContextStrength(String text, List<String> keywords) {
    double strength = 0.0;
    for (final keyword in keywords) {
      if (text.contains(keyword)) {
        strength += 0.2;
      }
    }
    return math.min(1.0, strength);
  }

  /// Smart keyword matching with context awareness
  static bool _isKeywordMatch(String sentence, String keyword) {
    // Exact word boundary matching
    final regex =
        RegExp(r'\b' + RegExp.escape(keyword) + r'\b', caseSensitive: false);
    return regex.hasMatch(sentence);
  }

  /// Calculate contextual weight for keywords
  static double _calculateContextualWeight(String sentence, String keyword) {
    double weight = 1.0;

    // Boost weight if keyword appears with intensifiers
    final intensifiers = ['very', 'really', 'extremely', 'super', 'totally'];
    for (final intensifier in intensifiers) {
      if (sentence.contains('$intensifier $keyword') ||
          sentence.contains('$keyword $intensifier')) {
        weight += 0.3;
      }
    }

    // Reduce weight if keyword appears with negations
    final negations = ['not', 'never', 'no', 'dont', "don't"];
    for (final negation in negations) {
      if (sentence.contains('$negation $keyword')) {
        weight *= 0.3; // Significantly reduce weight for negated keywords
      }
    }

    return weight;
  }

  /// Find repetitions in text (indicates emphasis)
  static List<String> _findRepetitions(String text) {
    final words = text.toLowerCase().split(' ');
    final repetitions = <String>[];

    for (int i = 0; i < words.length - 1; i++) {
      if (words[i] == words[i + 1] && words[i].length > 2) {
        repetitions.add(words[i]);
      }
    }

    return repetitions;
  }

  /// Calculate capitalization ratio
  static double _calculateCapsRatio(String text) {
    if (text.isEmpty) return 0.0;

    final capsCount = text
        .split('')
        .where(
            (char) => char == char.toUpperCase() && char != char.toLowerCase())
        .length;
    return capsCount / text.length;
  }

  /// Intelligent confidence calculation
  static Map<String, double> _calculateIntelligentConfidence(
      Map<String, double> scores, String text) {
    final confidenceScores = <String, double>{};

    // Find the maximum score for normalization
    final maxScore =
        scores.values.isNotEmpty ? scores.values.reduce(math.max) : 0.0;

    if (maxScore == 0.0) {
      // If no emotions detected, return neutral with medium confidence
      for (final emotion in _emotions) {
        confidenceScores[emotion] = emotion == 'neutral' ? 0.6 : 0.0;
      }
      return confidenceScores;
    }

    // Calculate confidence based on score distribution
    for (final emotion in _emotions) {
      final normalizedScore = scores[emotion]! / maxScore;

      // Apply confidence boosting for clear dominant emotions
      if (normalizedScore > 0.7) {
        confidenceScores[emotion] = normalizedScore * 0.95; // High confidence
      } else if (normalizedScore > 0.4) {
        confidenceScores[emotion] = normalizedScore * 0.8; // Medium confidence
      } else {
        confidenceScores[emotion] = normalizedScore * 0.6; // Lower confidence
      }
    }

    return confidenceScores;
  }

  /// Intelligent dominant emotion selection
  static MapEntry<String, double> _selectDominantEmotionIntelligently(
      Map<String, double> probabilities, String text) {
    // Sort emotions by score
    final sortedEmotions = probabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topEmotion = sortedEmotions.first;
    final secondEmotion = sortedEmotions.length > 1 ? sortedEmotions[1] : null;

    // If top emotion is significantly higher than second, return it
    if (secondEmotion == null || topEmotion.value > secondEmotion.value * 1.5) {
      return topEmotion;
    }

    // If emotions are close, apply intelligent tie-breaking
    return _applyIntelligentTieBreaking(sortedEmotions, text);
  }

  /// Apply intelligent tie-breaking when emotions are close
  static MapEntry<String, double> _applyIntelligentTieBreaking(
      List<MapEntry<String, double>> sortedEmotions, String text) {
    // Prefer emotions that are more specific over neutral
    for (final emotion in sortedEmotions) {
      if (emotion.key != 'neutral' && emotion.value > 0.3) {
        return emotion;
      }
    }

    // If all emotions are low, prefer neutral
    return MapEntry('neutral', 0.5);
  }

  /// Generate intelligent reasoning based on comprehensive analysis
  static String _generateIntelligentReasoning(String text, String emotion,
      Map<String, double> semanticScores, Map<String, double> contextScores) {
    final reasons = <String>[];

    // Add semantic reasoning
    if (semanticScores[emotion]! > 0.3) {
      reasons.add('Strong emotional language patterns detected');
    }

    // Add context reasoning
    final dominantContext = contextScores.entries
        .where((entry) => entry.value > 0.2)
        .map((entry) => entry.key)
        .join(', ');

    if (dominantContext.isNotEmpty) {
      reasons.add('Context: $dominantContext-related content');
    }

    // Add pattern reasoning
    if (text.contains('!')) {
      reasons.add('Emphatic expression detected');
    }

    if (text.contains('?')) {
      reasons.add('Questioning or uncertainty detected');
    }

    // Construct final reasoning
    if (reasons.isEmpty) {
      return 'Based on overall tone and language analysis';
    } else {
      return reasons.join('; ');
    }
  }

  static ({double score, List<String> keywords}) _calculateKeywordScore(
      String text,
      List<String> words,
      Map<String, dynamic> emotionData,
      String emotion) {
    final keywords = emotionData['keywords'] as Map<String, dynamic>? ?? {};
    final intensifiers =
        emotionData['intensifiers'] as Map<String, dynamic>? ?? {};
    final contextModifiers =
        emotionData['context_modifiers'] as Map<String, dynamic>? ?? {};

    double totalScore = 0.0;
    List<String> matchedKeywords = [];

    for (String word in words) {
      final lowerWord = word.toLowerCase();

      if (keywords.containsKey(lowerWord)) {
        double baseScore = (keywords[lowerWord] ?? 0.0).toDouble();
        double multiplier = 1.0;

        // Check for intensifiers in nearby words
        multiplier *= _findIntensifierMultiplier(
            words, words.indexOf(word), intensifiers);

        // Check for context modifiers
        multiplier *= _findContextMultiplier(text, contextModifiers);

        // Apply decay for repetition
        final wordCount =
            words.where((w) => w.toLowerCase() == lowerWord).length;
        if (wordCount > 1) {
          multiplier *= math.pow(0.8, wordCount - 1); // Diminishing returns
        }

        final finalScore = baseScore * multiplier;
        totalScore += finalScore;
        matchedKeywords.add(lowerWord);

        // Score calculation completed
      }
    }

    return (score: totalScore, keywords: matchedKeywords);
  }

  /// Find intensifier multipliers in nearby words
  static double _findIntensifierMultiplier(
      List<String> words, int keywordIndex, Map<String, dynamic> intensifiers) {
    double multiplier = 1.0;

    // Check 2 words before and after the keyword
    for (int i = math.max(0, keywordIndex - 2);
        i < math.min(words.length, keywordIndex + 3);
        i++) {
      if (i == keywordIndex) continue;

      final word = words[i].toLowerCase();
      if (intensifiers.containsKey(word)) {
        multiplier *= (intensifiers[word] ?? 1.0).toDouble();
      }
    }

    return multiplier;
  }

  /// Find context multipliers based on detected themes
  static double _findContextMultiplier(
      String text, Map<String, dynamic> contextModifiers) {
    double multiplier = 1.0;

    for (String context in contextModifiers.keys) {
      if (_detectContext(text, context)) {
        multiplier *= (contextModifiers[context] ?? 1.0).toDouble();
        debugPrint(
            '🎯 Context detected: $context (×${contextModifiers[context]})');
      }
    }

    return multiplier;
  }

  /// Detect specific contexts in text
  static bool _detectContext(String text, String context) {
    final lowerText = text.toLowerCase();

    switch (context) {
      case 'work_related':
      case 'work_stress':
        return lowerText.contains(RegExp(
            r'\b(work|job|office|boss|colleague|meeting|deadline|project|client|task)\b'));
      case 'relationship':
      case 'relationship_loss':
        return lowerText.contains(RegExp(
            r'\b(partner|boyfriend|girlfriend|spouse|husband|wife|love|relationship|breakup)\b'));
      case 'achievement':
        return lowerText.contains(RegExp(
            r'\b(success|win|achieve|accomplish|goal|victory|champion|award|prize)\b'));
      case 'health':
      case 'health_issues':
      case 'health_concern':
        return lowerText.contains(RegExp(
            r'\b(health|sick|illness|doctor|hospital|pain|medicine|treatment|diet|exercise)\b'));
      case 'personal_growth':
        return lowerText.contains(RegExp(
            r'\b(learn|grow|develop|improve|progress|change|transform|evolve)\b'));
      case 'financial_trouble':
      case 'financial_worry':
        return lowerText.contains(RegExp(
            r'\b(money|debt|broke|expensive|cost|budget|payment|loan|financial)\b'));
      case 'family_problems':
        return lowerText.contains(RegExp(
            r'\b(family|parent|child|sibling|relative|mom|dad|mother|father)\b'));
      case 'social_situation':
      case 'public_speaking':
        return lowerText.contains(RegExp(
            r'\b(social|people|crowd|public|speak|presentation|party|gathering)\b'));
      case 'relationship_anxiety':
        return lowerText.contains(RegExp(
            r'\b(anxiety|worry|nervous|concerned|stressed|relationship|partner)\b'));
      default:
        return false;
    }
  }

  /// Calculate pattern scores (emojis, punctuation)
  static double _calculatePatternScore(
      String text, Map<String, dynamic> emotionData) {
    final patterns = emotionData['patterns'] as List? ?? [];
    double score = 0.0;

    for (String pattern in patterns) {
      final count = text.split(pattern).length - 1;
      if (count > 0) {
        score += count * 0.5; // Each pattern match adds 0.5 points
        debugPrint('🎭 Pattern "$pattern" found $count times');
      }
    }

    return score;
  }

  /// Analyze contextual flow through sentences
  static double _calculateContextScore(
      List<String> sentences, Map<String, dynamic> emotionData) {
    if (sentences.length <= 1) return 0.0;

    double contextStrength = 0.0;
    final keywords = emotionData['keywords'] as Map<String, dynamic>? ?? {};

    // Check for emotional progression across sentences
    for (int i = 0; i < sentences.length - 1; i++) {
      final currentMatches = _countKeywordMatches(sentences[i], keywords);
      final nextMatches = _countKeywordMatches(sentences[i + 1], keywords);

      if (currentMatches > 0 && nextMatches > 0) {
        contextStrength += 0.3; // Bonus for sustained emotion
      }
    }

    return contextStrength;
  }

  /// Calculate sentiment flow analysis
  static double _calculateSentimentFlow(
      List<String> sentences, Map<String, dynamic> emotionData) {
    if (sentences.length <= 1) return 0.0;

    final keywords = emotionData['keywords'] as Map<String, dynamic>? ?? {};
    double flowScore = 0.0;

    List<double> sentenceScores = [];

    for (String sentence in sentences) {
      double sentenceScore = 0.0;
      final words = _extractWords(sentence);

      for (String word in words) {
        if (keywords.containsKey(word.toLowerCase())) {
          sentenceScore += (keywords[word.toLowerCase()] ?? 0.0).toDouble();
        }
      }

      sentenceScores.add(sentenceScore);
    }

    // Analyze flow patterns
    if (sentenceScores.isNotEmpty) {
      final maxScore = sentenceScores.reduce(math.max);
      final avgScore =
          sentenceScores.reduce((a, b) => a + b) / sentenceScores.length;

      // Bonus for building or sustained emotion
      if (avgScore > 0.5 && maxScore > 1.0) {
        flowScore += 0.4;
      }
    }

    return flowScore;
  }

  /// Calculate negation penalty
  static double _calculateNegationPenalty(
      String text, String emotion, Map<String, dynamic> emotionData) {
    final negationWeight = (emotionData['negation_weight'] ?? 0.3).toDouble();
    final negationWords = [
      'not',
      'no',
      'never',
      'neither',
      'none',
      'nothing',
      'nowhere',
      'nobody',
      'isn\'t',
      'aren\'t',
      'wasn\'t',
      'weren\'t',
      'don\'t',
      'doesn\'t',
      'didn\'t',
      'won\'t',
      'wouldn\'t',
      'can\'t',
      'couldn\'t',
      'shouldn\'t',
      'mustn\'t'
    ];

    final words = _extractWords(text);
    double penalty = 0.0;

    for (int i = 0; i < words.length; i++) {
      final word = words[i].toLowerCase();
      if (negationWords.contains(word)) {
        // Check if negation affects emotion words within 3 positions
        for (int j = i + 1; j < math.min(words.length, i + 4); j++) {
          final keywords =
              emotionData['keywords'] as Map<String, dynamic>? ?? {};
          if (keywords.containsKey(words[j].toLowerCase())) {
            penalty += negationWeight;
            debugPrint('❌ Negation detected: "$word" affects "${words[j]}"');
            break;
          }
        }
      }
    }

    return math.min(penalty, 0.8); // Cap penalty at 80%
  }

  /// Calculate personality-based bonus
  static double _calculatePersonalityBonus(String emotion) {
    final userPattern = _userEmotionPatterns[emotion] ?? 0.0;
    return userPattern * 0.2; // Up to 20% bonus for frequent emotions
  }

  /// Calculate temporal emotion tracking bonus
  static double _calculateTemporalBonus(String emotion) {
    final recentCount = _emotionLearningCounts[emotion] ?? 0;
    if (recentCount > 10) {
      return 0.1; // 10% bonus for well-learned emotions
    }
    return 0.0;
  }

  /// Advanced confidence calculation
  static double _calculateAdvancedConfidence(double primaryScore,
      double secondaryScore, Map<String, double> allScores, int textLength) {
    if (primaryScore == 0.0) return 0.1;

    // Base confidence from score magnitude
    double confidence = math.min(primaryScore / 5.0, 0.9);

    // Adjust based on score separation
    if (secondaryScore > 0.0) {
      final separation = (primaryScore - secondaryScore) / primaryScore;
      confidence *= (0.5 + separation * 0.5); // Penalize close scores
    }

    // Adjust based on text length
    if (textLength < 20) {
      confidence *= 0.8; // Lower confidence for short text
    } else if (textLength > 100) {
      confidence *= 1.1; // Higher confidence for longer text
    }

    // Ensure confidence is between 0.1 and 0.95
    return math.min(math.max(confidence, 0.1), 0.95);
  }

  /// Generate comprehensive reasoning
  static String _generateComprehensiveReasoning(String emotion,
      List<String> keywords, double confidence, String components) {
    final buffer = StringBuffer();

    buffer.write('Detected $emotion emotion');

    if (keywords.isNotEmpty) {
      buffer.write(' based on keywords: ${keywords.take(5).join(", ")}');
      if (keywords.length > 5) {
        buffer.write(' and ${keywords.length - 5} others');
      }
    }

    buffer.write('. ');
    buffer.write(components);

    // Add confidence description
    if (confidence > 0.8) {
      buffer.write(' The analysis shows very high confidence.');
    } else if (confidence > 0.6) {
      buffer.write(' The analysis shows high confidence.');
    } else if (confidence > 0.4) {
      buffer.write(' The analysis shows moderate confidence.');
    } else {
      buffer.write(' The analysis shows lower confidence.');
    }

    return buffer.toString();
  }

  /// Build detailed reasoning for each component
  static String _buildReasoning(List<String> keywords, double keywordScore,
      double patternScore, double contextScore, bool hasNegation) {
    final parts = <String>[];

    if (keywordScore > 0) {
      parts.add(
          'Strong keyword indicators (score: ${keywordScore.toStringAsFixed(2)})');
    }

    if (patternScore > 0) {
      parts.add(
          'Pattern matches detected (score: ${patternScore.toStringAsFixed(2)})');
    }

    if (contextScore > 0) {
      parts.add('Contextual analysis supports this emotion');
    }

    if (hasNegation) {
      parts.add('Negation detected, reducing confidence');
    }

    return parts.isNotEmpty
        ? '${parts.join('. ')}.'
        : 'Basic analysis completed.';
  }

  /// Count keyword matches in text
  static int _countKeywordMatches(String text, Map<String, dynamic> keywords) {
    final words = _extractWords(text);
    int count = 0;

    for (String word in words) {
      if (keywords.containsKey(word.toLowerCase())) {
        count++;
      }
    }

    return count;
  }

  /// Extract sentences from text
  static List<String> _extractSentences(String text) {
    return text
        .split(RegExp(r'[.!?]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  // ========== PUBLIC UTILITY METHODS ==========

  /// Check if AI is ready
  static bool get isInitialized => _initialized;

  /// Get supported emotions
  static List<String> get supportedEmotions => List.from(_emotions);
}
