import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/weather_data.dart';
import '../services/dynamic_weather_service.dart';

class WeatherWidget extends StatefulWidget {
  final double? height;
  final bool showForecast;

  const WeatherWidget({
    super.key,
    this.height,
    this.showForecast = false,
  });

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget>
    with SingleTickerProviderStateMixin {
  final DynamicWeatherService _weatherService = DynamicWeatherService();
  WeatherData? _currentWeather;
  bool _isLoading = true;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _loadWeatherData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadWeatherData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final weather = await _weatherService.getCurrentWeather();
      if (mounted) {
        setState(() {
          _currentWeather = weather;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshWeather() async {
    await _weatherService.clearCache();
    await _loadWeatherData();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: Container(
        decoration: _buildWeatherGradient(),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_currentWeather == null) {
      return _buildErrorWidget();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildCompactWeatherCard(),
    );
  }

  Widget _buildLoadingWidget() {
    return const Padding(
      padding: EdgeInsets.all(6),
      child: Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Weather unavailable',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadWeatherData,
              child: Text(
                'Retry',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactWeatherCard() {
    final weather = _currentWeather!;

    return Padding(
      padding: const EdgeInsets.all(6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Weather icon and temperature
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildWeatherIcon(weather.iconCode, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      weather.temperatureCelsius,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  weather.capitalizedDescription,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Location and details
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  weather.cityName,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                _buildDetailRow(
                    Icons.visibility, 'Feels ${weather.feelsLike.round()}°'),
                _buildDetailRow(Icons.water_drop, '${weather.humidity}%'),
                _buildDetailRow(
                    Icons.air, '${weather.windSpeed.toStringAsFixed(1)} m/s'),
              ],
            ),
          ),

          // Refresh button
          IconButton(
            onPressed: _refreshWeather,
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherIcon(String iconCode, {double size = 24}) {
    IconData iconData;
    switch (iconCode.toLowerCase()) {
      case '01d':
      case '01n':
        iconData = Icons.wb_sunny;
        break;
      case '02d':
      case '02n':
      case '03d':
      case '03n':
      case '04d':
      case '04n':
        iconData = Icons.wb_cloudy;
        break;
      case '09d':
      case '09n':
      case '10d':
      case '10n':
        iconData = Icons.umbrella;
        break;
      case '11d':
      case '11n':
        iconData = Icons.flash_on;
        break;
      case '13d':
      case '13n':
        iconData = Icons.ac_unit;
        break;
      case '50d':
      case '50n':
        iconData = Icons.foggy;
        break;
      default:
        iconData = Icons.wb_sunny;
    }

    return Icon(
      iconData,
      size: size,
      color: Colors.white,
    );
  }

  BoxDecoration _buildWeatherGradient() {
    final weather = _currentWeather;
    List<Color> colors;

    if (weather == null) {
      colors = [Colors.blue.shade300, Colors.blue.shade600];
    } else if (weather.isDay) {
      if (weather.isClear) {
        colors = [Colors.blue.shade300, Colors.blue.shade600];
      } else if (weather.isCloudy) {
        colors = [Colors.grey.shade400, Colors.grey.shade600];
      } else if (weather.isRainy) {
        colors = [Colors.indigo.shade400, Colors.indigo.shade700];
      } else {
        colors = [Colors.orange.shade300, Colors.orange.shade600];
      }
    } else {
      colors = [Colors.indigo.shade600, Colors.indigo.shade900];
    }

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: colors.last.withValues(alpha: 0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
