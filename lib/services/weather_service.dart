import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_data.dart';

class WeatherService {
  // Demo mode - set to false to use real weather API
  static const bool _isDemoMode = false;

  // WeatherAPI.com - Free tier with excellent Pakistan coverage
  // Get your free API key from https://www.weatherapi.com/
  static const String _apiKey = 'demo_key_for_pakistan'; // Demo key for testing
  static const String _baseUrl = 'https://api.weatherapi.com/v1';

  // Cache keys
  static const String _lastWeatherKey = 'last_weather_data';
  static const String _lastUpdateKey = 'last_weather_update';
  static const String _lastLocationKey = 'last_weather_location';

  // Cache duration (30 minutes)
  static const Duration _cacheValidDuration = Duration(minutes: 30);

  /// Get current weather based on device location
  Future<WeatherData?> getCurrentWeather() async {
    try {
      // Always try to get current location first
      final position = await _getCurrentPosition();

      // In demo mode, return location-aware mock data
      if (_isDemoMode) {
        return getMockWeatherDataForLocation(position);
      }

      // Check cache first (only in real API mode)
      final cachedWeather = await _getCachedWeather();
      if (cachedWeather != null) {
        return cachedWeather;
      }

      // If no location available, return null
      if (position == null) return null;

      // Fetch weather data
      final weatherData = await _fetchWeatherByCoordinates(
        position.latitude,
        position.longitude,
      );

      // Cache the result
      if (weatherData != null) {
        await _cacheWeatherData(weatherData);
      }

      return weatherData;
    } catch (e) {
      debugPrint('Error getting current weather: $e');
      // Return fallback mock data
      return getMockWeatherDataForLocation(null);
    }
  }

  /// Get weather by city name
  Future<WeatherData?> getWeatherByCity(String cityName) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/weather?q=$cityName&appid=$_apiKey&units=metric',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weatherData = WeatherData.fromJson(data);
        await _cacheWeatherData(weatherData);
        return weatherData;
      } else {
        debugPrint('Weather API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching weather by city: $e');
      return null;
    }
  }

  /// Get 5-day weather forecast
  Future<List<WeatherForecast>?> getWeatherForecast() async {
    try {
      // Always try to get location first
      final position = await _getCurrentPosition();

      // In demo mode, return location-aware mock forecast data
      if (_isDemoMode) {
        return getMockForecastDataForLocation(position);
      }

      if (position == null) return null;

      final url = Uri.parse(
        '$_baseUrl/forecast?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> forecastList = data['list'];

        // Group by day and take one forecast per day
        final Map<String, WeatherForecast> dailyForecasts = {};

        for (final item in forecastList) {
          final forecast = WeatherForecast.fromJson(item);
          final dateKey =
              '${forecast.date.year}-${forecast.date.month}-${forecast.date.day}';

          // Take the forecast closest to noon for each day
          if (!dailyForecasts.containsKey(dateKey) ||
              (forecast.date.hour - 12).abs() <
                  (dailyForecasts[dateKey]!.date.hour - 12).abs()) {
            dailyForecasts[dateKey] = forecast;
          }
        }

        return dailyForecasts.values.take(5).toList();
      }
    } catch (e) {
      debugPrint('Error fetching weather forecast: $e');
    }
    return null;
  }

  /// Check location permissions and get current position
  Future<Position?> _getCurrentPosition() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return null;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return null;
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  /// Fetch weather data by coordinates
  Future<WeatherData?> _fetchWeatherByCoordinates(
      double lat, double lon) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else {
        debugPrint('Weather API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching weather data: $e');
      return null;
    }
  }

  /// Get cached weather data if valid
  Future<WeatherData?> _getCachedWeather() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final lastUpdateString = prefs.getString(_lastUpdateKey);
      if (lastUpdateString == null) return null;

      final lastUpdate = DateTime.parse(lastUpdateString);
      final now = DateTime.now();

      // Check if cache is still valid
      if (now.difference(lastUpdate) > _cacheValidDuration) {
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

  /// Cache weather data
  Future<void> _cacheWeatherData(WeatherData weatherData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_lastWeatherKey, json.encode(weatherData.toJson()));
      await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
      await prefs.setString(
          _lastLocationKey, '${weatherData.latitude},${weatherData.longitude}');
    } catch (e) {
      debugPrint('Error caching weather data: $e');
    }
  }

  /// Clear cached weather data
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastWeatherKey);
      await prefs.remove(_lastUpdateKey);
      await prefs.remove(_lastLocationKey);
    } catch (e) {
      debugPrint('Error clearing weather cache: $e');
    }
  }

  /// Get mock weather data for demo purposes (when API key is not available)
  WeatherData getMockWeatherData() {
    return WeatherData(
      cityName: 'Demo City',
      countryCode: 'DC',
      temperature: 22.5,
      feelsLike: 24.0,
      humidity: 65,
      windSpeed: 3.2,
      description: 'partly cloudy',
      mainCondition: 'Clouds',
      iconCode: '02d',
      sunrise: DateTime.now().subtract(const Duration(hours: 2)),
      sunset: DateTime.now().add(const Duration(hours: 8)),
      latitude: 0.0,
      longitude: 0.0,
      timestamp: DateTime.now(),
    );
  }

  /// Get location-aware mock weather data
  WeatherData getMockWeatherDataForLocation(Position? position) {
    final now = DateTime.now();
    final hour = now.hour;

    // Location-based city name determination
    String cityName = 'Your Location';
    String countryCode = 'Demo';
    double lat = 0.0;
    double lon = 0.0;

    if (position != null) {
      lat = position.latitude;
      lon = position.longitude;

      // Determine approximate location based on coordinates
      if (lat >= 24.0 && lat <= 37.0 && lon >= 67.0 && lon <= 75.0) {
        cityName = 'Karachi'; // Pakistan region
        countryCode = 'PK';
      } else if (lat >= 40.0 && lat <= 41.0 && lon >= -74.0 && lon <= -73.0) {
        cityName = 'New York';
        countryCode = 'US';
      } else if (lat >= 51.0 && lat <= 52.0 && lon >= -1.0 && lon <= 0.0) {
        cityName = 'London';
        countryCode = 'GB';
      } else if (lat >= 25.0 && lat <= 26.0 && lon >= 55.0 && lon <= 56.0) {
        cityName = 'Dubai';
        countryCode = 'AE';
      } else if (lat >= 28.0 && lat <= 29.0 && lon >= 76.0 && lon <= 78.0) {
        cityName = 'Delhi';
        countryCode = 'IN';
      } else {
        // Use a generic name based on hemisphere
        if (lat > 0) {
          cityName = lat > 30 ? 'Northern City' : 'Tropical City';
        } else {
          cityName = 'Southern City';
        }
        countryCode = 'WW'; // World Wide
      }
    }

    // Dynamic weather based on time and location
    String condition;
    String iconCode;
    double baseTemp;

    // Adjust base temperature based on approximate location
    if (countryCode == 'AE') {
      // Dubai - Hot
      baseTemp = 30.0;
    } else if (countryCode == 'GB') {
      // London - Cool
      baseTemp = 15.0;
    } else if (countryCode == 'PK' || countryCode == 'IN') {
      // South Asia - Warm
      baseTemp = 25.0;
    } else {
      // Default moderate
      baseTemp = 20.0;
    }

    // Time-based weather variation
    double temp;
    if (hour >= 6 && hour < 12) {
      // Morning
      condition = 'Clear';
      iconCode = '01d';
      temp = baseTemp - 5 + (hour - 6) * 1.5; // Gradually warming up
    } else if (hour >= 12 && hour < 18) {
      // Afternoon - Peak temperature
      condition = hour % 2 == 0 ? 'Clear' : 'Clouds';
      iconCode = hour % 2 == 0 ? '01d' : '02d';
      temp = baseTemp + 3 + (hour - 12) * 0.5;
    } else if (hour >= 18 && hour < 22) {
      // Evening
      condition = 'Clear';
      iconCode = hour > 19 ? '01n' : '01d';
      temp = baseTemp + 2 - (hour - 18) * 1.2; // Cooling down
    } else {
      // Night
      condition = 'Clear';
      iconCode = '01n';
      temp = baseTemp - 8 + (hour > 22 ? (hour - 22) : (hour + 2)) * 0.3;
    }

    // Add some randomness based on day of year
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    temp += (dayOfYear % 7 - 3) * 0.5; // ±1.5°C variation

    final humidity = 50 + (hour % 5) * 8 + (dayOfYear % 3) * 5; // 50-85% range

    return WeatherData(
      cityName: cityName,
      countryCode: countryCode,
      temperature: temp,
      feelsLike: temp + 2.0 + (humidity > 70 ? 3.0 : 0.0),
      humidity: humidity,
      windSpeed: 1.5 + (hour % 4) * 1.2 + (lat.abs() > 30 ? 1.0 : 0.0),
      description: condition.toLowerCase(),
      mainCondition: condition,
      iconCode: iconCode,
      sunrise: DateTime(now.year, now.month, now.day, 6, 30),
      sunset: DateTime(now.year, now.month, now.day, 19, 15),
      latitude: lat,
      longitude: lon,
      timestamp: now,
    );
  }

  /// Get mock forecast data for demo
  List<WeatherForecast> getMockForecastData() {
    final now = DateTime.now();
    return List.generate(5, (index) {
      return WeatherForecast(
        date: now.add(Duration(days: index + 1)),
        temperature: 20.0 + (index * 2),
        minTemperature: 15.0 + (index * 1.5),
        maxTemperature: 25.0 + (index * 2.5),
        description: [
          'sunny',
          'cloudy',
          'rainy',
          'partly cloudy',
          'clear'
        ][index],
        mainCondition: ['Clear', 'Clouds', 'Rain', 'Clouds', 'Clear'][index],
        iconCode: ['01d', '03d', '10d', '02d', '01d'][index],
        humidity: 60 + (index * 5),
        windSpeed: 2.0 + (index * 0.5),
      );
    });
  }

  /// Generate location-aware mock forecast data based on coordinates
  List<WeatherForecast> getMockForecastDataForLocation(Position? position) {
    final now = DateTime.now();

    // Default values
    double baseTemp = 20.0;
    List<String> weatherPatterns = [
      'Clear',
      'Clouds',
      'Rain',
      'Clouds',
      'Clear'
    ];
    List<String> descriptions = [
      'sunny',
      'cloudy',
      'rainy',
      'partly cloudy',
      'clear'
    ];
    List<String> icons = ['01d', '03d', '10d', '02d', '01d'];

    if (position != null) {
      final lat = position.latitude;
      final lon = position.longitude;

      // Detect geographic region and adjust forecast accordingly
      if (lat >= 23.5 && lat <= 37.5 && lon >= 60.0 && lon <= 77.5) {
        // Pakistan region - hot, dry climate with occasional rain
        baseTemp = 25.0;
        weatherPatterns = ['Clear', 'Clear', 'Clouds', 'Clear', 'Clouds'];
        descriptions = [
          'hot and sunny',
          'clear skies',
          'partly cloudy',
          'sunny',
          'cloudy'
        ];
        icons = ['01d', '01d', '03d', '01d', '03d'];
      } else if (lat >= 25.0 && lat <= 26.5 && lon >= 55.0 && lon <= 56.5) {
        // UAE region - very hot, desert climate
        baseTemp = 30.0;
        weatherPatterns = ['Clear', 'Clear', 'Clear', 'Clouds', 'Clear'];
        descriptions = [
          'hot and sunny',
          'desert heat',
          'scorching sun',
          'hazy',
          'clear desert sky'
        ];
        icons = ['01d', '01d', '01d', '03d', '01d'];
      } else if (lat >= 50.0 && lat <= 60.0 && lon >= -8.0 && lon <= 2.0) {
        // UK region - cool, rainy climate
        baseTemp = 15.0;
        weatherPatterns = ['Clouds', 'Rain', 'Clouds', 'Rain', 'Clouds'];
        descriptions = [
          'cloudy',
          'light rain',
          'overcast',
          'drizzle',
          'grey skies'
        ];
        icons = ['03d', '10d', '04d', '09d', '03d'];
      } else if (lat >= 40.0 && lat <= 45.0 && lon >= -75.0 && lon <= -70.0) {
        // US Northeast region - temperate climate
        baseTemp = 18.0;
        weatherPatterns = ['Clear', 'Clouds', 'Rain', 'Clear', 'Clouds'];
        descriptions = [
          'pleasant',
          'partly cloudy',
          'showers',
          'sunny',
          'cloudy'
        ];
        icons = ['01d', '02d', '10d', '01d', '03d'];
      } else if (lat >= 20.0 && lat <= 35.0 && lon >= 68.0 && lon <= 97.0) {
        // India region - tropical/subtropical climate
        baseTemp = 24.0;
        weatherPatterns = ['Clear', 'Clouds', 'Rain', 'Clouds', 'Clear'];
        descriptions = [
          'warm and sunny',
          'humid clouds',
          'monsoon rain',
          'muggy',
          'clear and warm'
        ];
        icons = ['01d', '03d', '10d', '04d', '01d'];
      }
    }

    return List.generate(5, (index) {
      final dayOffset = index + 1;
      final forecastDate = now.add(Duration(days: dayOffset));

      // Add some randomness based on day of year (manual calculation)
      final dayOfYear =
          forecastDate.difference(DateTime(forecastDate.year, 1, 1)).inDays + 1;
      final randomFactor = (dayOfYear % 7) / 10.0;

      return WeatherForecast(
        date: forecastDate,
        temperature: baseTemp + (index * 1.5) + randomFactor,
        minTemperature: baseTemp - 5.0 + (index * 1.0) + randomFactor,
        maxTemperature: baseTemp + 5.0 + (index * 2.0) + randomFactor,
        description: descriptions[index],
        mainCondition: weatherPatterns[index],
        iconCode: icons[index],
        humidity: (50 + (index * 8) + (randomFactor * 10)).round(),
        windSpeed: 1.5 + (index * 0.7) + randomFactor,
      );
    });
  }
}
