import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_data.dart';

class DynamicWeatherService {
  // Dynamic weather API with real data and intelligent fallbacks
  static const bool _useRealAPI = false; // Disabled until API key is added

  // OpenWeatherMap API - Free tier with good Pakistan coverage
  static const String _apiKey =
      'your_api_key_here'; // Replace with real API key
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  // Pakistani cities with enhanced data
  static const List<Map<String, dynamic>> _pakistaniCities = [
    {
      'name': 'Karachi',
      'lat': 24.8607,
      'lon': 67.0011,
      'temp_base': 28.0,
      'climate': 'coastal',
      'elevation': 8,
    },
    {
      'name': 'Lahore',
      'lat': 31.5804,
      'lon': 74.3587,
      'temp_base': 25.0,
      'climate': 'continental',
      'elevation': 217,
    },
    {
      'name': 'Islamabad',
      'lat': 33.6844,
      'lon': 73.0479,
      'temp_base': 22.0,
      'climate': 'subtropical',
      'elevation': 540,
    },
    {
      'name': 'Rawalpindi',
      'lat': 33.5965,
      'lon': 73.0516,
      'temp_base': 23.0,
      'climate': 'subtropical',
      'elevation': 518,
    },
    {
      'name': 'Faisalabad',
      'lat': 31.4504,
      'lon': 73.1350,
      'temp_base': 26.0,
      'climate': 'semi-arid',
      'elevation': 184,
    },
    {
      'name': 'Multan',
      'lat': 30.1575,
      'lon': 71.5249,
      'temp_base': 27.0,
      'climate': 'arid',
      'elevation': 122,
    },
    {
      'name': 'Peshawar',
      'lat': 34.0151,
      'lon': 71.5249,
      'temp_base': 21.0,
      'climate': 'semi-arid',
      'elevation': 359,
    },
    {
      'name': 'Quetta',
      'lat': 30.1798,
      'lon': 66.9750,
      'temp_base': 18.0,
      'climate': 'cold semi-arid',
      'elevation': 1680,
    },
  ];

  // Cache configuration
  static const String _cacheKey = 'dynamic_weather_cache';
  static const String _lastUpdateKey = 'last_weather_update';
  static const Duration _cacheValidDuration = Duration(minutes: 20);

  /// Get current weather with dynamic API integration
  Future<WeatherData?> getCurrentWeather() async {
    try {
      debugPrint('DynamicWeatherService: Starting getCurrentWeather()');

      // Get current location
      final position = await _getCurrentPosition();
      debugPrint(
          'DynamicWeatherService: Got position: ${position?.latitude}, ${position?.longitude}');

      // Try cached data first
      final cachedWeather = await _getCachedWeather();
      if (cachedWeather != null) {
        debugPrint('DynamicWeatherService: Using cached weather data');
        return cachedWeather;
      }

      WeatherData? weatherData;

      if (_useRealAPI && _apiKey != 'your_api_key_here') {
        // Try real API first
        debugPrint('DynamicWeatherService: Attempting real API call...');
        if (position != null) {
          weatherData = await _fetchRealWeatherByCoordinates(
              position.latitude, position.longitude);
        } else {
          // Use Karachi as default for real API
          weatherData = await _fetchRealWeatherByCity('Karachi');
        }
      } else {
        debugPrint('DynamicWeatherService: Real API disabled, using fallback');
      }

      // Fallback to intelligent mock data if API fails
      if (weatherData == null) {
        debugPrint(
            'DynamicWeatherService: Using intelligent fallback weather data');
        weatherData = _generateIntelligentWeatherData(position);
      }

      // Cache the result
      await _cacheWeatherData(weatherData);

      debugPrint(
          'DynamicWeatherService: Returning weather for ${weatherData.cityName}');
      return weatherData;
    } catch (e) {
      debugPrint('DynamicWeatherService: Error in getCurrentWeather: $e');
      return _generateIntelligentWeatherData(null);
    }
  }

  /// Fetch real weather data from OpenWeatherMap API
  Future<WeatherData?> _fetchRealWeatherByCoordinates(
      double lat, double lon) async {
    try {
      final url = Uri.parse(
          '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric');

      debugPrint('Making API call to: ${url.toString()}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Real weather API success!');
        return _parseOpenWeatherResponse(data);
      } else {
        debugPrint('API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching real weather by coordinates: $e');
      return null;
    }
  }

  /// Fetch real weather data by city name
  Future<WeatherData?> _fetchRealWeatherByCity(String cityName) async {
    try {
      final url = Uri.parse(
          '$_baseUrl/weather?q=$cityName,PK&appid=$_apiKey&units=metric');

      debugPrint('Making API call for city: $cityName');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Real weather API success for $cityName!');
        return _parseOpenWeatherResponse(data);
      } else {
        debugPrint('API error for $cityName: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching real weather for $cityName: $e');
      return null;
    }
  }

  /// Parse OpenWeatherMap API response
  WeatherData _parseOpenWeatherResponse(Map<String, dynamic> data) {
    final main = data['main'];
    final weather = data['weather'][0];
    final wind = data['wind'] ?? {};
    final sys = data['sys'] ?? {};
    final coord = data['coord'] ?? {};

    return WeatherData(
      cityName: data['name'] ?? 'Unknown',
      countryCode: sys['country'] ?? 'PK',
      temperature: (main['temp'] as num).toDouble(),
      feelsLike: (main['feels_like'] as num).toDouble(),
      humidity: main['humidity'] as int,
      windSpeed: ((wind['speed'] as num?) ?? 0).toDouble(),
      description: weather['description'] ?? 'clear',
      mainCondition: weather['main'] ?? 'Clear',
      iconCode: weather['icon'] ?? '01d',
      sunrise: sys['sunrise'] != null
          ? DateTime.fromMillisecondsSinceEpoch(sys['sunrise'] * 1000)
          : DateTime.now().subtract(const Duration(hours: 2)),
      sunset: sys['sunset'] != null
          ? DateTime.fromMillisecondsSinceEpoch(sys['sunset'] * 1000)
          : DateTime.now().add(const Duration(hours: 8)),
      latitude: ((coord['lat'] as num?) ?? 0).toDouble(),
      longitude: ((coord['lon'] as num?) ?? 0).toDouble(),
      timestamp: DateTime.now(),
    );
  }

  /// Generate intelligent weather data with real-time patterns
  WeatherData _generateIntelligentWeatherData(Position? position) {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final month = now.month;
    final day = now.day;

    // Select appropriate city
    Map<String, dynamic> selectedCity;

    if (position != null &&
        _isInPakistanRegion(position.latitude, position.longitude)) {
      selectedCity = _findNearestCity(position.latitude, position.longitude);
    } else {
      // Intelligent city rotation based on time
      final cityIndex = (day + hour) % _pakistaniCities.length;
      selectedCity = _pakistaniCities[cityIndex];
    }

    // Real-time temperature calculation
    final baseTemp = selectedCity['temp_base'] as double;
    final climate = selectedCity['climate'] as String;
    final elevation = selectedCity['elevation'] as int;

    // Calculate intelligent temperature
    final temp = _calculateIntelligentTemperature(
        baseTemp, climate, elevation, month, hour, minute);

    // Calculate intelligent weather conditions
    final conditions =
        _getIntelligentWeatherConditions(climate, month, hour, temp);

    // Calculate intelligent humidity and wind
    final humidity = _calculateIntelligentHumidity(climate, month, hour, temp);
    final windSpeed =
        _calculateIntelligentWind(climate, elevation, month, hour);

    return WeatherData(
      cityName: selectedCity['name'],
      countryCode: 'PK',
      temperature: temp,
      feelsLike: temp + _calculateHeatIndex(temp, humidity),
      humidity: humidity,
      windSpeed: windSpeed,
      description: conditions['description']!,
      mainCondition: conditions['condition']!,
      iconCode: conditions['icon']!,
      sunrise: DateTime(now.year, now.month, now.day, 6, 15),
      sunset: DateTime(now.year, now.month, now.day, 18, 45),
      latitude: selectedCity['lat'],
      longitude: selectedCity['lon'],
      timestamp: now,
    );
  }

  /// Calculate intelligent temperature based on multiple factors
  double _calculateIntelligentTemperature(double baseTemp, String climate,
      int elevation, int month, int hour, int minute) {
    double temp = baseTemp;

    // Seasonal adjustment
    switch (month) {
      case 12:
      case 1:
      case 2: // Winter
        temp -= 8.0;
        break;
      case 3:
      case 4:
      case 5: // Spring
        temp += 0.0;
        break;
      case 6:
      case 7:
      case 8: // Summer
        temp += 8.0;
        break;
      case 9:
      case 10:
      case 11: // Autumn
        temp += 2.0;
        break;
    }

    // Climate-specific adjustments
    switch (climate) {
      case 'coastal':
        temp += 2.0; // Sea breeze effect
        break;
      case 'arid':
        temp += 3.0; // Desert heat
        break;
      case 'cold semi-arid':
        temp -= 5.0; // Mountain coolness
        break;
      case 'subtropical':
        temp += 1.0; // Moderate adjustment
        break;
    }

    // Elevation effect (lapse rate: ~6.5°C per 1000m)
    temp -= (elevation / 1000.0) * 6.5;

    // Hourly temperature curve
    if (hour >= 0 && hour < 6) {
      temp -= 6.0 + (6 - hour) * 0.5; // Coolest before dawn
    } else if (hour >= 6 && hour < 12) {
      temp += (hour - 6) * 1.5; // Rising temperature
    } else if (hour >= 12 && hour < 16) {
      temp += 6.0 + (hour - 12) * 0.5; // Peak heat
    } else if (hour >= 16 && hour < 20) {
      temp += 8.0 - (hour - 16) * 1.5; // Cooling down
    } else {
      temp += 2.0 - (hour - 20) * 1.0; // Evening cool
    }

    // Minute-level variation for dynamic feel
    final minuteVariation = sin(minute * pi / 30) * 0.5; // ±0.5°C sine wave
    temp += minuteVariation;

    return double.parse(temp.toStringAsFixed(1));
  }

  /// Get intelligent weather conditions
  Map<String, String> _getIntelligentWeatherConditions(
      String climate, int month, int hour, double temp) {
    // Base conditions by climate and season
    List<Map<String, String>> possibleConditions;

    if (month >= 7 && month <= 9) {
      // Monsoon season
      possibleConditions = [
        {'condition': 'Clouds', 'description': 'monsoon clouds', 'icon': '04d'},
        {'condition': 'Rain', 'description': 'light rain', 'icon': '10d'},
        {
          'condition': 'Thunderstorm',
          'description': 'thunderstorm',
          'icon': '11d'
        },
      ];
    } else if (month >= 12 || month <= 2) {
      // Winter
      if (climate == 'subtropical' || climate == 'continental') {
        possibleConditions = [
          {'condition': 'Fog', 'description': 'morning fog', 'icon': '50d'},
          {
            'condition': 'Clear',
            'description': 'clear winter sky',
            'icon': '01d'
          },
          {
            'condition': 'Clouds',
            'description': 'winter clouds',
            'icon': '03d'
          },
        ];
      } else {
        possibleConditions = [
          {
            'condition': 'Clear',
            'description': 'clear and cool',
            'icon': '01d'
          },
          {
            'condition': 'Clouds',
            'description': 'partly cloudy',
            'icon': '02d'
          },
        ];
      }
    } else if (month >= 6 && month <= 8) {
      // Summer
      if (climate == 'arid' || climate == 'semi-arid') {
        possibleConditions = [
          {'condition': 'Clear', 'description': 'hot and sunny', 'icon': '01d'},
          {'condition': 'Haze', 'description': 'heat haze', 'icon': '50d'},
        ];
      } else {
        possibleConditions = [
          {
            'condition': 'Clear',
            'description': 'hot summer day',
            'icon': '01d'
          },
          {
            'condition': 'Clouds',
            'description': 'partly cloudy',
            'icon': '02d'
          },
        ];
      }
    } else {
      // Spring/Autumn
      possibleConditions = [
        {
          'condition': 'Clear',
          'description': 'pleasant weather',
          'icon': '01d'
        },
        {'condition': 'Clouds', 'description': 'partly cloudy', 'icon': '02d'},
        {'condition': 'Clear', 'description': 'clear skies', 'icon': '01d'},
      ];
    }

    // Select condition based on temperature and time
    int index = 0;
    if (temp > 35) {
      index = 0; // Hot = clear/haze
    } else if (temp < 15) {
      index = min(1, possibleConditions.length - 1); // Cool = fog/clouds
    } else {
      index = (hour + DateTime.now().day) % possibleConditions.length;
    }

    final selected = possibleConditions[index];

    // Adjust icon for day/night
    String icon = selected['icon']!;
    if ((hour < 6 || hour >= 19) && !icon.contains('n')) {
      icon = icon.replaceAll('d', 'n');
    }

    return {
      'condition': selected['condition']!,
      'description': selected['description']!,
      'icon': icon,
    };
  }

  /// Calculate intelligent humidity
  int _calculateIntelligentHumidity(
      String climate, int month, int hour, double temp) {
    int baseHumidity;

    // Base humidity by climate
    switch (climate) {
      case 'coastal':
        baseHumidity = 70;
        break;
      case 'arid':
      case 'semi-arid':
        baseHumidity = 35;
        break;
      case 'cold semi-arid':
        baseHumidity = 45;
        break;
      default:
        baseHumidity = 55;
    }

    // Seasonal adjustment
    if (month >= 7 && month <= 9) {
      // Monsoon
      baseHumidity += 25;
    } else if (month >= 12 || month <= 2) {
      // Winter
      baseHumidity += 10;
    }

    // Daily cycle
    if (hour >= 3 && hour < 9) {
      // Early morning peak
      baseHumidity += 15;
    } else if (hour >= 12 && hour < 17) {
      // Afternoon low
      baseHumidity -= 15;
    }

    // Temperature effect (higher temp = lower humidity)
    if (temp > 30) {
      baseHumidity -= 10;
    } else if (temp < 20) {
      baseHumidity += 10;
    }

    return baseHumidity.clamp(20, 95);
  }

  /// Calculate intelligent wind speed
  double _calculateIntelligentWind(
      String climate, int elevation, int month, int hour) {
    double baseWind = 2.0;

    // Climate effects
    if (climate == 'coastal') baseWind = 4.0;
    if (climate == 'arid') baseWind = 3.0;

    // Elevation effect (higher = more wind)
    baseWind += elevation / 1000.0;

    // Seasonal patterns
    if (month >= 4 && month <= 6) baseWind += 1.5; // Pre-monsoon winds
    if (month >= 7 && month <= 9) baseWind += 1.0; // Monsoon

    // Daily variation
    if (hour >= 12 && hour < 18) baseWind += 1.5; // Afternoon thermal winds
    if (hour >= 0 && hour < 6) baseWind -= 1.0; // Calm night

    // Random variation
    final random = Random(DateTime.now().minute);
    baseWind += (random.nextDouble() - 0.5) * 2.0;

    return double.parse(baseWind.clamp(0.5, 8.0).toStringAsFixed(1));
  }

  /// Calculate heat index for feels-like temperature
  double _calculateHeatIndex(double temp, int humidity) {
    if (temp < 27) return 1.0; // No heat index below 27°C

    // Simplified heat index calculation
    final hi = -8.78469475556 +
        1.61139411 * temp +
        2.33854883889 * humidity +
        -0.14611605 * temp * humidity +
        -0.012308094 * temp * temp +
        -0.0164248277778 * humidity * humidity +
        0.002211732 * temp * temp * humidity +
        0.00072546 * temp * humidity * humidity +
        -0.000003582 * temp * temp * humidity * humidity;

    return (hi - temp).clamp(0.0, 8.0);
  }

  // Helper methods
  bool _isInPakistanRegion(double lat, double lon) {
    return lat >= 23.5 && lat <= 37.5 && lon >= 60.0 && lon <= 77.5;
  }

  Map<String, dynamic> _findNearestCity(double lat, double lon) {
    double minDistance = double.infinity;
    Map<String, dynamic> nearestCity = _pakistaniCities[0];

    for (final city in _pakistaniCities) {
      final distance =
          sqrt(pow(lat - city['lat'], 2) + pow(lon - city['lon'], 2));
      if (distance < minDistance) {
        minDistance = distance;
        nearestCity = city;
      }
    }
    return nearestCity;
  }

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
      if (DateTime.now().difference(lastUpdate) > _cacheValidDuration) {
        return null;
      }

      final weatherDataString = prefs.getString(_cacheKey);
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
      await prefs.setString(_cacheKey, json.encode(weatherData.toJson()));
      await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error caching weather data: $e');
    }
  }

  // Public methods for forecast and city search
  Future<List<WeatherForecast>?> getWeatherForecast() async {
    try {
      final position = await _getCurrentPosition();

      if (_useRealAPI && _apiKey != 'your_api_key_here') {
        return await _fetchRealForecast(position);
      }

      return _generateIntelligentForecast(position);
    } catch (e) {
      debugPrint('Error getting forecast: $e');
      return _generateIntelligentForecast(null);
    }
  }

  Future<List<WeatherForecast>?> _fetchRealForecast(Position? position) async {
    try {
      String url;
      if (position != null) {
        url =
            '$_baseUrl/forecast?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric';
      } else {
        url = '$_baseUrl/forecast?q=Karachi,PK&appid=$_apiKey&units=metric';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseRealForecast(data);
      }
    } catch (e) {
      debugPrint('Error fetching real forecast: $e');
    }
    return null;
  }

  List<WeatherForecast> _parseRealForecast(Map<String, dynamic> data) {
    final List<dynamic> list = data['list'];
    final Map<String, WeatherForecast> dailyForecasts = {};

    for (final item in list) {
      final forecast = WeatherForecast(
        date: DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000),
        temperature: (item['main']['temp'] as num).toDouble(),
        minTemperature: (item['main']['temp_min'] as num).toDouble(),
        maxTemperature: (item['main']['temp_max'] as num).toDouble(),
        description: item['weather'][0]['description'],
        mainCondition: item['weather'][0]['main'],
        iconCode: item['weather'][0]['icon'],
        humidity: item['main']['humidity'],
        windSpeed: ((item['wind']['speed'] as num?) ?? 0).toDouble(),
      );

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

  List<WeatherForecast> _generateIntelligentForecast(Position? position) {
    final now = DateTime.now();
    final selectedCity = position != null &&
            _isInPakistanRegion(position.latitude, position.longitude)
        ? _findNearestCity(position.latitude, position.longitude)
        : _pakistaniCities[0];

    return List.generate(5, (index) {
      final forecastDate = now.add(Duration(days: index + 1));
      final climate = selectedCity['climate'];
      final baseTemp = selectedCity['temp_base'] as double;

      final temp = _calculateIntelligentTemperature(baseTemp, climate,
          selectedCity['elevation'], forecastDate.month, 12, 0);

      final conditions = _getIntelligentWeatherConditions(
          climate, forecastDate.month, 12, temp);

      return WeatherForecast(
        date: forecastDate,
        temperature: temp,
        minTemperature: temp - 8.0,
        maxTemperature: temp + 6.0,
        description: conditions['description']!,
        mainCondition: conditions['condition']!,
        iconCode: conditions['icon']!,
        humidity: _calculateIntelligentHumidity(
            climate, forecastDate.month, 12, temp),
        windSpeed: _calculateIntelligentWind(
            climate, selectedCity['elevation'], forecastDate.month, 12),
      );
    });
  }

  Future<WeatherData?> getWeatherByCity(String cityName) async {
    try {
      if (_useRealAPI && _apiKey != 'your_api_key_here') {
        final realData = await _fetchRealWeatherByCity(cityName);
        if (realData != null) return realData;
      }

      // Fallback to intelligent data
      final city = _pakistaniCities.firstWhere(
        (c) => c['name'].toLowerCase() == cityName.toLowerCase(),
        orElse: () => _pakistaniCities[0],
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

      return _generateIntelligentWeatherData(position);
    } catch (e) {
      debugPrint('Error getting weather for city $cityName: $e');
      return _generateIntelligentWeatherData(null);
    }
  }

  List<String> getPakistaniCities() {
    return _pakistaniCities.map((city) => city['name'] as String).toList();
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_lastUpdateKey);
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }
}
