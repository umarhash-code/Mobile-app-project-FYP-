import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/journal_entry.dart';
import 'rest_auth_service.dart';
import 'mood_detection_service.dart';

class JournalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RestAuthService _authService;
  final MoodDetectionService _moodService;

  JournalService(this._authService, [MoodDetectionService? moodService])
      : _moodService = moodService ?? MoodDetectionService();

  // Get current user ID
  String? get currentUserId {
    final user = _authService.currentUser;
    if (user == null) {
      debugPrint('🔥 JournalService: No authenticated user found');
    } else {
      debugPrint('🔥 JournalService: Current user ID: ${user.uid}');
    }
    return user?.uid;
  }

  // Collection reference for journal entries
  CollectionReference get _entriesCollection =>
      _firestore.collection('journal_entries');

  // Create a new journal entry with automatic mood detection
  Future<String> createEntry({
    required String title,
    required String content,
    List<String> tags = const [],
    String mood = '',
    bool detectMood = true, // Now defaults to true for automatic detection
  }) async {
    try {
      debugPrint('🔍 JournalService: Starting createEntry');
      debugPrint('🔍 JournalService: Current user ID: $currentUserId');

      if (currentUserId == null) {
        debugPrint('❌ JournalService: User not authenticated!');
        throw Exception('User not authenticated - please sign in again');
      }

      debugPrint('🔍 JournalService: Creating entry with title: "$title"');

      // Detect mood if enabled and no mood provided
      String finalMood = mood;
      double? moodConfidence;
      Map<String, double>? moodProbabilities;

      if (detectMood && mood.isEmpty) {
        debugPrint('🧠 JournalService: Detecting mood for journal entry');
        try {
          final moodResult =
              await _moodService.analyzeJournalEntry(title, content);
          if (moodResult.isSuccess) {
            finalMood = moodResult.emotion;
            moodConfidence = moodResult.confidence;
            moodProbabilities = moodResult.allProbabilities;
            debugPrint(
                '🧠 JournalService: Detected mood: $finalMood (confidence: ${moodConfidence.toStringAsFixed(2)})');
          } else {
            debugPrint(
                '⚠️ JournalService: Mood detection failed: ${moodResult.error}');
          }
        } catch (e) {
          debugPrint('⚠️ JournalService: Mood detection error: $e');
        }
      }

      // Use a server-safe approach: create a document reference first so we
      // can store the generated document ID inside the document and ensure
      // timestamps are consistent.
      final now = DateTime.now().toIso8601String();

      final docRef = _entriesCollection.doc();
      final id = docRef.id;

      final Map<String, dynamic> data = {
        'id': id,
        'title': title,
        'content': content,
        'createdAt': now,
        'updatedAt': now,
        'userId': currentUserId!,
        'tags': tags,
        'mood': finalMood,
        'moodConfidence': moodConfidence,
        'moodProbabilities': moodProbabilities,
      };

      debugPrint('🔍 JournalService: Writing to Firestore with ID: $id');
      await docRef.set(data);
      debugPrint('✅ JournalService: Entry created successfully with ID: $id');

      return id;
    } on FirebaseException catch (e) {
      debugPrint('❌ JournalService Firebase Error: ${e.code} - ${e.message}');
      if (e.code == 'permission-denied') {
        throw Exception(
            'Permission denied. Please check Firestore database rules.');
      } else if (e.code == 'unavailable') {
        throw Exception(
            'Network error. Please check your internet connection and try again.');
      } else if (e.code == 'not-found') {
        throw Exception(
            'Firestore database not found. Please check your Firebase project setup.');
      }
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      debugPrint('❌ JournalService: Error creating entry: $e');
      throw Exception('Failed to create entry: $e');
    }
  }

  // Update an existing journal entry with automatic mood detection
  Future<void> updateEntry({
    required String entryId,
    String? title,
    String? content,
    List<String>? tags,
    String? mood,
    bool detectMood = true, // Now defaults to true for automatic detection
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      Map<String, dynamic> updateData = {
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Handle mood detection for updated content
      if (detectMood && (title != null || content != null)) {
        debugPrint('🧠 JournalService: Detecting mood for updated entry');

        // Get current entry to combine with new content
        final currentEntry = await getEntry(entryId);
        if (currentEntry != null) {
          final finalTitle = title ?? currentEntry.title;
          final finalContent = content ?? currentEntry.content;

          try {
            final moodResult = await _moodService.analyzeJournalEntry(
                finalTitle, finalContent);
            if (moodResult.isSuccess) {
              updateData['mood'] = moodResult.emotion;
              updateData['moodConfidence'] = moodResult.confidence;
              updateData['moodProbabilities'] = moodResult.allProbabilities;
              debugPrint(
                  '🧠 JournalService: Updated mood: ${moodResult.emotion} (confidence: ${moodResult.confidence.toStringAsFixed(2)})');
            }
          } catch (e) {
            debugPrint(
                '⚠️ JournalService: Mood detection error during update: $e');
          }
        }
      }

      // Add other fields if provided
      if (title != null) updateData['title'] = title;
      if (content != null) updateData['content'] = content;
      if (tags != null) updateData['tags'] = tags;
      if (mood != null) {
        updateData['mood'] = mood;
        // Clear auto-detected mood data if manually setting mood
        updateData['moodConfidence'] = null;
        updateData['moodProbabilities'] = null;
      }

      await _entriesCollection.doc(entryId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update entry: $e');
    }
  }

  // Delete a journal entry
  Future<void> deleteEntry(String entryId) async {
    try {
      debugPrint('🗑️ JournalService: Starting delete for entry ID: $entryId');

      if (currentUserId == null) {
        debugPrint('❌ JournalService: User not authenticated');
        throw Exception('User not authenticated');
      }

      debugPrint(
          '🗑️ JournalService: User authenticated, proceeding with delete');
      await _entriesCollection.doc(entryId).delete();
      debugPrint('✅ JournalService: Delete successful');
    } on FirebaseException catch (e) {
      debugPrint(
          '❌ JournalService: FirebaseException during delete: ${e.code} - ${e.message}');
      if (e.code == 'permission-denied') {
        throw Exception(
            'Permission denied. Please check Firestore database rules.');
      } else if (e.code == 'unavailable') {
        throw Exception(
            'Network error. Please check your internet connection and try again.');
      } else if (e.code == 'not-found') {
        throw Exception('Entry not found. It may have already been deleted.');
      }
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      debugPrint('❌ JournalService: Error deleting entry: $e');
      throw Exception('Failed to delete entry: $e');
    }
  }

  // Get a specific journal entry
  Future<JournalEntry?> getEntry(String entryId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      DocumentSnapshot doc = await _entriesCollection.doc(entryId).get();

      if (doc.exists) {
        return JournalEntry.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get entry: $e');
    }
  }

  // Get all journal entries for current user
  Future<List<JournalEntry>> getUserEntries() async {
    try {
      debugPrint('📋 JournalService: Starting getUserEntries');
      if (currentUserId == null) {
        debugPrint('❌ JournalService: User not authenticated');
        throw Exception('User not authenticated');
      }

      debugPrint(
          '📋 JournalService: Querying entries for user: $currentUserId');

      // Use a simpler query that doesn't require a composite index
      QuerySnapshot querySnapshot = await _entriesCollection
          .where('userId', isEqualTo: currentUserId)
          .get();

      debugPrint(
          '📋 JournalService: Found ${querySnapshot.docs.length} documents');

      List<JournalEntry> entries = querySnapshot.docs.map((doc) {
        debugPrint('📋 JournalService: Processing document: ${doc.id}');
        return JournalEntry.fromFirestore(doc);
      }).toList();

      // Sort in memory instead of in the query
      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      debugPrint(
          '📋 JournalService: Successfully converted ${entries.length} entries');
      return entries;
    } on FirebaseException catch (e) {
      debugPrint(
          '❌ JournalService: FirebaseException in getUserEntries: ${e.code} - ${e.message}');
      if (e.code == 'permission-denied') {
        throw Exception(
            'Permission denied. Please check Firestore database rules.');
      } else if (e.code == 'unavailable') {
        throw Exception(
            'Network error. Please check your internet connection and try again.');
      }
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      debugPrint('❌ JournalService: Error getting user entries: $e');
      throw Exception('Failed to get user entries: $e');
    }
  }

  // Get recent journal entries (last 10)
  Future<List<JournalEntry>> getRecentEntries({int limit = 10}) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      QuerySnapshot querySnapshot = await _entriesCollection
          .where('userId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => JournalEntry.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get recent entries: $e');
    }
  }

  // Search entries by title or content
  Future<List<JournalEntry>> searchEntries(String searchTerm) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Note: Firestore doesn't support text search natively
      // This is a basic implementation - for better search, consider using Algolia or similar
      QuerySnapshot querySnapshot = await _entriesCollection
          .where('userId', isEqualTo: currentUserId)
          .get();

      return querySnapshot.docs
          .map((doc) => JournalEntry.fromFirestore(doc))
          .where((entry) =>
              entry.title.toLowerCase().contains(searchTerm.toLowerCase()) ||
              entry.content.toLowerCase().contains(searchTerm.toLowerCase()))
          .toList();
    } catch (e) {
      throw Exception('Failed to search entries: $e');
    }
  }

  // Get entries by date range
  Future<List<JournalEntry>> getEntriesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      QuerySnapshot querySnapshot = await _entriesCollection
          .where('userId', isEqualTo: currentUserId)
          .where('createdAt',
              isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('createdAt', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => JournalEntry.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get entries by date range: $e');
    }
  }

  // Get entries count for current user
  Future<int> getEntriesCount() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      QuerySnapshot querySnapshot = await _entriesCollection
          .where('userId', isEqualTo: currentUserId)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get entries count: $e');
    }
  }

  // Stream of user entries (real-time updates)
  Stream<List<JournalEntry>> getUserEntriesStream() {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    return _entriesCollection
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JournalEntry.fromFirestore(doc))
            .toList());
  }

  // Analyze mood for existing entry
  Future<MoodDetectionResult> analyzeMoodForEntry(String entryId) async {
    try {
      final entry = await getEntry(entryId);
      if (entry == null) {
        throw Exception('Entry not found');
      }

      return await _moodService.analyzeJournalEntry(entry.title, entry.content);
    } catch (e) {
      debugPrint('⚠️ JournalService: Error analyzing mood for entry: $e');
      return MoodDetectionResult.error('Failed to analyze mood: $e');
    }
  }

  // Update entry mood based on AI analysis
  Future<void> updateEntryMood(String entryId) async {
    try {
      final moodResult = await analyzeMoodForEntry(entryId);

      if (moodResult.isSuccess) {
        await _entriesCollection.doc(entryId).update({
          'mood': moodResult.emotion,
          'moodConfidence': moodResult.confidence,
          'moodProbabilities': moodResult.allProbabilities,
          'updatedAt': DateTime.now().toIso8601String(),
        });
        debugPrint(
            '✅ JournalService: Updated mood for entry $entryId: ${moodResult.emotion}');
      } else {
        throw Exception(moodResult.error ?? 'Mood analysis failed');
      }
    } catch (e) {
      debugPrint('❌ JournalService: Error updating entry mood: $e');
      throw Exception('Failed to update mood: $e');
    }
  }

  // Batch analyze moods for all user entries that don't have mood data
  Future<List<String>> analyzeMoodsForAllEntries({bool force = false}) async {
    try {
      final entries = await getUserEntries();
      final List<String> updatedEntries = [];

      for (final entry in entries) {
        // Skip if entry already has mood detection data (unless force is true)
        if (!force && entry.hasMoodDetection) {
          continue;
        }

        try {
          await updateEntryMood(entry.id);
          updatedEntries.add(entry.id);

          // Add small delay to avoid overwhelming the API
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          debugPrint(
              '⚠️ JournalService: Failed to analyze mood for entry ${entry.id}: $e');
        }
      }

      debugPrint(
          '✅ JournalService: Analyzed moods for ${updatedEntries.length} entries');
      return updatedEntries;
    } catch (e) {
      debugPrint('❌ JournalService: Error in batch mood analysis: $e');
      throw Exception('Failed to analyze moods: $e');
    }
  }

  // Get mood statistics for user entries
  Future<Map<String, dynamic>> getMoodStatistics() async {
    try {
      final entries = await getUserEntries();
      final moodCounts = <String, int>{};
      final moodConfidences = <String, List<double>>{};
      int totalEntriesWithMood = 0;

      for (final entry in entries) {
        if (entry.mood.isNotEmpty) {
          totalEntriesWithMood++;
          moodCounts[entry.mood] = (moodCounts[entry.mood] ?? 0) + 1;

          if (entry.moodConfidence != null) {
            moodConfidences[entry.mood] ??= [];
            moodConfidences[entry.mood]!.add(entry.moodConfidence!);
          }
        }
      }

      // Calculate average confidences
      final moodAverageConfidences = <String, double>{};
      moodConfidences.forEach((mood, confidences) {
        if (confidences.isNotEmpty) {
          moodAverageConfidences[mood] =
              confidences.reduce((a, b) => a + b) / confidences.length;
        }
      });

      return {
        'totalEntries': entries.length,
        'entriesWithMood': totalEntriesWithMood,
        'moodCounts': moodCounts,
        'moodAverageConfidences': moodAverageConfidences,
        'mostCommonMood': moodCounts.isNotEmpty
            ? moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : null,
      };
    } catch (e) {
      debugPrint('❌ JournalService: Error getting mood statistics: $e');
      throw Exception('Failed to get mood statistics: $e');
    }
  }

  // Dispose of resources
  void dispose() {
    _moodService.dispose();
  }
}
