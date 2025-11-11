import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/prayer_times.dart';
import '../services/prayer_times_service.dart';
import '../screens/prayer/prayer_times_screen.dart';

class PrayerTimesWidget extends StatefulWidget {
  const PrayerTimesWidget({super.key});

  @override
  State<PrayerTimesWidget> createState() => _PrayerTimesWidgetState();
}

class _PrayerTimesWidgetState extends State<PrayerTimesWidget> {
  final PrayerTimesService _prayerService = PrayerTimesService();
  PrayerTimes? _prayerTimes;
  bool _isLoading = true;
  String? _nextPrayer;

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
  }

  Future<void> _loadPrayerTimes() async {
    try {
      final prayerTimes = await _prayerService.getPrayerTimes();
      if (mounted) {
        setState(() {
          _prayerTimes = prayerTimes;
          _nextPrayer = prayerTimes?.getNextPrayer();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  IconData _getPrayerIcon(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'fajr':
        return Icons.brightness_2;
      case 'sunrise':
        return Icons.wb_sunny;
      case 'dhuhr':
        return Icons.wb_sunny_outlined;
      case 'asr':
        return Icons.wb_twilight;
      case 'maghrib':
        return Icons.brightness_3;
      case 'isha':
        return Icons.nights_stay;
      default:
        return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const PrayerTimesScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: _isLoading
            ? _buildLoadingState()
            : _prayerTimes == null
                ? _buildErrorState()
                : _buildPrayerContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.access_time,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Prayer Times',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.access_time,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Prayer Times',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Enable location to view times',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color:
                Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 8),
        Icon(
          Icons.location_off,
          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.6),
          size: 16,
        ),
      ],
    );
  }

  Widget _buildPrayerContent() {
    final nextPrayerTime =
        _nextPrayer != null ? _prayerTimes!.allPrayers[_nextPrayer!] : null;
    final timeUntilNext = _prayerTimes!.getTimeUntilNextPrayer();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.access_time,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              'Prayer Times',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context)
                  .colorScheme
                  .onPrimary
                  .withValues(alpha: 0.7),
              size: 14,
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (_nextPrayer != null && nextPrayerTime != null) ...[
          Row(
            children: [
              Icon(
                _getPrayerIcon(_nextPrayer!),
                color: Theme.of(context).colorScheme.onPrimary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Next: $_nextPrayer',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            nextPrayerTime,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          if (timeUntilNext != null) ...[
            const SizedBox(height: 2),
            Text(
              'in ${_formatDuration(timeUntilNext)}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
        const SizedBox(height: 4),
        Text(
          _prayerTimes!.city,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color:
                Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
