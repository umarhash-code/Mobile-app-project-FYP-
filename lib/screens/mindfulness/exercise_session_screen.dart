import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../models/mindfulness_exercise.dart';
import '../../services/mindfulness_service.dart';

class ExerciseSessionScreen extends StatefulWidget {
  final MindfulnessExercise exercise;

  const ExerciseSessionScreen({
    super.key,
    required this.exercise,
  });

  @override
  State<ExerciseSessionScreen> createState() => _ExerciseSessionScreenState();
}

class _ExerciseSessionScreenState extends State<ExerciseSessionScreen>
    with TickerProviderStateMixin {
  final MindfulnessService _mindfulnessService = MindfulnessService();

  late AnimationController _breathingController;
  late AnimationController _pulseController;
  late Animation<double> _breathingAnimation;
  late Animation<double> _pulseAnimation;

  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isActive = false;
  bool _isPaused = false;
  bool _isCompleted = false;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _remainingSeconds = widget.exercise.durationMinutes * 60;
    _startSession();
  }

  void _setupAnimations() {
    _breathingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _breathingAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.exercise.type == ExerciseType.breathing) {
      _breathingController.repeat(reverse: true);
    } else {
      _pulseController.repeat(reverse: true);
    }
  }

  Future<void> _startSession() async {
    try {
      _sessionId =
          await _mindfulnessService.startExerciseSession(widget.exercise.id);
      setState(() {
        _isActive = true;
      });
      _startTimer();
    } catch (e) {
      // Even if the session fails to start on the server, we can still run the timer locally
      setState(() {
        _isActive = true;
      });
      _startTimer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Session started locally. Server sync may be unavailable.',
                style: GoogleFonts.poppins()),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0 && !_isPaused) {
        setState(() {
          _remainingSeconds--;
        });
      } else if (_remainingSeconds == 0) {
        _completeSession();
      }
    });
  }

  void _pauseResume() {
    setState(() {
      _isPaused = !_isPaused;
    });

    if (_isPaused) {
      _breathingController.stop();
      _pulseController.stop();
    } else {
      if (widget.exercise.type == ExerciseType.breathing) {
        _breathingController.repeat(reverse: true);
      } else {
        _pulseController.repeat(reverse: true);
      }
    }
  }

  void _stopSession() {
    _timer?.cancel();
    Navigator.of(context).pop();
  }

  Future<void> _completeSession() async {
    if (_sessionId != null) {
      try {
        await _mindfulnessService.completeExerciseSession(
            sessionId: _sessionId!);
      } catch (e) {
        // Handle error silently
      }
    }

    setState(() {
      _isCompleted = true;
      _isActive = false;
    });

    _timer?.cancel();
    _breathingController.stop();
    _pulseController.stop();

    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.celebration,
              color: _getTypeColor(),
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Well Done!',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: _getTypeColor(),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'ve completed the ${widget.exercise.title} exercise.',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'Take a moment to notice how you feel right now.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: Text(
              'Continue',
              style: GoogleFonts.poppins(
                color: _getTypeColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor() {
    switch (widget.exercise.type) {
      case ExerciseType.breathing:
        return Colors.lightBlue;
      case ExerciseType.meditation:
        return Colors.purple;
      case ExerciseType.patience:
        return Colors.green;
      case ExerciseType.gratitude:
        return Colors.orange;
      case ExerciseType.affirmation:
        return Colors.pink;
      case ExerciseType.visualization:
        return Colors.indigo;
      case ExerciseType.bodyRelaxation:
        return Colors.teal;
    }
  }

  IconData _getTypeIcon() {
    switch (widget.exercise.type) {
      case ExerciseType.breathing:
        return Icons.air;
      case ExerciseType.meditation:
        return Icons.self_improvement;
      case ExerciseType.patience:
        return Icons.hourglass_empty;
      case ExerciseType.gratitude:
        return Icons.favorite;
      case ExerciseType.affirmation:
        return Icons.psychology;
      case ExerciseType.visualization:
        return Icons.visibility;
      case ExerciseType.bodyRelaxation:
        return Icons.spa;
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getTypeColor().withValues(alpha: 0.1),
      body: SafeArea(
        child: Column(
          children: [
            // Header - Fixed height
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: _getTypeColor(),
                    ),
                    onPressed:
                        _isActive ? null : () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      widget.exercise.title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getTypeColor(),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Timer Display
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 15),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _getTypeColor().withValues(alpha: 0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            _formatTime(_remainingSeconds),
                            style: GoogleFonts.poppins(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: _getTypeColor(),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isPaused
                                ? 'Paused'
                                : _isCompleted
                                    ? 'Completed'
                                    : 'Remaining',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Animated Center Circle - Constrained height
                    SizedBox(
                      height: 220,
                      child: Center(
                        child: AnimatedBuilder(
                          animation:
                              widget.exercise.type == ExerciseType.breathing
                                  ? _breathingAnimation
                                  : _pulseAnimation,
                          builder: (context, child) {
                            final scale =
                                widget.exercise.type == ExerciseType.breathing
                                    ? _breathingAnimation.value
                                    : _pulseAnimation.value;

                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      _getTypeColor().withValues(alpha: 0.3),
                                      _getTypeColor().withValues(alpha: 0.1),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 110,
                                    height: 110,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _getTypeColor()
                                          .withValues(alpha: 0.8),
                                    ),
                                    child: Icon(
                                      _getTypeIcon(),
                                      size: 55,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Control Buttons - Fixed at bottom
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Stop Button
                  ElevatedButton(
                    onPressed: _isActive ? _stopSession : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.all(14),
                      shape: const CircleBorder(),
                      elevation: 0,
                    ),
                    child: const Icon(Icons.stop, size: 20),
                  ),

                  // Pause/Resume Button
                  ElevatedButton(
                    onPressed: _isActive && !_isCompleted ? _pauseResume : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getTypeColor(),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(18),
                      shape: const CircleBorder(),
                      elevation: 2,
                    ),
                    child: Icon(
                      _isPaused ? Icons.play_arrow : Icons.pause,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
