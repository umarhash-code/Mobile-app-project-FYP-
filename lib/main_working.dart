import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer' as developer;
import 'firebase_options.dart';
import 'services/rest_auth_service.dart';
import 'providers/theme_provider.dart';
import 'screens/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    developer.log('Firebase initialized successfully',
        name: 'EverydayChronicles');
  } catch (e) {
    developer.log('Firebase initialization failed: $e',
        name: 'EverydayChronicles');
  }

  developer.log('Starting Everyday Chronicles App', name: 'EverydayChronicles');
  runApp(const EverydayChroniclesApp());
}

class EverydayChroniclesApp extends StatelessWidget {
  const EverydayChroniclesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RestAuthService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadSettings()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Everyday Chronicles',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6B73FF),
                brightness: Brightness.light,
              ),
              textTheme: GoogleFonts.poppinsTextTheme(),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6B73FF),
                brightness: Brightness.dark,
              ),
              textTheme: GoogleFonts.poppinsTextTheme(),
            ),
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}
