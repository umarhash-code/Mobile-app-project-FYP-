class WeatherData {
  final String cityName;
  final String countryCode;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final String description;
  final String mainCondition;
  final String iconCode;
  final DateTime sunrise;
  final DateTime sunset;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  WeatherData({
    required this.cityName,
    required this.countryCode,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.mainCondition,
    required this.iconCode,
    required this.sunrise,
    required this.sunset,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      cityName: json['name'] ?? 'Unknown',
      countryCode: json['sys']['country'] ?? 'XX',
      temperature: (json['main']['temp'] as num).toDouble(),
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      humidity: json['main']['humidity'] ?? 0,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      description: json['weather'][0]['description'] ?? 'Clear',
      mainCondition: json['weather'][0]['main'] ?? 'Clear',
      iconCode: json['weather'][0]['icon'] ?? '01d',
      sunrise: DateTime.fromMillisecondsSinceEpoch(
        (json['sys']['sunrise'] as int) * 1000,
      ),
      sunset: DateTime.fromMillisecondsSinceEpoch(
        (json['sys']['sunset'] as int) * 1000,
      ),
      latitude: (json['coord']['lat'] as num).toDouble(),
      longitude: (json['coord']['lon'] as num).toDouble(),
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cityName': cityName,
      'countryCode': countryCode,
      'temperature': temperature,
      'feelsLike': feelsLike,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'description': description,
      'mainCondition': mainCondition,
      'iconCode': iconCode,
      'sunrise': sunrise.millisecondsSinceEpoch,
      'sunset': sunset.millisecondsSinceEpoch,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  // Helper methods
  String get temperatureCelsius => '${temperature.round()}°C';
  String get temperatureFahrenheit => '${(temperature * 9 / 5 + 32).round()}°F';
  String get capitalizedDescription => description
      .split(' ')
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');

  // Weather condition helpers
  bool get isDay {
    final now = DateTime.now();
    return now.isAfter(sunrise) && now.isBefore(sunset);
  }

  String get weatherIconUrl =>
      'https://openweathermap.org/img/wn/$iconCode@2x.png';

  // Weather condition categories
  bool get isClear => mainCondition.toLowerCase() == 'clear';
  bool get isCloudy => mainCondition.toLowerCase() == 'clouds';
  bool get isRainy => mainCondition.toLowerCase().contains('rain');
  bool get isSnowy => mainCondition.toLowerCase() == 'snow';
  bool get isThunderstorm => mainCondition.toLowerCase() == 'thunderstorm';
  bool get isFoggy =>
      ['mist', 'fog', 'haze'].contains(mainCondition.toLowerCase());
}

class WeatherForecast {
  final DateTime date;
  final double temperature;
  final double minTemperature;
  final double maxTemperature;
  final String description;
  final String mainCondition;
  final String iconCode;
  final int humidity;
  final double windSpeed;

  WeatherForecast({
    required this.date,
    required this.temperature,
    required this.minTemperature,
    required this.maxTemperature,
    required this.description,
    required this.mainCondition,
    required this.iconCode,
    required this.humidity,
    required this.windSpeed,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      date: DateTime.fromMillisecondsSinceEpoch(
        (json['dt'] as int) * 1000,
      ),
      temperature: (json['main']['temp'] as num).toDouble(),
      minTemperature: (json['main']['temp_min'] as num).toDouble(),
      maxTemperature: (json['main']['temp_max'] as num).toDouble(),
      description: json['weather'][0]['description'] ?? 'Clear',
      mainCondition: json['weather'][0]['main'] ?? 'Clear',
      iconCode: json['weather'][0]['icon'] ?? '01d',
      humidity: json['main']['humidity'] ?? 0,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
    );
  }

  String get temperatureCelsius => '${temperature.round()}°C';
  String get minTempCelsius => '${minTemperature.round()}°C';
  String get maxTempCelsius => '${maxTemperature.round()}°C';
  String get weatherIconUrl =>
      'https://openweathermap.org/img/wn/$iconCode@2x.png';
  String get dayName =>
      ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][date.weekday % 7];
}
