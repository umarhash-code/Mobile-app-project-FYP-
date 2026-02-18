import 'package:cloud_firestore/cloud_firestore.dart';

class JournalEntry {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final List<String> tags;
  final String mood;
  final double? moodConfidence;
  final Map<String, double>? moodProbabilities;

  JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    this.tags = const [],
    this.mood = '',
    this.moodConfidence,
    this.moodProbabilities,
  });

  // Convert JournalEntry to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'userId': userId,
      'tags': tags,
      'mood': mood,
      'moodConfidence': moodConfidence,
      'moodProbabilities': moodProbabilities,
    };
  }

  // Create JournalEntry from Firestore document
  factory JournalEntry.fromMap(Map<String, dynamic> map, String documentId) {
    return JournalEntry(
      id: documentId,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdAt:
          DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      userId: map['userId'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      mood: map['mood'] ?? '',
      moodConfidence: map['moodConfidence']?.toDouble(),
      moodProbabilities: map['moodProbabilities'] != null
          ? Map<String, double>.from(map['moodProbabilities'])
          : null,
    );
  }

  // Create JournalEntry from Firestore DocumentSnapshot
  factory JournalEntry.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return JournalEntry.fromMap(data, doc.id);
  }

  // Create a copy of JournalEntry with updated fields
  JournalEntry copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    List<String>? tags,
    String? mood,
    double? moodConfidence,
    Map<String, double>? moodProbabilities,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      tags: tags ?? this.tags,
      mood: mood ?? this.mood,
      moodConfidence: moodConfidence ?? this.moodConfidence,
      moodProbabilities: moodProbabilities ?? this.moodProbabilities,
    );
  }

  @override
  String toString() {
    return 'JournalEntry(id: $id, title: $title, content: ${content.length > 50 ? '${content.substring(0, 50)}...' : content}, createdAt: $createdAt)';
  }

  // Helper methods for mood
  String get moodEmoji {
    switch (mood.toLowerCase()) {
      case 'happy':
      case 'joy':
        return '😊';
      case 'love':
        return '❤️';
      case 'sad':
      case 'sadness':
        return '😢';
      case 'angry':
      case 'anger':
        return '😠';
      case 'fear':
        return '😰';
      case 'surprise':
        return '😲';
      case 'neutral':
      default:
        return '😐';
    }
  }

  String get moodColor {
    switch (mood.toLowerCase()) {
      case 'happy':
      case 'joy':
        return '#FFD700'; // Gold
      case 'love':
        return '#FF69B4'; // Hot Pink
      case 'sad':
      case 'sadness':
        return '#4169E1'; // Royal Blue
      case 'angry':
      case 'anger':
        return '#FF4500'; // Orange Red
      case 'fear':
        return '#8A2BE2'; // Blue Violet
      case 'surprise':
        return '#FF6347'; // Tomato
      case 'neutral':
      default:
        return '#808080'; // Gray
    }
  }

  bool get hasMoodDetection => mood.isNotEmpty && moodConfidence != null;

  String get moodConfidenceLevel {
    if (moodConfidence == null) return 'Unknown';
    if (moodConfidence! >= 0.8) return 'Very High';
    if (moodConfidence! >= 0.6) return 'High';
    if (moodConfidence! >= 0.4) return 'Medium';
    if (moodConfidence! >= 0.2) return 'Low';
    return 'Very Low';
  }
}
