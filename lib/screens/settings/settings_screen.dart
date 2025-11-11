import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/theme_provider.dart';
import '../../services/rest_auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Appearance Section
              _buildSectionHeader('Appearance'),
              _buildSettingsTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                subtitle: 'Switch between light and dark themes',
                trailing: Switch.adaptive(
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleDarkMode();
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Notifications Section
              _buildSectionHeader('Notifications'),
              _buildSettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Enable Notifications',
                subtitle: 'Receive prayer time and mindfulness reminders',
                trailing: Switch.adaptive(
                  value: themeProvider.notificationsEnabled,
                  onChanged: (value) {
                    themeProvider.toggleNotifications();
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Privacy & Location Section
              _buildSectionHeader('Privacy & Location'),
              _buildSettingsTile(
                icon: Icons.location_on_outlined,
                title: 'Location Services',
                subtitle:
                    'Allow app to access location for prayer times and weather',
                trailing: Switch.adaptive(
                  value: themeProvider.locationEnabled,
                  onChanged: (value) {
                    themeProvider.toggleLocation();
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Units & Formats Section
              _buildSectionHeader('Units & Formats'),
              _buildDropdownTile(
                icon: Icons.thermostat_outlined,
                title: 'Temperature Unit',
                subtitle: 'Choose temperature display format',
                value: themeProvider.temperatureUnit,
                items: const [
                  {'value': 'celsius', 'label': 'Celsius (°C)'},
                  {'value': 'fahrenheit', 'label': 'Fahrenheit (°F)'},
                ],
                onChanged: (value) {
                  themeProvider.setTemperatureUnit(value!);
                },
              ),
              _buildDropdownTile(
                icon: Icons.access_time_outlined,
                title: 'Time Format',
                subtitle: 'Choose time display format',
                value: themeProvider.timeFormat,
                items: const [
                  {'value': '12hour', 'label': '12 Hour (AM/PM)'},
                  {'value': '24hour', 'label': '24 Hour'},
                ],
                onChanged: (value) {
                  themeProvider.setTimeFormat(value!);
                },
              ),
              _buildDropdownTile(
                icon: Icons.language_outlined,
                title: 'Language',
                subtitle: 'Choose app language',
                value: themeProvider.language,
                items: const [
                  {'value': 'en', 'label': 'English'},
                  {'value': 'ur', 'label': 'اردو (Urdu)'},
                  {'value': 'ar', 'label': 'العربية (Arabic)'},
                ],
                onChanged: (value) {
                  themeProvider.setLanguage(value!);
                },
              ),
              const SizedBox(height: 20),

              // Account Section
              _buildSectionHeader('Account'),
              _buildSettingsTile(
                icon: Icons.person_outline,
                title: 'Profile',
                subtitle: 'Manage your account information',
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Profile management feature placeholder
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile management coming soon!'),
                    ),
                  );
                },
              ),
              _buildSettingsTile(
                icon: Icons.sync_outlined,
                title: 'Data Sync',
                subtitle: 'Sync your data across devices',
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Show data sync information
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data sync coming soon!'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Support Section
              _buildSectionHeader('Support'),
              _buildSettingsTile(
                icon: Icons.help_outline,
                title: 'Help & FAQ',
                subtitle: 'Get help and find answers',
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showHelpDialog(context);
                },
              ),
              _buildSettingsTile(
                icon: Icons.bug_report_outlined,
                title: 'Report a Bug',
                subtitle: 'Help us improve the app',
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showReportBugDialog(context);
                },
              ),
              _buildSettingsTile(
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'App version and information',
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showAboutDialog(context);
                },
              ),
              const SizedBox(height: 20),

              // Danger Zone
              _buildSectionHeader('Danger Zone'),
              _buildSettingsTile(
                icon: Icons.refresh_outlined,
                title: 'Reset Settings',
                subtitle: 'Reset all settings to default',
                textColor: Colors.orange,
                trailing: const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.orange),
                onTap: () {
                  _showResetDialog(context, themeProvider);
                },
              ),
              _buildSettingsTile(
                icon: Icons.logout,
                title: 'Sign Out',
                subtitle: 'Sign out of your account',
                textColor: Colors.red,
                trailing: const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.red),
                onTap: () {
                  _showSignOutDialog(context);
                },
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: textColor ?? Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color: textColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        trailing: trailing,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            DropdownButton<String>(
              value: value,
              underline: Container(),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item['value'],
                  child: Text(
                    item['label']!,
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Help & FAQ',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Common Questions:',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              '• How to enable dark mode?\n  Go to Settings > Appearance > Dark Mode\n\n'
              '• How to set prayer time notifications?\n  Go to Settings > Notifications\n\n'
              '• How to change temperature units?\n  Go to Settings > Units & Formats',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportBugDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Report a Bug',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'To report a bug or suggest a feature, please contact us at:\n\nsupport@everydaychronicles.com\n\nInclude details about the issue and your device information.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'About Everyday Chronicles',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version: 1.0.0',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Your personal spiritual companion for daily prayers, mindfulness, and weather updates.',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              '© 2024 Everyday Chronicles',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reset Settings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to reset all settings to their default values? This action cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
          TextButton(
            onPressed: () {
              themeProvider.resetSettings();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to default'),
                ),
              );
            },
            child: Text(
              'Reset',
              style: GoogleFonts.poppins(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Sign Out',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to sign out of your account?',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final authService =
                    Provider.of<RestAuthService>(context, listen: false);
                await authService.signOut();
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error signing out: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Sign Out',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
