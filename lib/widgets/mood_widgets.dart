import 'package:flutter/material.dart';
import '../services/mood_detection_service.dart';

class MoodIndicator extends StatelessWidget {
  final String mood;
  final double? confidence;
  final double size;
  final bool showText;
  final bool showConfidence;

  const MoodIndicator({
    super.key,
    required this.mood,
    this.confidence,
    this.size = 24.0,
    this.showText = false,
    this.showConfidence = false,
  });

  @override
  Widget build(BuildContext context) {
    final moodData = MoodDetectionResult(
        emotion: mood, confidence: confidence ?? 0.0, allProbabilities: {});

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                Color(int.parse(moodData.moodColor.replaceFirst('#', '0xFF'))),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              moodData.moodEmoji,
              style: TextStyle(fontSize: size * 0.6),
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mood.isEmpty ? 'No mood' : mood.toUpperCase(),
                style: TextStyle(
                  fontSize: size * 0.5,
                  fontWeight: FontWeight.w600,
                  color: mood.isEmpty ? Colors.grey : null,
                ),
              ),
              if (showConfidence && confidence != null)
                Text(
                  '${(confidence! * 100).toStringAsFixed(0)}% confident',
                  style: TextStyle(
                    fontSize: size * 0.35,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class MoodAnalysisWidget extends StatefulWidget {
  final String text;
  final Function(MoodDetectionResult)? onMoodDetected;
  final bool autoAnalyze;
  final Widget? child;

  const MoodAnalysisWidget({
    super.key,
    required this.text,
    this.onMoodDetected,
    this.autoAnalyze = false,
    this.child,
  });

  @override
  State<MoodAnalysisWidget> createState() => _MoodAnalysisWidgetState();
}

class _MoodAnalysisWidgetState extends State<MoodAnalysisWidget> {
  final MoodDetectionService _moodService = MoodDetectionService();
  MoodDetectionResult? _currentMood;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoAnalyze && widget.text.isNotEmpty) {
      _analyzeMood();
    }
  }

  @override
  void didUpdateWidget(MoodAnalysisWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoAnalyze &&
        widget.text != oldWidget.text &&
        widget.text.isNotEmpty &&
        !_isAnalyzing) {
      _analyzeMood();
    }
  }

  Future<void> _analyzeMood() async {
    if (widget.text.trim().isEmpty) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final result = await _moodService.detectMood(widget.text);
      setState(() {
        _currentMood = result;
      });

      if (widget.onMoodDetected != null) {
        widget.onMoodDetected!(result);
      }
    } catch (e) {
      setState(() {
        _currentMood = MoodDetectionResult(
          emotion: 'neutral',
          confidence: 0.0,
          allProbabilities: {},
          error: 'Failed to analyze mood: $e',
        );
      });
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.child != null) widget.child!,
        const SizedBox(height: 8),
        Row(
          children: [
            if (!widget.autoAnalyze)
              ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : _analyzeMood,
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.psychology, size: 16),
                label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze Mood'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            if (_isAnalyzing && widget.autoAnalyze) ...[
              const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 8),
              const Text('Analyzing mood...', style: TextStyle(fontSize: 12)),
            ],
            if (_currentMood != null && !_isAnalyzing) ...[
              if (!widget.autoAnalyze) const SizedBox(width: 12),
              Expanded(
                child: _buildMoodResult(),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildMoodResult() {
    if (_currentMood == null) return const SizedBox.shrink();

    if (_currentMood!.error != null) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          border: Border.all(color: Colors.red.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 16, color: Colors.red.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _currentMood!.error!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MoodIndicator(
                mood: _currentMood!.emotion,
                confidence: _currentMood!.confidence,
                size: 32,
                showText: true,
                showConfidence: true,
              ),
              const Spacer(),
              if (_currentMood!.confidence > 0.7)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'High Confidence',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (_currentMood!.allProbabilities.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Other emotions detected:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _currentMood!.allProbabilities.entries
                  .where((entry) =>
                      entry.key != _currentMood!.emotion && entry.value > 0.1)
                  .take(3)
                  .map((entry) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              MoodDetectionResult(
                                  emotion: entry.key,
                                  confidence: 0.0,
                                  allProbabilities: {}).moodEmoji,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${(entry.value * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _moodService.dispose();
    super.dispose();
  }
}

class MoodStatisticsWidget extends StatefulWidget {
  final Map<String, dynamic> statistics;

  const MoodStatisticsWidget({
    super.key,
    required this.statistics,
  });

  @override
  State<MoodStatisticsWidget> createState() => _MoodStatisticsWidgetState();
}

class _MoodStatisticsWidgetState extends State<MoodStatisticsWidget> {
  @override
  Widget build(BuildContext context) {
    final moodCounts =
        widget.statistics['moodCounts'] as Map<String, int>? ?? {};
    final totalEntries = widget.statistics['totalEntries'] as int? ?? 0;
    final entriesWithMood = widget.statistics['entriesWithMood'] as int? ?? 0;
    final mostCommonMood = widget.statistics['mostCommonMood'] as String?;

    if (moodCounts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.mood, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                'No mood data available',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Start writing journal entries to see your mood patterns!',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mood Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Entries',
                    totalEntries.toString(),
                    Icons.book,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Analyzed',
                    entriesWithMood.toString(),
                    Icons.psychology,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            if (mostCommonMood != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(int.parse(MoodDetectionResult(
                              emotion: mostCommonMood,
                              confidence: 0.0,
                              allProbabilities: {})
                          .moodColor
                          .replaceFirst('#', '0xFF')))
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    MoodIndicator(
                      mood: mostCommonMood,
                      size: 32,
                      showText: true,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Most Common Mood',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${moodCounts[mostCommonMood]} entries',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Mood Distribution',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...moodCounts.entries.map((entry) {
              final percentage = (entry.value / entriesWithMood * 100).round();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    MoodIndicator(mood: entry.key, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '${entry.value} ($percentage%)',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
