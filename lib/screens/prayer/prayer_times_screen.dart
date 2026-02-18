import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../models/prayer_times.dart';
import '../../services/prayer_times_service.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  final PrayerTimesService _prayerService = PrayerTimesService();
  PrayerTimes? _prayerTimes;
  bool _isLoading = true;
  String? _error;
  Timer? _timer;
  String _currentTime = '';
  String? _nextPrayer;
  Duration? _timeUntilNext;

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _updateCurrentTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCurrentTime();
    });
  }

  void _updateCurrentTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      if (_prayerTimes != null) {
        _nextPrayer = _prayerTimes!.getNextPrayer();
        _timeUntilNext = _prayerTimes!.getTimeUntilNextPrayer();
      }
    });
  }

  Future<void> _loadPrayerTimes() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final prayerTimes = await _prayerService.getPrayerTimes();

      setState(() {
        _prayerTimes = prayerTimes;
        _isLoading = false;
      });

      if (prayerTimes == null) {
        setState(() {
          _error =
              'Unable to fetch prayer times. Please check your location settings.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading prayer times: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshPrayerTimes() async {
    await _prayerService.clearCache();
    await _loadPrayerTimes();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  Color _getPrayerColor(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'fajr':
        return Colors.indigo;
      case 'sunrise':
        return Colors.orange;
      case 'dhuhr':
        return Colors.amber;
      case 'asr':
        return Colors.deepOrange;
      case 'maghrib':
        return Colors.purple;
      case 'isha':
        return Colors.deepPurple;
      default:
        return Colors.blue;
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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Prayer Times',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshPrayerTimes,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _prayerTimes == null
                  ? _buildNoDataWidget()
                  : _buildPrayerTimesContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color:
                    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPrayerTimes,
              icon: const Icon(Icons.refresh),
              label: Text('Try Again', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color:
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Location Required',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please enable location services to get accurate prayer times for your area.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color:
                    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPrayerTimes,
              icon: const Icon(Icons.location_on),
              label: Text('Enable Location', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTimesContent() {
    return RefreshIndicator(
      onRefresh: _refreshPrayerTimes,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Time and Location
            _buildCurrentTimeCard(),

            const SizedBox(height: 16),

            // Next Prayer Countdown
            if (_nextPrayer != null) _buildNextPrayerCard(),

            const SizedBox(height: 16),

            // Prayer Times List
            _buildPrayerTimesList(),

            const SizedBox(height: 24),

            // Location Info
            _buildLocationInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTimeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Current Time',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentTime,
            style: GoogleFonts.poppins(
              fontSize: 32,
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _prayerTimes!.date,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextPrayerCard() {
    final nextPrayerColor = _getPrayerColor(_nextPrayer!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: nextPrayerColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: nextPrayerColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getPrayerIcon(_nextPrayer!),
                color: nextPrayerColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Next: $_nextPrayer',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: nextPrayerColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_timeUntilNext != null)
            Text(
              'in ${_formatDuration(_timeUntilNext!)}',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: nextPrayerColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimesList() {
    final prayers = _prayerTimes!.allPrayers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Prayer Times',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...prayers.entries
            .map((entry) => _buildPrayerTimeCard(
                  entry.key,
                  entry.value,
                  entry.key == _nextPrayer,
                ))
            ,
      ],
    );
  }

  Widget _buildPrayerTimeCard(String name, String time, bool isNext) {
    final color = _getPrayerColor(name);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isNext
            ? color.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNext
              ? color.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: isNext ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getPrayerIcon(name),
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          name,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
            color: isNext ? color : null,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              time,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isNext ? color : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (isNext) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.schedule,
                color: color,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Location',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_prayerTimes!.city}, ${_prayerTimes!.country}',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Prayer times are calculated using the Islamic Society of North America (ISNA) method',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

