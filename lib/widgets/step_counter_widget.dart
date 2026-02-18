import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/step_counter_service.dart';
import '../models/step_data.dart';

class StepCounterWidget extends StatefulWidget {
  final double? height;
  final VoidCallback? onTap;

  const StepCounterWidget({
    super.key,
    this.height,
    this.onTap,
  });

  @override
  State<StepCounterWidget> createState() => _StepCounterWidgetState();
}

class _StepCounterWidgetState extends State<StepCounterWidget>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _progressController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StepCounterService>(
      builder: (context, stepService, child) {
        final stepData = stepService.stepData;

        return GestureDetector(
          onTap: widget.onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: widget.height ?? 160,
              decoration: _buildContainerDecoration(stepData),
              child: stepService.error != null
                  ? _buildErrorState(stepService.error!)
                  : _buildStepContent(stepData, stepService),
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _buildContainerDecoration(StepData stepData) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: stepData.goalAchieved
            ? [Colors.green.shade400, Colors.green.shade600]
            : [Colors.blue.shade400, Colors.blue.shade600],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          offset: const Offset(0, 4),
          blurRadius: 12,
          spreadRadius: 0,
        ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 8),
            const Text(
              'Step Counter Unavailable',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Check permissions',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(StepData stepData, StepCounterService stepService) {
    return Padding(
      padding: const EdgeInsets.all(12), // Reduced from 16 to 12
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(stepData),
          const SizedBox(height: 6), // Reduced from 8 to 6
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildStepDisplay(stepData, stepService)),
                const SizedBox(width: 10), // Reduced from 12 to 10
                _buildProgressCircle(stepData),
              ],
            ),
          ),
          _buildFooter(stepData),
        ],
      ),
    );
  }

  Widget _buildHeader(StepData stepData) {
    return Row(
      children: [
        Icon(
          stepData.goalAchieved ? Icons.celebration : Icons.directions_walk,
          color: Colors.white,
          size: 18, // Reduced from 20 to 18
        ),
        const SizedBox(width: 6), // Reduced from 8 to 6
        Expanded(
          child: Text(
            stepData.goalAchieved ? 'Goal Achieved!' : 'Daily Steps',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14, // Reduced from 16 to 14
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!stepData.goalAchieved)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 6, vertical: 3), // Reduced padding
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Goal: ${_formatNumber(stepData.dailyGoal)}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildStepDisplay(StepData stepData, StepCounterService stepService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation:
              stepData.goalAchieved ? _pulseAnimation : _progressAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: stepData.goalAchieved ? _pulseAnimation.value : 1.0,
              child: Text(
                _formatNumber(stepData.currentSteps),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24, // Reduced from 28 to 24
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          stepData.progressText,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (stepService.isListening)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Live tracking',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildProgressCircle(StepData stepData) {
    return SizedBox(
      width: 50, // Reduced from 60 to 50
      height: 50, // Reduced from 60 to 50
      child: Stack(
        children: [
          // Background circle
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          // Progress circle
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return CircularProgressIndicator(
                value: stepData.progressPercentage * _progressAnimation.value,
                strokeWidth: 3, // Reduced from 4 to 3
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  stepData.goalAchieved ? Colors.greenAccent : Colors.white,
                ),
              );
            },
          ),
          // Center text
          Center(
            child: Text(
              '${(stepData.progressPercentage * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(StepData stepData) {
    final weeklyAvg = stepData.weeklyAverage;

    return Row(
      children: [
        Icon(
          Icons.trending_up,
          color: Colors.white.withValues(alpha: 0.8),
          size: 14, // Reduced from 16 to 14
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            'Weekly avg: ${_formatNumber(weeklyAvg.toInt())}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11, // Reduced from 12 to 11
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Spacer(),
        if (stepData.goalAchieved)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star,
                color: Colors.yellow.shade300,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Excellent!',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      final thousands = (number / 1000).toStringAsFixed(1);
      return '${thousands.replaceAll('.0', '')}k';
    }
    return number.toString();
  }
}

// Compact version for smaller spaces
class CompactStepCounterWidget extends StatelessWidget {
  final VoidCallback? onTap;

  const CompactStepCounterWidget({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<StepCounterService>(
      builder: (context, stepService, child) {
        final stepData = stepService.stepData;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: stepData.goalAchieved
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: stepData.goalAchieved
                    ? Colors.green.withValues(alpha: 0.3)
                    : Colors.blue.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  stepData.goalAchieved
                      ? Icons.celebration
                      : Icons.directions_walk,
                  color: stepData.goalAchieved ? Colors.green : Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${stepData.currentSteps} steps',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      Text(
                        stepData.progressText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: stepData.progressPercentage,
                    strokeWidth: 2,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      stepData.goalAchieved ? Colors.green : Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
