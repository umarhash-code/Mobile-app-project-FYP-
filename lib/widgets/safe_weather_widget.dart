import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ultra-safe weather widget that absolutely cannot overflow
/// This is a fallback version with minimal content and defensive constraints
class SafeWeatherWidget extends StatelessWidget {
  const SafeWeatherWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight * 0.15;
        final maxWidth = constraints.maxWidth;
        
        return Container(
          width: maxWidth,
          height: maxHeight.clamp(60, 100),
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.blue.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SingleChildScrollView(
              child: Row(
                children: [
                  // Weather icon
                  const Icon(
                    Icons.wb_sunny,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  // Temperature
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '25°C',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Location
                  Expanded(
                    child: Text(
                      'Weather',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}