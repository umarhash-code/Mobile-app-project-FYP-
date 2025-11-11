import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseRestAuth {
  static const String apiKey =
      'AIzaSyDEHB97w81qcKs9dgT_Xp0lrWUUO481JsE'; // Correct Firebase API key from google-services.json
  static const String baseUrl =
      'https://identitytoolkit.googleapis.com/v1/accounts';

  // Register using Firebase REST API to bypass Pigeon interface
  static Future<Map<String, dynamic>> registerWithRestAPI({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      debugPrint('🔥 REST: Starting REST API registration for: $email');

      // Step 1: Register with Firebase Auth REST API
      const registrationUrl = '$baseUrl:signUp?key=$apiKey';

      final registrationResponse = await http.post(
        Uri.parse(registrationUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );

      debugPrint(
          '🔥 REST: Registration response status: ${registrationResponse.statusCode}');
      debugPrint(
          '🔥 REST: Registration response body: ${registrationResponse.body}');

      if (registrationResponse.statusCode != 200) {
        final errorData = jsonDecode(registrationResponse.body);
        final errorMessage =
            errorData['error']['message'] ?? 'Registration failed';
        return {
          'success': false,
          'error': errorMessage,
        };
      }

      final registrationData = jsonDecode(registrationResponse.body);
      final uid = registrationData['localId'];
      final idToken = registrationData['idToken'];

      debugPrint('🔥 REST: Registration successful! UID: $uid');

      // Step 2: Save user data to Firestore
      final userData = {
        'uid': uid,
        'email': email,
        'fullName': fullName,
        'createdAt': DateTime.now().toIso8601String(),
        'lastLoginAt': DateTime.now().toIso8601String(),
        'isActive': true,
      };

      debugPrint('🔥 REST: Saving user data to Firestore...');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(userData);

      debugPrint('🔥 REST: User data saved successfully!');

      return {
        'success': true,
        'uid': uid,
        'email': email,
        'fullName': fullName,
        'idToken': idToken,
      };
    } catch (e) {
      debugPrint('❌ REST: Registration error: $e');
      return {
        'success': false,
        'error': 'Registration failed: $e',
      };
    }
  }

  // Sign in using Firebase REST API
  static Future<Map<String, dynamic>> signInWithRestAPI({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔥 REST: Starting REST API sign in for: $email');

      const signInUrl = '$baseUrl:signInWithPassword?key=$apiKey';

      final signInResponse = await http.post(
        Uri.parse(signInUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );

      debugPrint(
          '🔥 REST: Sign in response status: ${signInResponse.statusCode}');
      debugPrint('🔥 REST: Sign in response body: ${signInResponse.body}');

      if (signInResponse.statusCode != 200) {
        final errorData = jsonDecode(signInResponse.body);
        final errorMessage = errorData['error']['message'] ?? 'Sign in failed';
        return {
          'success': false,
          'error': errorMessage,
        };
      }

      final signInData = jsonDecode(signInResponse.body);
      final uid = signInData['localId'];
      final idToken = signInData['idToken'];

      debugPrint('🔥 REST: Sign in successful! UID: $uid');

      return {
        'success': true,
        'uid': uid,
        'email': email,
        'idToken': idToken,
      };
    } catch (e) {
      debugPrint('❌ REST: Sign in error: $e');
      return {
        'success': false,
        'error': 'Sign in failed: $e',
      };
    }
  }

  // Verify token (optional)
  static Future<Map<String, dynamic>> verifyToken(String idToken) async {
    try {
      const verifyUrl = '$baseUrl:lookup?key=$apiKey';

      final verifyResponse = await http.post(
        Uri.parse(verifyUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'idToken': idToken,
        }),
      );

      if (verifyResponse.statusCode == 200) {
        final verifyData = jsonDecode(verifyResponse.body);
        return {
          'success': true,
          'data': verifyData,
        };
      } else {
        return {
          'success': false,
          'error': 'Token verification failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Token verification error: $e',
      };
    }
  }
}
