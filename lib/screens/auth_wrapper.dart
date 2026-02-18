import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'auth/sign_in_screen.dart';
import 'dashboard/dashboard_screen.dart';
import '../widgets/loading_screen.dart';
import '../services/rest_auth_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Consumer to listen to RestAuthService state changes
    return Consumer<RestAuthService>(
      builder: (context, authService, child) {
        // Show loading while authentication is in progress
        if (authService.isLoading) {
          return const LoadingScreen(message: 'Authenticating...');
        }

        // Check if user is authenticated
        if (authService.isSignedIn && authService.currentUser != null) {
          developer.log(
              'User is authenticated: ${authService.currentUser!.email}',
              name: 'AuthWrapper');
          return const DashboardScreen();
        } else {
          developer.log('User is not authenticated, showing sign in screen',
              name: 'AuthWrapper');
          return const SignInScreen();
        }
      },
    );
  }
}
