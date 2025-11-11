import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/weather_data.dart';
import '../../services/dynamic_weather_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with TickerProviderStateMixin {
  final DynamicWeatherService _weatherService = DynamicWeatherService();
  final TextEditingController _cityController = TextEditingController();
  WeatherData? _currentWeather;
  List<WeatherForecast>? _forecast;
  bool _isLoading = false;
  String? _error;

  late AnimationController _backgroundController;
  late AnimationController _cardController;
  late Animation<double> _backgroundAnimation;
  late Animation<Offset> _cardSlideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadWeatherData();
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_backgroundController);

    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutBack,
    ));

    _backgroundController.repeat();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _cardController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final weather = await _weatherService.getCurrentWeather();
      final forecast = await _weatherService.getWeatherForecast();

      setState(() {
        _currentWeather = weather;
        _forecast = forecast;
      });

      _cardController.forward();
    } catch (e) {
      setState(() {
        _error = 'Unable to load weather data';
        _currentWeather = null;
        _forecast = null;
      });
      _cardController.forward();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchWeather() async {
    if (_cityController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final weather =
          await _weatherService.getWeatherByCity(_cityController.text.trim());

      if (weather != null) {
        setState(() {
          _currentWeather = weather;
        });
        _cardController.reset();
        _cardController.forward();

        // Clear the search field
        _cityController.clear();
        if (mounted) {
          FocusScope.of(context).unfocus();
        }
      } else {
        setState(() {
          _error = 'City not found';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error searching for city';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: _buildAnimatedBackground(),
            child: SafeArea(
              child: Column(
                children: [
                  _buildAppBar(),
                  _buildSearchBar(),
                  Expanded(
                    child: _isLoading
                        ? _buildLoadingIndicator()
                        : _buildWeatherContent(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  BoxDecoration _buildAnimatedBackground() {
    final weather = _currentWeather;

    if (weather == null) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade300,
            Colors.blue.shade600,
          ],
        ),
      );
    }

    // Animated background based on weather
    List<Color> colors;
    final animationValue = _backgroundAnimation.value;

    if (weather.isDay) {
      if (weather.isClear) {
        colors = [
          Color.lerp(
              Colors.blue.shade300, Colors.cyan.shade300, animationValue)!,
          Color.lerp(
              Colors.blue.shade600, Colors.blue.shade700, animationValue)!,
        ];
      } else if (weather.isCloudy) {
        colors = [
          Color.lerp(
              Colors.grey.shade400, Colors.grey.shade300, animationValue)!,
          Color.lerp(
              Colors.grey.shade600, Colors.grey.shade700, animationValue)!,
        ];
      } else if (weather.isRainy) {
        colors = [
          Color.lerp(
              Colors.indigo.shade400, Colors.indigo.shade300, animationValue)!,
          Color.lerp(
              Colors.indigo.shade700, Colors.indigo.shade800, animationValue)!,
        ];
      } else {
        colors = [
          Color.lerp(
              Colors.orange.shade300, Colors.orange.shade400, animationValue)!,
          Color.lerp(
              Colors.orange.shade600, Colors.orange.shade700, animationValue)!,
        ];
      }
    } else {
      colors = [
        Color.lerp(
            Colors.indigo.shade800, Colors.purple.shade800, animationValue)!,
        Color.lerp(Colors.black87, Colors.indigo.shade900, animationValue)!,
      ];
    }

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          Expanded(
            child: Text(
              'Weather',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: _loadWeatherData,
            icon: const Icon(Icons.my_location, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: TextField(
              controller: _cityController,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search Pakistani city...',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                suffixIcon: IconButton(
                  onPressed: _searchWeather,
                  icon: const Icon(Icons.send, color: Colors.white),
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
              onSubmitted: (_) => _searchWeather(),
            ),
          ),
          const SizedBox(height: 8),
          _buildPakistaniCitiesRow(),
        ],
      ),
    );
  }

  Widget _buildPakistaniCitiesRow() {
    final cities = _weatherService.getPakistaniCities().take(6).toList();

    return SizedBox(
      height: 35,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cities.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                _cityController.text = cities[index];
                _searchWeather();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Text(
                  cities[index],
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(
        color: Colors.white,
        strokeWidth: 3,
      ),
    );
  }

  Widget _buildWeatherContent() {
    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_currentWeather == null) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _cardSlideAnimation,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Main weather card
              _buildMainWeatherCard(),

              const SizedBox(height: 16),

              // Hourly forecast
              if (_forecast != null && _forecast!.isNotEmpty)
                _buildForecastSection(),

              const SizedBox(height: 16),

              // Additional weather details
              _buildDetailsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 64),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadWeatherData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Retry',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainWeatherCard() {
    final weather = _currentWeather!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Location and date
          Text(
            '${weather.cityName}, ${weather.countryCode}',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Text(
            _formatDateTime(weather.timestamp),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),

          const SizedBox(height: 20),

          // Temperature and icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildWeatherIcon(weather.iconCode, size: 100),
              const SizedBox(width: 20),
              Column(
                children: [
                  Text(
                    weather.temperatureCelsius,
                    style: GoogleFonts.poppins(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    weather.capitalizedDescription,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForecastSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '5-Day Forecast',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _forecast!.length,
            itemBuilder: (context, index) {
              final forecast = _forecast![index];
              return _buildForecastCard(forecast);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildForecastCard(WeatherForecast forecast) {
    return Container(
      width: 90,
      height: 120, // Fixed height to match ListView
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              forecast.dayName,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          _buildWeatherIcon(forecast.iconCode, size: 28),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              forecast.maxTempCelsius,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            child: Text(
              forecast.minTempCelsius,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    final weather = _currentWeather!;

    return IntrinsicHeight(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Weather Details',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    Icons.thermostat,
                    'Feels like',
                    '${weather.feelsLike.round()}°C',
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    Icons.water_drop,
                    'Humidity',
                    '${weather.humidity}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    Icons.air,
                    'Wind Speed',
                    '${weather.windSpeed.toStringAsFixed(1)} m/s',
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    Icons.wb_sunny,
                    weather.isDay ? 'Sunset' : 'Sunrise',
                    _formatTime(
                        weather.isDay ? weather.sunset : weather.sunrise),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherIcon(String iconCode, {double size = 40}) {
    IconData iconData;

    switch (iconCode.substring(0, 2)) {
      case '01':
        iconData = Icons.wb_sunny;
        break;
      case '02':
        iconData = Icons.wb_cloudy;
        break;
      case '03':
      case '04':
        iconData = Icons.cloud;
        break;
      case '09':
      case '10':
        iconData = Icons.grain;
        break;
      case '11':
        iconData = Icons.flash_on;
        break;
      case '13':
        iconData = Icons.ac_unit;
        break;
      case '50':
        iconData = Icons.foggy;
        break;
      default:
        iconData = Icons.wb_sunny;
    }

    return Icon(
      iconData,
      color: Colors.white,
      size: size,
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    return '${weekdays[dateTime.weekday - 1]}, ${dateTime.day} ${months[dateTime.month - 1]}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
