import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class RestAuthService extends ChangeNotifier {
  static const String _apiKey = 'AIzaSyDEHB97w81qcKs9dgT_Xp0lrWUUO481JsE';
  static const String _baseUrl =
      'https://identitytoolkit.googleapis.com/v1/accounts';

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _currentToken;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isSignedIn => _currentUser != null && _currentToken != null;

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Register with email and password using REST API
  Future<UserModel?> registerWithEmailPassword(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      _setLoading(true);
      debugPrint('🔥 RestAuthService: Starting registration for: $email');

      // Step 1: Register with Firebase Auth REST API
      const registrationUrl = '$_baseUrl:signUp?key=$_apiKey';

      final registrationResponse = await http.post(
        Uri.parse(registrationUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );

      debugPrint(
          '🔥 RestAuthService: Registration response: ${registrationResponse.statusCode}');

      if (registrationResponse.statusCode != 200) {
        final errorData = jsonDecode(registrationResponse.body);
        final errorMessage =
            errorData['error']['message'] ?? 'Registration failed';
        throw Exception(errorMessage);
      }

      final registrationData = jsonDecode(registrationResponse.body);
      final uid = registrationData['localId'];
      _currentToken = registrationData['idToken'];

      debugPrint('🔥 RestAuthService: Registration successful! UID: $uid');

      // Step 2: Create user model and save to Firestore
      final user = UserModel(
        uid: uid,
        email: email,
        fullName: fullName,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isActive: true,
      );

      debugPrint('🔥 RestAuthService: Saving user data to Firestore...');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(user.toMap());

      _currentUser = user;
      _setLoading(false);
      notifyListeners(); // Explicitly notify that user state changed

      debugPrint('🔥 RestAuthService: Registration completed successfully!');
      return user;
    } catch (e) {
      _setLoading(false);
      debugPrint('❌ RestAuthService: Registration error: $e');
      throw Exception('Registration failed: $e');
    }
  }

  // Sign in with email and password using REST API
  Future<UserModel?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      _setLoading(true);
      debugPrint('🔥 RestAuthService: Starting sign in for: $email');

      // Step 1: Sign in with Firebase Auth REST API
      const signInUrl = '$_baseUrl:signInWithPassword?key=$_apiKey';

      final signInResponse = await http.post(
        Uri.parse(signInUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );

      debugPrint(
          '🔥 RestAuthService: Sign in response: ${signInResponse.statusCode}');

      if (signInResponse.statusCode != 200) {
        final errorData = jsonDecode(signInResponse.body);
        final errorMessage = errorData['error']['message'] ?? 'Sign in failed';
        throw Exception(errorMessage);
      }

      final signInData = jsonDecode(signInResponse.body);
      final uid = signInData['localId'];
      _currentToken = signInData['idToken'];

      debugPrint('🔥 RestAuthService: Sign in successful! UID: $uid');

      // Step 2: Fetch user data from Firestore
      debugPrint('🔥 RestAuthService: Fetching user data from Firestore...');

      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      final user = UserModel.fromMap(userDoc.data()!);

      // Update last login time
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'lastLoginAt': DateTime.now().toIso8601String()});

      _currentUser = user;
      _setLoading(false);
      notifyListeners(); // Explicitly notify that user state changed

      debugPrint('🔥 RestAuthService: Sign in completed successfully!');
      return user;
    } catch (e) {
      _setLoading(false);
      debugPrint('❌ RestAuthService: Sign in error: $e');
      throw Exception('Sign in failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      debugPrint('🔥 RestAuthService: Signing out...');

      _currentUser = null;
      _currentToken = null;
      notifyListeners();

      debugPrint('🔥 RestAuthService: Sign out completed');
    } catch (e) {
      debugPrint('❌ RestAuthService: Sign out error: $e');
      throw Exception('Sign out failed: $e');
    }
  }

  // Send password reset email using REST API
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      debugPrint('🔥 RestAuthService: Sending password reset email to: $email');

      const resetUrl = '$_baseUrl:sendOobCode?key=$_apiKey';

      final resetResponse = await http.post(
        Uri.parse(resetUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'requestType': 'PASSWORD_RESET',
          'email': email,
        }),
      );

      debugPrint(
          '🔥 RestAuthService: Password reset response: ${resetResponse.statusCode}');

      if (resetResponse.statusCode != 200) {
        final errorData = jsonDecode(resetResponse.body);
        final errorMessage =
            errorData['error']['message'] ?? 'Password reset failed';
        throw Exception(errorMessage);
      }

      debugPrint('🔥 RestAuthService: Password reset email sent successfully');
    } catch (e) {
      debugPrint('❌ RestAuthService: Password reset error: $e');
      throw Exception('Password reset failed: $e');
    }
  }

  // Verify token and get user info (useful for checking if user is still authenticated)
  Future<bool> verifyCurrentToken() async {
    if (_currentToken == null) return false;

    try {
      const verifyUrl = '$_baseUrl:lookup?key=$_apiKey';

      final verifyResponse = await http.post(
        Uri.parse(verifyUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': _currentToken,
        }),
      );

      return verifyResponse.statusCode == 200;
    } catch (e) {
      debugPrint('❌ RestAuthService: Token verification error: $e');
      return false;
    }
  }
}
