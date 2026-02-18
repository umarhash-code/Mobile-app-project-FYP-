import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer_times.dart';

class PrayerTimesService {
  static const String _baseUrl = 'http://api.aladhan.com/v1';
  static const String _cacheKey = 'cached_prayer_times';
  static const String _lastUpdateKey = 'last_prayer_update';
  static const String _locationKey = 'last_location';

  // Get prayer times based on current location
  Future<PrayerTimes?> getPrayerTimes() async {
    try {
      // Try to get cached data first
      final cachedData = await _getCachedPrayerTimes();
      if (cachedData != null && await _isCacheValid()) {
        return cachedData;
      }

      // Get fresh data
      final position = await _getCurrentLocation();
      if (position != null) {
        final prayerTimes = await _fetchPrayerTimesFromAPI(
          position.latitude,
          position.longitude,
        );

        if (prayerTimes != null) {
          await _cachePrayerTimes(prayerTimes);
        }

        return prayerTimes;
      }

      // Fallback to cached data if available
      return cachedData;
    } catch (e) {
      // Debug: 'Error getting prayer times: $e'

      // Return cached data as fallback
      return await _getCachedPrayerTimes();
    }
  } // Get prayer times for specific coordinates

  Future<PrayerTimes?> getPrayerTimesForLocation(
    double latitude,
    double longitude,
  ) async {
    try {
      return await _fetchPrayerTimesFromAPI(latitude, longitude);
    } catch (e) {
      // Debug: 'Error getting prayer times for location: $e'
      return null;
    }
  }

  // Get prayer times for a specific city
  Future<PrayerTimes?> getPrayerTimesForCity(
      String city, String country) async {
    try {
      final url = '$_baseUrl/timingsByCity?city=$city&country=$country';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          return PrayerTimes.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      // Debug: 'Error getting prayer times for city: $e'
      return null;
    }
  }

  // Private method to fetch from API
  Future<PrayerTimes?> _fetchPrayerTimesFromAPI(
    double latitude,
    double longitude,
  ) async {
    final url =
        '$_baseUrl/timings?latitude=$latitude&longitude=$longitude&method=2';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['code'] == 200) {
        return PrayerTimes.fromJson(data);
      }
    }

    throw Exception('Failed to fetch prayer times: ${response.statusCode}');
  }

  // Get current location
  Future<Position?> _getCurrentLocation() async {
    try {
      // Check location permission
      final permission = await Permission.location.request();
      if (!permission.isGranted) {
        return null;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      // Cache the location
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _locationKey, '${position.latitude},${position.longitude}');

      return position;
    } catch (e) {
      // Debug: 'Error getting location: $e'

      // Try to use cached location
      final prefs = await SharedPreferences.getInstance();
      final cachedLocation = prefs.getString(_locationKey);
      if (cachedLocation != null) {
        final coords = cachedLocation.split(',');
        return Position(
          latitude: double.parse(coords[0]),
          longitude: double.parse(coords[1]),
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }

      return null;
    }
  }

  // Cache prayer times
  Future<void> _cachePrayerTimes(PrayerTimes prayerTimes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'fajr': prayerTimes.fajr,
        'sunrise': prayerTimes.sunrise,
        'dhuhr': prayerTimes.dhuhr,
        'asr': prayerTimes.asr,
        'maghrib': prayerTimes.maghrib,
        'isha': prayerTimes.isha,
        'date': prayerTimes.date,
        'city': prayerTimes.city,
        'country': prayerTimes.country,
      };

      await prefs.setString(_cacheKey, json.encode(data));
      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Debug: 'Error caching prayer times: $e'
    }
  }

  // Get cached prayer times
  Future<PrayerTimes?> _getCachedPrayerTimes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);

      if (cachedData != null) {
        final data = json.decode(cachedData);
        return PrayerTimes(
          fajr: data['fajr'],
          sunrise: data['sunrise'],
          dhuhr: data['dhuhr'],
          asr: data['asr'],
          maghrib: data['maghrib'],
          isha: data['isha'],
          date: data['date'],
          city: data['city'],
          country: data['country'],
        );
      }
    } catch (e) {
      // Debug: 'Error getting cached prayer times: $e'
    }
    return null;
  }

  // Check if cache is valid (refresh daily)
  Future<bool> _isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getInt(_lastUpdateKey);
      if (lastUpdate == null) return false;

      final lastUpdateDate = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
      final now = DateTime.now();

      // Cache is valid if it's from today
      return lastUpdateDate.day == now.day &&
          lastUpdateDate.month == now.month &&
          lastUpdateDate.year == now.year;
    } catch (e) {
      return false;
    }
  } // Clear cache

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_lastUpdateKey);
    } catch (e) {
      // Debug: 'Error clearing cache: $e'
    }
  }

  // Check location permission status
  Future<bool> isLocationPermissionGranted() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  // Request location permission
  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
}


