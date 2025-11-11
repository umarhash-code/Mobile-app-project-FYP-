import 'package:flutter/material.dart';

class CustomToggleButton extends StatefulWidget {
  final String label;
  final bool initialValue;
  final Function(bool) onToggle;
  final IconData? icon;
  final Color? activeColor;
  final Color? inactiveColor;
  final String? activeText;
  final String? inactiveText;

  const CustomToggleButton({
    super.key,
    required this.label,
    required this.onToggle,
    this.initialValue = false,
    this.icon,
    this.activeColor,
    this.inactiveColor,
    this.activeText,
    this.inactiveText,
  });

  @override
  State<CustomToggleButton> createState() => _CustomToggleButtonState();
}

class _CustomToggleButtonState extends State<CustomToggleButton>
    with SingleTickerProviderStateMixin {
  late bool _isToggled;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _isToggled = widget.initialValue;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleToggle() {
    setState(() {
      _isToggled = !_isToggled;
    });

    // Animation feedback
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Haptic feedback
    // HapticFeedback.lightImpact();

    // Call the callback
    widget.onToggle(_isToggled);
  }

  @override
  Widget build(BuildContext context) {
    final activeColor =
        widget.activeColor ?? Theme.of(context).colorScheme.primary;
    final inactiveColor = widget.inactiveColor ?? Colors.grey;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: _handleToggle,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isToggled
                    ? [
                        activeColor.withValues(alpha: 0.1),
                        activeColor.withValues(alpha: 0.05),
                      ]
                    : [
                        Colors.grey.withValues(alpha: 0.05),
                        Colors.grey.withValues(alpha: 0.02),
                      ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Toggle Switch
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Label and icon
                    Expanded(
                      child: Row(
                        children: [
                          if (widget.icon != null)
                            Icon(
                              widget.icon,
                              color: _isToggled ? activeColor : inactiveColor,
                              size: 24,
                            ),
                          if (widget.icon != null) const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.label,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _isToggled ? activeColor : inactiveColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Toggle switch
                    Switch(
                      value: _isToggled,
                      onChanged: (_) => _handleToggle(),
                      activeColor: activeColor,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),

                // Status text
                if (widget.activeText != null ||
                    widget.inactiveText != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _isToggled
                          ? activeColor.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _isToggled
                          ? (widget.activeText ?? 'ON')
                          : (widget.inactiveText ?? 'OFF'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _isToggled ? activeColor : inactiveColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Simple toggle button variant
class SimpleToggleButton extends StatefulWidget {
  final String label;
  final bool initialValue;
  final Function(bool) onToggle;
  final Color? activeColor;

  const SimpleToggleButton({
    super.key,
    required this.label,
    required this.onToggle,
    this.initialValue = false,
    this.activeColor,
  });

  @override
  State<SimpleToggleButton> createState() => _SimpleToggleButtonState();
}

class _SimpleToggleButtonState extends State<SimpleToggleButton> {
  late bool _isToggled;

  @override
  void initState() {
    super.initState();
    _isToggled = widget.initialValue;
  }

  void _handleToggle() {
    setState(() {
      _isToggled = !_isToggled;
    });
    widget.onToggle(_isToggled);
  }

  @override
  Widget build(BuildContext context) {
    final activeColor =
        widget.activeColor ?? Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: _handleToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _isToggled ? activeColor : Colors.grey[300],
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            color: _isToggled ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

