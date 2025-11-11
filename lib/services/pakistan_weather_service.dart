import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_data.dart';

class PakistanWeatherService {
  // Demo mode for reliable weather data
  static const bool _isDemoMode = true;

  // Major Pakistani cities with accurate coordinates
  static const List<Map<String, dynamic>> _pakistaniCities = [
    {'name': 'Karachi', 'lat': 24.8607, 'lon': 67.0011, 'temp_base': 28.0},
    {'name': 'Lahore', 'lat': 31.5804, 'lon': 74.3587, 'temp_base': 25.0},
    {'name': 'Islamabad', 'lat': 33.6844, 'lon': 73.0479, 'temp_base': 22.0},
    {'name': 'Rawalpindi', 'lat': 33.5965, 'lon': 73.0516, 'temp_base': 23.0},
    {'name': 'Faisalabad', 'lat': 31.4504, 'lon': 73.1350, 'temp_base': 26.0},
    {'name': 'Multan', 'lat': 30.1575, 'lon': 71.5249, 'temp_base': 27.0},
    {'name': 'Peshawar', 'lat': 34.0151, 'lon': 71.5249, 'temp_base': 21.0},
    {'name': 'Quetta', 'lat': 30.1798, 'lon': 66.9750, 'temp_base': 18.0},
    {'name': 'Hyderabad', 'lat': 25.3960, 'lon': 68.3578, 'temp_base': 29.0},
    {'name': 'Gujranwala', 'lat': 32.1877, 'lon': 74.1945, 'temp_base': 24.0},
    {'name': 'Sialkot', 'lat': 32.4945, 'lon': 74.5229, 'temp_base': 23.0},
    {'name': 'Bahawalpur', 'lat': 29.3544, 'lon': 71.6911, 'temp_base': 28.0},
  ];

  // Cache keys
  static const String _lastWeatherKey = 'pk_last_weather_data';
  static const String _lastUpdateKey = 'pk_last_weather_update';
  static const String _cacheValidDuration = '30'; // minutes

  /// Get current weather for Pakistan region
  Future<WeatherData?> getCurrentWeather() async {
    try {
      // Get current location
      final position = await _getCurrentPosition();

      // Use demo mode with realistic Pakistani weather
      if (_isDemoMode) {
        return _getRealisticPakistaniWeather(position);
      }

      // Try to get cached weather first
      final cachedWeather = await _getCachedWeather();
      if (cachedWeather != null) {
        return cachedWeather;
      }

      // Fetch from API or fallback to nearest Pakistani city
      WeatherData? weatherData;

      if (position != null) {
        // Check if position is in Pakistan region
        if (_isInPakistanRegion(position.latitude, position.longitude)) {
          weatherData = await _fetchWeatherByCoordinates(
              position.latitude, position.longitude);
        }
      }

      // Fallback to major Pakistani city
      weatherData ??= await _fetchWeatherForNearestPakistaniCity(position);

      // Cache the result
      if (weatherData != null) {
        await _cacheWeatherData(weatherData);
      }

      return weatherData ?? _getRealisticPakistaniWeather(position);
    } catch (e) {
      debugPrint('Error getting Pakistan weather: $e');
      return _getRealisticPakistaniWeather(null);
    }
  }

  /// Check if coordinates are in Pakistan region
  bool _isInPakistanRegion(double lat, double lon) {
    return lat >= 23.5 && lat <= 37.5 && lon >= 60.0 && lon <= 77.5;
  }

  /// Get realistic Pakistani weather data based on current conditions
  WeatherData _getRealisticPakistaniWeather(Position? position) {
    final now = DateTime.now();
    final hour = now.hour;
    final month = now.month;

    // Determine the city
    Map<String, dynamic> selectedCity;

    if (position != null &&
        _isInPakistanRegion(position.latitude, position.longitude)) {
      // Find nearest Pakistani city
      selectedCity =
          _findNearestPakistaniCity(position.latitude, position.longitude);
    } else {
      // Default to a major city based on time (simulate user movement)
      final cityIndex = (now.day + hour) % _pakistaniCities.length;
      selectedCity = _pakistaniCities[cityIndex];
    }

    // Seasonal temperature adjustment
    double seasonalAdjustment = 0.0;
    List<String> seasonalConditions = [];

    switch (month) {
      case 12:
      case 1:
      case 2: // Winter
        seasonalAdjustment = -8.0;
        seasonalConditions = ['Clear', 'Fog', 'Clouds'];
        break;
      case 3:
      case 4:
      case 5: // Spring
        seasonalAdjustment = 0.0;
        seasonalConditions = ['Clear', 'Clouds', 'Dust'];
        break;
      case 6:
      case 7:
      case 8: // Summer
        seasonalAdjustment = 8.0;
        seasonalConditions = ['Clear', 'Haze', 'Very Hot'];
        break;
      case 9:
      case 10:
      case 11: // Autumn
        seasonalAdjustment = 2.0;
        seasonalConditions = ['Clear', 'Clouds', 'Pleasant'];
        break;
    }

    // Daily temperature variation
    double timeAdjustment = 0.0;
    String condition = 'Clear';
    String iconCode = '01d';

    if (hour >= 5 && hour < 10) {
      // Morning
      timeAdjustment = -5.0;
      condition = seasonalConditions[0];
      iconCode = '01d';
    } else if (hour >= 10 && hour < 16) {
      // Afternoon - Peak heat
      timeAdjustment = 5.0;
      condition = month >= 6 && month <= 8 ? 'Very Hot' : seasonalConditions[1];
      iconCode = month >= 6 && month <= 8 ? '01d' : '02d';
    } else if (hour >= 16 && hour < 19) {
      // Evening
      timeAdjustment = 2.0;
      condition = seasonalConditions[2];
      iconCode = '02d';
    } else {
      // Night
      timeAdjustment = -7.0;
      condition = 'Clear';
      iconCode = '01n';
    }

    final baseTemp = selectedCity['temp_base'] as double;
    final finalTemp = baseTemp + seasonalAdjustment + timeAdjustment;

    // Add some realistic variation
    final random = Random(now.day + now.hour);
    final variation = (random.nextDouble() - 0.5) * 4.0; // ±2°C

    return WeatherData(
      cityName: selectedCity['name'],
      countryCode: 'PK',
      temperature: finalTemp + variation,
      feelsLike: finalTemp + variation + (month >= 6 && month <= 8 ? 5.0 : 2.0),
      humidity: _calculateRealisticHumidity(month, hour, selectedCity['name']),
      windSpeed: _calculateRealisticWindSpeed(month, selectedCity['name']),
      description: condition.toLowerCase(),
      mainCondition: condition,
      iconCode: iconCode,
      sunrise: DateTime(now.year, now.month, now.day, 6, 15),
      sunset: DateTime(now.year, now.month, now.day, 18, 45),
      latitude: selectedCity['lat'],
      longitude: selectedCity['lon'],
      timestamp: now,
    );
  }

  /// Calculate realistic humidity for Pakistani cities
  int _calculateRealisticHumidity(int month, int hour, String cityName) {
    int baseHumidity;

    // Different base humidity for coastal vs inland cities
    if (cityName == 'Karachi' || cityName == 'Hyderabad') {
      baseHumidity = 70; // Coastal cities
    } else if (cityName == 'Quetta') {
      baseHumidity = 35; // Dry mountain city
    } else {
      baseHumidity = 50; // Inland cities
    }

    // Seasonal adjustment
    if (month >= 7 && month <= 9) {
      // Monsoon season
      baseHumidity += 20;
    } else if (month >= 12 || month <= 2) {
      // Winter
      baseHumidity += 10;
    }

    // Daily variation
    if (hour >= 5 && hour < 10) {
      baseHumidity += 15; // Higher humidity in morning
    } else if (hour >= 12 && hour < 16) {
      baseHumidity -= 10; // Lower humidity in afternoon heat
    }

    return (baseHumidity).clamp(25, 95);
  }

  /// Calculate realistic wind speed for Pakistani cities
  double _calculateRealisticWindSpeed(int month, String cityName) {
    double baseWind = 2.0;

    // Coastal cities have more wind
    if (cityName == 'Karachi') {
      baseWind = 3.5;
    }

    // Summer months have higher wind
    if (month >= 4 && month <= 6) {
      baseWind += 1.5;
    }

    // Add variation
    final random = Random(DateTime.now().day);
    return baseWind + (random.nextDouble() * 2.0);
  }

  /// Find nearest Pakistani city to given coordinates
  Map<String, dynamic> _findNearestPakistaniCity(double lat, double lon) {
    double minDistance = double.infinity;
    Map<String, dynamic> nearestCity = _pakistaniCities[0];

    for (final city in _pakistaniCities) {
      final distance = _calculateDistance(lat, lon, city['lat'], city['lon']);

      if (distance < minDistance) {
        minDistance = distance;
        nearestCity = city;
      }
    }

    return nearestCity;
  }

  /// Calculate distance between two coordinates (simplified)
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    final dLat = lat1 - lat2;
    final dLon = lon1 - lon2;
    return sqrt(dLat * dLat + dLon * dLon);
  }

  /// Get 5-day weather forecast for Pakistan
  Future<List<WeatherForecast>?> getWeatherForecast() async {
    try {
      final position = await _getCurrentPosition();

      if (_isDemoMode) {
        return _getRealisticPakistaniForecast(position);
      }

      // API implementation would go here
      return _getRealisticPakistaniForecast(position);
    } catch (e) {
      debugPrint('Error getting Pakistan forecast: $e');
      return _getRealisticPakistaniForecast(null);
    }
  }

  /// Generate realistic 5-day forecast for Pakistan
  List<WeatherForecast> _getRealisticPakistaniForecast(Position? position) {
    final now = DateTime.now();
    final selectedCity = position != null &&
            _isInPakistanRegion(position.latitude, position.longitude)
        ? _findNearestPakistaniCity(position.latitude, position.longitude)
        : _pakistaniCities[0]; // Default to Karachi

    return List.generate(5, (index) {
      final forecastDate = now.add(Duration(days: index + 1));
      final month = forecastDate.month;
      final baseTemp = selectedCity['temp_base'] as double;

      // Seasonal adjustment
      double seasonalAdj = 0.0;
      String condition = 'Clear';
      String icon = '01d';

      switch (month) {
        case 12:
        case 1:
        case 2: // Winter
          seasonalAdj = -6.0;
          condition = ['Clear', 'Fog', 'Clouds'][index % 3];
          icon = ['01d', '50d', '03d'][index % 3];
          break;
        case 6:
        case 7:
        case 8: // Summer
          seasonalAdj = 6.0;
          condition = ['Clear', 'Hot', 'Very Hot'][index % 3];
          icon = ['01d', '01d', '01d'][index % 3];
          break;
        default:
          condition = ['Clear', 'Clouds', 'Pleasant'][index % 3];
          icon = ['01d', '02d', '01d'][index % 3];
      }

      final random = Random(forecastDate.day);
      final variation = (random.nextDouble() - 0.5) * 3.0;

      return WeatherForecast(
        date: forecastDate,
        temperature: baseTemp + seasonalAdj + variation,
        minTemperature: baseTemp + seasonalAdj - 5.0 + variation,
        maxTemperature: baseTemp + seasonalAdj + 8.0 + variation,
        description: condition.toLowerCase(),
        mainCondition: condition,
        iconCode: icon,
        humidity: _calculateRealisticHumidity(month, 12, selectedCity['name']),
        windSpeed: _calculateRealisticWindSpeed(month, selectedCity['name']),
      );
    });
  }

  /// Get weather for specific Pakistani city
  Future<WeatherData?> getWeatherByCity(String cityName) async {
    try {
      // Find the city in our Pakistani cities list
      final city = _pakistaniCities.firstWhere(
        (c) => c['name'].toLowerCase() == cityName.toLowerCase(),
        orElse: () => _pakistaniCities[0], // Default to Karachi
      );

      if (_isDemoMode) {
        // Create a position object for the city
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
        return _getRealisticPakistaniWeather(position);
      }

      // API implementation would go here
      return _getRealisticPakistaniWeather(null);
    } catch (e) {
      debugPrint('Error getting weather for city $cityName: $e');
      return _getRealisticPakistaniWeather(null);
    }
  }

  /// Get all Pakistani cities for search
  List<String> getPakistaniCities() {
    return _pakistaniCities.map((city) => city['name'] as String).toList();
  }

  // Helper methods for location, caching, etc.
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

  Future<WeatherData?> _getCachedWeather() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdateString = prefs.getString(_lastUpdateKey);
      if (lastUpdateString == null) return null;

      final lastUpdate = DateTime.parse(lastUpdateString);
      final now = DateTime.now();

      if (now.difference(lastUpdate).inMinutes >
          int.parse(_cacheValidDuration)) {
        return null;
      }

      final weatherDataString = prefs.getString(_lastWeatherKey);
      if (weatherDataString == null) return null;

      final weatherDataMap = json.decode(weatherDataString);
      return WeatherData.fromJson(weatherDataMap);
    } catch (e) {
      debugPrint('Error reading cached weather: $e');
      return null;
    }
  }

  Future<void> _cacheWeatherData(WeatherData weatherData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastWeatherKey, json.encode(weatherData.toJson()));
      await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error caching weather data: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastWeatherKey);
      await prefs.remove(_lastUpdateKey);
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  // Placeholder methods for API integration
  Future<WeatherData?> _fetchWeatherByCoordinates(
      double lat, double lon) async {
    // This would implement actual API call to WeatherAPI.com
    // For now, return realistic data
    return _getRealisticPakistaniWeather(Position(
      latitude: lat,
      longitude: lon,
      timestamp: DateTime.now(),
      accuracy: 1.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    ));
  }

  Future<WeatherData?> _fetchWeatherForNearestPakistaniCity(
      Position? position) async {
    final city = position != null
        ? _findNearestPakistaniCity(position.latitude, position.longitude)
        : _pakistaniCities[0];

    return _getRealisticPakistaniWeather(Position(
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
    ));
  }
}
