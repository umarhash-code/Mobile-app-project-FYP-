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

  /// Advanced emotion detection method with learning capabilities
  static Future<EmotionResult> detectEmotion(String text) async {
    if (!_initialized) {
      await initialize();
    }

    if (text.trim().isEmpty) {
      return EmotionResult(
        emotion: 'neutral',
        confidence: 0.5,
        allEmotions: {'neutral': 0.5},
        reasoning: 'Empty text',
      );
    }

    // Preprocess text with advanced techniques
    final processedText = _preprocessText(text);

    // Calculate base emotion scores
    final scores = _calculateEmotionScores(processedText, text);

    // Apply context learning from previous detections
    final contextScores = _applyContextLearning(processedText, scores);

    // Apply user-specific pattern learning
    final learnedScores = _applyUserPatternLearning(contextScores);

    // Apply advanced emotion blending and temporal analysis
    final enhancedScores = _applyAdvancedAnalysis(learnedScores, processedText);

    // Normalize scores to probabilities with confidence boosting
    final probabilities = _normalizeToProbabilitiesAdvanced(enhancedScores);

    // Get dominant emotion with confidence analysis
    final dominantEmotion = _selectDominantEmotion(probabilities);

    // Learn from this detection for future improvements
    _learnFromDetection(
        processedText, dominantEmotion.key, dominantEmotion.value);

    // Generate advanced reasoning with learning context
    final reasoning = _generateAdvancedReasoning(
        processedText, dominantEmotion.key, enhancedScores);

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

  // ========== ENHANCED AI ANALYSIS METHODS ==========

  /// Advanced keyword scoring with context awareness
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
