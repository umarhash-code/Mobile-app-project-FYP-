import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer' as developer;
import 'providers/theme_provider.dart';
import 'screens/dashboard/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  developer.log('Starting Everyday Chronicles App (Web)',
      name: 'EverydayChronicles');
  runApp(const EverydayChroniclesWebApp());
}

class EverydayChroniclesWebApp extends StatelessWidget {
  const EverydayChroniclesWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
              textTheme: GoogleFonts.poppinsTextTheme(
                Theme.of(context).textTheme.apply(
                      bodyColor: Colors.white,
                      displayColor: Colors.white,
                    ),
              ),
            ),
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const DashboardScreen(),
          );
        },
      ),
    );
  }
}
