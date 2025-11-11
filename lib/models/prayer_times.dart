class PrayerTimes {
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final String date;
  final String city;
  final String country;

  PrayerTimes({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.date,
    required this.city,
    required this.country,
  });

  factory PrayerTimes.fromJson(Map<String, dynamic> json) {
    final timings = json['data']['timings'];
    final dateInfo = json['data']['date'];
    final meta = json['data']['meta'];

    return PrayerTimes(
      fajr: _formatTime(timings['Fajr']),
      sunrise: _formatTime(timings['Sunrise']),
      dhuhr: _formatTime(timings['Dhuhr']),
      asr: _formatTime(timings['Asr']),
      maghrib: _formatTime(timings['Maghrib']),
      isha: _formatTime(timings['Isha']),
      date: dateInfo['readable'],
      city: meta['timezone'].split('/').last.replaceAll('_', ' '),
      country: meta['timezone'].split('/').first,
    );
  }

  static String _formatTime(String time) {
    // Remove timezone info if present (e.g., "05:30 (+03)" -> "05:30")
    return time.split(' ').first;
  }

  Map<String, String> get allPrayers => {
        'Fajr': fajr,
        'Sunrise': sunrise,
        'Dhuhr': dhuhr,
        'Asr': asr,
        'Maghrib': maghrib,
        'Isha': isha,
      };

  String? getNextPrayer() {
    final now = DateTime.now();
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final prayers = [
      {'name': 'Fajr', 'time': fajr},
      {'name': 'Sunrise', 'time': sunrise},
      {'name': 'Dhuhr', 'time': dhuhr},
      {'name': 'Asr', 'time': asr},
      {'name': 'Maghrib', 'time': maghrib},
      {'name': 'Isha', 'time': isha},
    ];

    for (var prayer in prayers) {
      if (_isTimeAfter(currentTime, prayer['time']!)) {
        return prayer['name'];
      }
    }

    // If all prayers have passed, next prayer is Fajr of tomorrow
    return 'Fajr';
  }

  bool _isTimeAfter(String currentTime, String prayerTime) {
    final current = _timeToMinutes(currentTime);
    final prayer = _timeToMinutes(prayerTime);
    return current < prayer;
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  Duration? getTimeUntilNextPrayer() {
    final nextPrayer = getNextPrayer();
    if (nextPrayer == null) return null;

    final now = DateTime.now();
    final prayerTime = allPrayers[nextPrayer]!;
    final parts = prayerTime.split(':');

    var prayerDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    // If the prayer is tomorrow (Fajr after Isha)
    if (nextPrayer == 'Fajr' && now.hour > 18) {
      prayerDateTime = prayerDateTime.add(const Duration(days: 1));
    }

    return prayerDateTime.difference(now);
  }

  @override
  String toString() {
    return 'PrayerTimes(city: $city, date: $date, fajr: $fajr, dhuhr: $dhuhr, asr: $asr, maghrib: $maghrib, isha: $isha)';
  }
}

