import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/rest_auth_service.dart';
import '../../models/user_model.dart';
import '../journal/new_entry_screen.dart';
import '../journal/entries_list_screen.dart';
import '../weather/weather_screen.dart';
import '../settings/settings_screen.dart';
import '../app_usage_screen.dart';
import '../../widgets/prayer_times_widget.dart';
import '../../widgets/mindfulness_widget.dart';
import '../../widgets/weather_widget.dart';
import '../../widgets/step_counter_widget.dart';
import '../../widgets/app_usage_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UserModel? currentUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final authService = Provider.of<RestAuthService>(context, listen: false);
      final user = authService.currentUser;
      setState(() {
        currentUser = user;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      final authService = Provider.of<RestAuthService>(context, listen: false);
      await authService.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Good ${_getTimeOfDayGreeting()}!',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentUser?.firstName ?? 'User',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Profile Avatar and Menu
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'profile':
                                // Future feature: User profile management
                                break;
                              case 'settings':
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SettingsScreen(),
                                  ),
                                );
                                break;
                              case 'logout':
                                _signOut();
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'profile',
                              child: Row(
                                children: [
                                  Icon(Icons.person_outline),
                                  SizedBox(width: 12),
                                  Text('Profile'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'settings',
                              child: Row(
                                children: [
                                  Icon(Icons.settings_outlined),
                                  SizedBox(width: 12),
                                  Text('Settings'),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(Icons.logout, color: Colors.red),
                                  SizedBox(width: 12),
                                  Text('Sign Out',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            child: currentUser?.photoUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: Image.network(
                                      currentUser!.photoUrl!,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Text(
                                          currentUser?.initials ?? 'U',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : Text(
                                    currentUser?.initials ?? 'U',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Welcome Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.auto_stories_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Welcome to Everyday Chronicles',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start documenting your daily experiences, thoughts, and memories.',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // App Usage Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'App Usage',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const AppUsageScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'View Details',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // App Usage Widget
                    const AppUsageWidget(showDetailed: false),

                    const SizedBox(height: 32),

                    // Quick Actions Section
                    Text(
                      'Quick Actions',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Action Cards Grid
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildActionCard(
                          context,
                          icon: Icons.add_circle_outline,
                          title: 'New Entry',
                          subtitle: 'Write today\'s story',
                          color: Colors.blue,
                          onTap: () async {
                            // Navigate to new entry screen
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const NewEntryScreen(),
                              ),
                            );

                            // Refresh dashboard if entry was saved
                            if (result == true) {
                              _loadUserData(); // Refresh any data if needed
                            }
                          },
                        ),
                        _buildActionCard(
                          context,
                          icon: Icons.book_outlined,
                          title: 'My Entries',
                          subtitle: 'View past entries',
                          color: Colors.green,
                          onTap: () async {
                            // Navigate to entries list screen
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const EntriesListScreen(),
                              ),
                            );

                            // Refresh dashboard if needed
                            if (result == true) {
                              _loadUserData();
                            }
                          },
                        ),
                        _buildActionCard(
                          context,
                          icon: Icons.timer_outlined,
                          title: 'App Usage',
                          subtitle: 'Track your time',
                          color: Colors.teal,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const AppUsageScreen(),
                              ),
                            );
                          },
                        ),
                        _buildActionCard(
                          context,
                          icon: Icons.wb_sunny_outlined,
                          title: 'Weather',
                          subtitle: 'Current conditions',
                          color: Colors.orange,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const WeatherScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Weather Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Weather',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const WeatherScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'View Details',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Weather Widget
                    const SizedBox(
                      height: 160,
                      child: WeatherWidget(height: 160),
                    ),

                    const SizedBox(height: 16),

                    // Step Counter Widget
                    const SizedBox(
                      height: 160,
                      child: StepCounterWidget(height: 160),
                    ),

                    const SizedBox(height: 16),

                    // Prayer Times Section
                    Text(
                      'Prayer Times',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Prayer Times Widget
                    const SizedBox(
                      height: 160,
                      child: PrayerTimesWidget(),
                    ),

                    const SizedBox(height: 16),

                    // Mindfulness Section
                    Text(
                      'Mindfulness & Patience',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mindfulness Widget
                    const SizedBox(
                      height: 160,
                      child: MindfulnessWidget(),
                    ),

                    const SizedBox(height: 32),

                    // App Features Section with Toggle Buttons
                    // Recent Activity Section
                    Text(
                      'Recent Activity',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Placeholder for recent activity
                    SizedBox(
                      height: 180,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_outlined,
                              size: 48,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No entries yet',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start writing your first journal entry to see your activity here.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeOfDayGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Morning';
    } else if (hour < 17) {
      return 'Afternoon';
    } else {
      return 'Evening';
    }
  }
}
