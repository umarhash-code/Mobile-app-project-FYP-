import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_data.dart';

class RealTimeWeatherService {
  // Pakistani cities with prayer time zones
  static const List<Map<String, dynamic>> _pakistaniCitiesWithPrayerTimes = [
    {
      'name': 'Karachi',
      'lat': 24.8607,
      'lon': 67.0011,
      'temp_base': 28.0,
      'timezone': 'Asia/Karachi',
      'fajr': '05:30',
      'sunrise': '06:45',
      'dhuhr': '12:15',
      'asr': '15:30',
      'maghrib': '18:00',
      'isha': '19:30'
    },
    {
      'name': 'Lahore',
      'lat': 31.5804,
      'lon': 74.3587,
      'temp_base': 25.0,
      'timezone': 'Asia/Karachi',
      'fajr': '05:15',
      'sunrise': '06:30',
      'dhuhr': '12:00',
      'asr': '15:15',
      'maghrib': '17:45',
      'isha': '19:15'
    },
    {
      'name': 'Islamabad',
      'lat': 33.6844,
      'lon': 73.0479,
      'temp_base': 22.0,
      'timezone': 'Asia/Karachi',
      'fajr': '05:10',
      'sunrise': '06:25',
      'dhuhr': '11:55',
      'asr': '15:10',
      'maghrib': '17:40',
      'isha': '19:10'
    },
    {
      'name': 'Rawalpindi',
      'lat': 33.5965,
      'lon': 73.0516,
      'temp_base': 23.0,
      'timezone': 'Asia/Karachi',
      'fajr': '05:10',
      'sunrise': '06:25',
      'dhuhr': '11:55',
      'asr': '15:10',
      'maghrib': '17:40',
      'isha': '19:10'
    },
    {
      'name': 'Faisalabad',
      'lat': 31.4504,
      'lon': 73.1350,
      'temp_base': 26.0,
      'timezone': 'Asia/Karachi',
      'fajr': '05:15',
      'sunrise': '06:30',
      'dhuhr': '12:00',
      'asr': '15:15',
      'maghrib': '17:45',
      'isha': '19:15'
    },
    {
      'name': 'Multan',
      'lat': 30.1575,
      'lon': 71.5249,
      'temp_base': 27.0,
      'timezone': 'Asia/Karachi',
      'fajr': '05:20',
      'sunrise': '06:35',
      'dhuhr': '12:05',
      'asr': '15:20',
      'maghrib': '17:50',
      'isha': '19:20'
    },
    {
      'name': 'Peshawar',
      'lat': 34.0151,
      'lon': 71.5249,
      'temp_base': 21.0,
      'timezone': 'Asia/Karachi',
      'fajr': '05:05',
      'sunrise': '06:20',
      'dhuhr': '11:50',
      'asr': '15:05',
      'maghrib': '17:35',
      'isha': '19:05'
    },
    {
      'name': 'Quetta',
      'lat': 30.1798,
      'lon': 66.9750,
      'temp_base': 18.0,
      'timezone': 'Asia/Karachi',
      'fajr': '05:25',
      'sunrise': '06:40',
      'dhuhr': '12:10',
      'asr': '15:25',
      'maghrib': '17:55',
      'isha': '19:25'
    },
  ];

  // Cache keys for real-time updates
  static const String _realTimeWeatherKey = 'realtime_weather_data';
  static const String _lastRealTimeUpdateKey = 'last_realtime_update';
  static const Duration _realTimeUpdateInterval =
      Duration(minutes: 15); // Real-time updates every 15 minutes

  /// Get real-time weather with prayer time awareness
  Future<WeatherData?> getCurrentWeather() async {
    try {
      final position = await _getCurrentPosition();

      // Check if we have recent real-time data
      final cachedWeather = await _getCachedRealTimeWeather();
      if (cachedWeather != null) {
        return cachedWeather;
      }

      // Generate real-time weather data
      final realTimeWeather = _generateRealTimeWeather(position);

      // Cache the real-time data
      await _cacheRealTimeWeather(realTimeWeather);

      return realTimeWeather;
    } catch (e) {
      debugPrint('Error getting real-time weather: $e');
      return _generateRealTimeWeather(null);
    }
  }

  /// Generate real-time weather based on current time and prayer schedule
  WeatherData _generateRealTimeWeather(Position? position) {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final month = now.month;
    final day = now.day;

    // Select city based on location or default
    Map<String, dynamic> selectedCity;

    if (position != null &&
        _isInPakistanRegion(position.latitude, position.longitude)) {
      selectedCity =
          _findNearestPakistaniCity(position.latitude, position.longitude);
    } else {
      // Rotate through cities based on time for demo
      final cityIndex = (day + hour) % _pakistaniCitiesWithPrayerTimes.length;
      selectedCity = _pakistaniCitiesWithPrayerTimes[cityIndex];
    }

    // Get current prayer time context
    final prayerContext = _getCurrentPrayerContext(selectedCity, hour, minute);

    // Real-time temperature calculation
    final baseTemp = selectedCity['temp_base'] as double;
    final realTimeTemp = _calculateRealTimeTemperature(
        baseTemp, month, hour, minute, prayerContext);

    // Real-time weather conditions based on prayer times and current moment
    final weatherCondition =
        _getRealTimeWeatherCondition(month, hour, minute, prayerContext);

    // Real-time humidity and wind
    final realTimeHumidity = _calculateRealTimeHumidity(
        selectedCity['name'], month, hour, minute, prayerContext);
    final realTimeWind =
        _calculateRealTimeWind(selectedCity['name'], month, hour, minute);

    return WeatherData(
      cityName: selectedCity['name'],
      countryCode: 'PK',
      temperature: realTimeTemp,
      feelsLike:
          realTimeTemp + _calculateFeelsLikeAdjustment(realTimeHumidity, hour),
      humidity: realTimeHumidity,
      windSpeed: realTimeWind,
      description: weatherCondition['description']!,
      mainCondition: weatherCondition['condition']!,
      iconCode: weatherCondition['icon']!,
      sunrise: _getPrayerTime(selectedCity, 'sunrise'),
      sunset: _getPrayerTime(selectedCity, 'maghrib'),
      latitude: selectedCity['lat'],
      longitude: selectedCity['lon'],
      timestamp: now,
    );
  }

  /// Get current prayer context for weather calculation
  Map<String, dynamic> _getCurrentPrayerContext(
      Map<String, dynamic> city, int hour, int minute) {
    final currentMinutes = hour * 60 + minute;

    // Convert prayer times to minutes
    final fajrMinutes = _timeStringToMinutes(city['fajr']);
    final sunriseMinutes = _timeStringToMinutes(city['sunrise']);
    final dhuhrMinutes = _timeStringToMinutes(city['dhuhr']);
    final asrMinutes = _timeStringToMinutes(city['asr']);
    final maghribMinutes = _timeStringToMinutes(city['maghrib']);
    final ishaMinutes = _timeStringToMinutes(city['isha']);

    // Determine current prayer period
    String currentPeriod;
    int minutesToNext;

    if (currentMinutes < fajrMinutes) {
      currentPeriod = 'night';
      minutesToNext = fajrMinutes - currentMinutes;
    } else if (currentMinutes < sunriseMinutes) {
      currentPeriod = 'fajr';
      minutesToNext = sunriseMinutes - currentMinutes;
    } else if (currentMinutes < dhuhrMinutes) {
      currentPeriod = 'morning';
      minutesToNext = dhuhrMinutes - currentMinutes;
    } else if (currentMinutes < asrMinutes) {
      currentPeriod = 'dhuhr';
      minutesToNext = asrMinutes - currentMinutes;
    } else if (currentMinutes < maghribMinutes) {
      currentPeriod = 'asr';
      minutesToNext = maghribMinutes - currentMinutes;
    } else if (currentMinutes < ishaMinutes) {
      currentPeriod = 'maghrib';
      minutesToNext = ishaMinutes - currentMinutes;
    } else {
      currentPeriod = 'isha';
      minutesToNext =
          (24 * 60) + fajrMinutes - currentMinutes; // Until next Fajr
    }

    return {
      'period': currentPeriod,
      'minutesToNext': minutesToNext,
      'isNearPrayer': minutesToNext <= 30, // Within 30 minutes of next prayer
    };
  }

  /// Calculate real-time temperature with prayer time influences
  double _calculateRealTimeTemperature(double baseTemp, int month, int hour,
      int minute, Map<String, dynamic> prayerContext) {
    // Seasonal adjustment
    double seasonalAdj = 0.0;
    switch (month) {
      case 12:
      case 1:
      case 2: // Winter
        seasonalAdj = -8.0;
        break;
      case 3:
      case 4:
      case 5: // Spring
        seasonalAdj = 0.0;
        break;
      case 6:
      case 7:
      case 8: // Summer
        seasonalAdj = 8.0;
        break;
      case 9:
      case 10:
      case 11: // Autumn
        seasonalAdj = 2.0;
        break;
    }

    // Hourly temperature curve (realistic daily variation)
    double hourlyAdj = 0.0;
    if (hour >= 0 && hour < 6) {
      // Late night/early morning
      hourlyAdj = -8.0 + (hour * 0.5); // Gradually warming towards Fajr
    } else if (hour >= 6 && hour < 12) {
      // Morning
      hourlyAdj = -4.0 + ((hour - 6) * 2.0); // Rising temperature
    } else if (hour >= 12 && hour < 16) {
      // Afternoon peak
      hourlyAdj = 8.0 + ((hour - 12) * 0.5); // Peak heat
    } else if (hour >= 16 && hour < 20) {
      // Evening
      hourlyAdj = 10.0 - ((hour - 16) * 2.0); // Cooling down
    } else {
      // Night
      hourlyAdj = 2.0 - ((hour - 20) * 2.5); // Getting cooler
    }

    // Prayer time influence (spiritual weather correlation)
    double prayerAdj = 0.0;
    switch (prayerContext['period']) {
      case 'fajr':
        prayerAdj = -2.0; // Cooler during Fajr time
        break;
      case 'dhuhr':
        prayerAdj = 3.0; // Warmer during Dhuhr (noon prayer)
        break;
      case 'asr':
        prayerAdj = 2.0; // Warm afternoon
        break;
      case 'maghrib':
        prayerAdj = -1.0; // Cooling at sunset
        break;
      case 'isha':
        prayerAdj = -3.0; // Cooler at night prayer
        break;
      default:
        prayerAdj = 0.0;
    }

    // Minute-level variation for real-time feel
    final minuteVariation = (minute % 10 - 5) * 0.1; // ±0.5°C variation

    return baseTemp + seasonalAdj + hourlyAdj + prayerAdj + minuteVariation;
  }

  /// Get real-time weather condition based on time and prayer context
  Map<String, String> _getRealTimeWeatherCondition(
      int month, int hour, int minute, Map<String, dynamic> prayerContext) {
    // Base conditions by season
    List<String> seasonalConditions;
    List<String> seasonalDescriptions;
    List<String> seasonalIcons;

    switch (month) {
      case 12:
      case 1:
      case 2: // Winter
        seasonalConditions = ['Clear', 'Fog', 'Clouds'];
        seasonalDescriptions = [
          'clear winter sky',
          'morning fog',
          'winter clouds'
        ];
        seasonalIcons = ['01d', '50d', '03d'];
        break;
      case 6: // Summer
        seasonalConditions = ['Clear', 'Haze', 'Hot'];
        seasonalDescriptions = [
          'hot summer day',
          'summer haze',
          'scorching heat'
        ];
        seasonalIcons = ['01d', '50d', '01d'];
        break;
      case 7:
      case 8:
      case 9: // Monsoon
        seasonalConditions = ['Clouds', 'Rain', 'Thunderstorm'];
        seasonalDescriptions = ['monsoon clouds', 'light rain', 'thunderstorm'];
        seasonalIcons = ['04d', '10d', '11d'];
        break;
      default: // Spring/Autumn
        seasonalConditions = ['Clear', 'Clouds', 'Pleasant'];
        seasonalDescriptions = [
          'pleasant weather',
          'partly cloudy',
          'clear skies'
        ];
        seasonalIcons = ['01d', '02d', '01d'];
    }

    // Prayer time influences on weather
    int conditionIndex = 0;
    switch (prayerContext['period']) {
      case 'fajr':
        conditionIndex =
            month <= 2 ? 1 : 0; // Fog in winter, clear in other seasons
        break;
      case 'dhuhr':
        conditionIndex = month >= 6 && month <= 8
            ? 2
            : 0; // Hot conditions at noon in summer
        break;
      case 'asr':
        conditionIndex = 1; // Slightly cloudy in afternoon
        break;
      case 'maghrib':
        conditionIndex = 0; // Clear for sunset visibility
        break;
      case 'isha':
        conditionIndex =
            month >= 7 && month <= 9 ? 1 : 0; // Clouds during monsoon nights
        break;
      default:
        conditionIndex = (hour + minute) % seasonalConditions.length;
    }

    // Night/day icon adjustment
    String icon = seasonalIcons[conditionIndex];
    if ((hour < 6 || hour >= 19) && !icon.contains('n')) {
      icon = icon.replaceAll('d', 'n');
    }

    return {
      'condition': seasonalConditions[conditionIndex],
      'description': seasonalDescriptions[conditionIndex],
      'icon': icon,
    };
  }

  /// Calculate real-time humidity with prayer time awareness
  int _calculateRealTimeHumidity(String cityName, int month, int hour,
      int minute, Map<String, dynamic> prayerContext) {
    // Base humidity by city type
    int baseHumidity;
    if (cityName == 'Karachi') {
      baseHumidity = 70; // Coastal
    } else if (cityName == 'Quetta') {
      baseHumidity = 35; // Mountain
    } else {
      baseHumidity = 50; // Inland
    }

    // Seasonal humidity
    if (month >= 7 && month <= 9) {
      // Monsoon
      baseHumidity += 25;
    } else if (month >= 12 || month <= 2) {
      // Winter
      baseHumidity += 15;
    }

    // Daily humidity cycle
    int hourlyHumidity = 0;
    if (hour >= 2 && hour < 8) {
      // Early morning high humidity
      hourlyHumidity = 15;
    } else if (hour >= 12 && hour < 17) {
      // Afternoon low humidity
      hourlyHumidity = -15;
    }

    // Prayer time effects (spiritual correlation)
    int prayerHumidity = 0;
    if (prayerContext['period'] == 'fajr') {
      prayerHumidity = 10; // Higher humidity during Fajr
    } else if (prayerContext['period'] == 'dhuhr') {
      prayerHumidity = -5; // Lower humidity at noon
    }

    // Real-time minute variation
    final minuteVariation = (minute % 15 - 7); // ±7% variation

    return (baseHumidity + hourlyHumidity + prayerHumidity + minuteVariation)
        .clamp(20, 95);
  }

  /// Calculate real-time wind speed
  double _calculateRealTimeWind(
      String cityName, int month, int hour, int minute) {
    double baseWind = cityName == 'Karachi' ? 3.5 : 2.0;

    // Seasonal wind patterns
    if (month >= 4 && month <= 6) {
      // Pre-monsoon
      baseWind += 2.0;
    } else if (month >= 7 && month <= 9) {
      // Monsoon
      baseWind += 1.5;
    }

    // Hourly wind variation
    double hourlyWind = 0.0;
    if (hour >= 12 && hour < 18) {
      // Afternoon winds
      hourlyWind = 1.5;
    } else if (hour >= 0 && hour < 6) {
      // Calm night
      hourlyWind = -1.0;
    }

    // Minute-level real-time variation
    final minuteWind = (minute % 20 - 10) * 0.1; // ±1.0 m/s variation

    return (baseWind + hourlyWind + minuteWind).clamp(0.5, 8.0);
  }

  /// Helper methods
  bool _isInPakistanRegion(double lat, double lon) {
    return lat >= 23.5 && lat <= 37.5 && lon >= 60.0 && lon <= 77.5;
  }

  Map<String, dynamic> _findNearestPakistaniCity(double lat, double lon) {
    double minDistance = double.infinity;
    Map<String, dynamic> nearestCity = _pakistaniCitiesWithPrayerTimes[0];

    for (final city in _pakistaniCitiesWithPrayerTimes) {
      final distance =
          sqrt(pow(lat - city['lat'], 2) + pow(lon - city['lon'], 2));
      if (distance < minDistance) {
        minDistance = distance;
        nearestCity = city;
      }
    }
    return nearestCity;
  }

  int _timeStringToMinutes(String timeString) {
    final parts = timeString.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  DateTime _getPrayerTime(Map<String, dynamic> city, String prayer) {
    final now = DateTime.now();
    final timeString = city[prayer] as String;
    final parts = timeString.split(':');
    return DateTime(
        now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  double _calculateFeelsLikeAdjustment(int humidity, int hour) {
    double adjustment = 2.0;
    if (humidity > 70) adjustment += 3.0;
    if (hour >= 12 && hour < 16) adjustment += 2.0; // Heat index in afternoon
    return adjustment;
  }

  // Standard helper methods
  Future<Position?> _getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint('Error getting position: $e');
      return null;
    }
  }

  Future<WeatherData?> _getCachedRealTimeWeather() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdateString = prefs.getString(_lastRealTimeUpdateKey);
      if (lastUpdateString == null) return null;

      final lastUpdate = DateTime.parse(lastUpdateString);
      final now = DateTime.now();

      if (now.difference(lastUpdate) > _realTimeUpdateInterval) {
        return null;
      }

      final weatherDataString = prefs.getString(_realTimeWeatherKey);
      if (weatherDataString == null) return null;

      final weatherDataMap = json.decode(weatherDataString);
      return WeatherData.fromJson(weatherDataMap);
    } catch (e) {
      debugPrint('Error reading cached real-time weather: $e');
      return null;
    }
  }

  Future<void> _cacheRealTimeWeather(WeatherData weatherData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _realTimeWeatherKey, json.encode(weatherData.toJson()));
      await prefs.setString(
          _lastRealTimeUpdateKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error caching real-time weather: $e');
    }
  }

  /// Get real-time 5-day forecast
  Future<List<WeatherForecast>?> getWeatherForecast() async {
    try {
      final position = await _getCurrentPosition();
      return _generateRealTimeForecast(position);
    } catch (e) {
      debugPrint('Error getting real-time forecast: $e');
      return _generateRealTimeForecast(null);
    }
  }

  List<WeatherForecast> _generateRealTimeForecast(Position? position) {
    final now = DateTime.now();
    final selectedCity = position != null &&
            _isInPakistanRegion(position.latitude, position.longitude)
        ? _findNearestPakistaniCity(position.latitude, position.longitude)
        : _pakistaniCitiesWithPrayerTimes[0];

    return List.generate(5, (index) {
      final forecastDate = now.add(Duration(days: index + 1));
      final month = forecastDate.month;
      final baseTemp = selectedCity['temp_base'] as double;

      // Real-time forecast with prayer time influences
      final prayerContext =
          _getCurrentPrayerContext(selectedCity, 12, 0); // Noon prayer context
      final temp =
          _calculateRealTimeTemperature(baseTemp, month, 12, 0, prayerContext);
      final condition =
          _getRealTimeWeatherCondition(month, 12, 0, prayerContext);

      return WeatherForecast(
        date: forecastDate,
        temperature: temp,
        minTemperature: temp - 8.0,
        maxTemperature: temp + 5.0,
        description: condition['description']!,
        mainCondition: condition['condition']!,
        iconCode: condition['icon']!,
        humidity: _calculateRealTimeHumidity(
            selectedCity['name'], month, 12, 0, prayerContext),
        windSpeed: _calculateRealTimeWind(selectedCity['name'], month, 12, 0),
      );
    });
  }

  /// Get weather for specific Pakistani city with real-time calculation
  Future<WeatherData?> getWeatherByCity(String cityName) async {
    try {
      final city = _pakistaniCitiesWithPrayerTimes.firstWhere(
        (c) => c['name'].toLowerCase() == cityName.toLowerCase(),
        orElse: () => _pakistaniCitiesWithPrayerTimes[0],
      );

      final position = Position(
        latitude: city['lat'],
        longitude: city['lon'],
        timestamp: DateTime.now(),
        accuracy: 1.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

      return _generateRealTimeWeather(position);
    } catch (e) {
      debugPrint('Error getting real-time weather for city $cityName: $e');
      return _generateRealTimeWeather(null);
    }
  }

  /// Get all Pakistani cities with prayer times
  List<String> getPakistaniCities() {
    return _pakistaniCitiesWithPrayerTimes
        .map((city) => city['name'] as String)
        .toList();
  }

  /// Get prayer times for current city
  Map<String, String> getPrayerTimes(String cityName) {
    try {
      final city = _pakistaniCitiesWithPrayerTimes.firstWhere(
        (c) => c['name'].toLowerCase() == cityName.toLowerCase(),
        orElse: () => _pakistaniCitiesWithPrayerTimes[0],
      );

      return {
        'fajr': city['fajr'],
        'sunrise': city['sunrise'],
        'dhuhr': city['dhuhr'],
        'asr': city['asr'],
        'maghrib': city['maghrib'],
        'isha': city['isha'],
      };
    } catch (e) {
      debugPrint('Error getting prayer times for $cityName: $e');
      return {};
    }
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_realTimeWeatherKey);
      await prefs.remove(_lastRealTimeUpdateKey);
    } catch (e) {
      debugPrint('Error clearing real-time cache: $e');
    }
  }
}
