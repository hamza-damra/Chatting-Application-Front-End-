import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/api_auth_provider.dart';
import '../widgets/custom_button.dart';
import 'shimmer_test_screen.dart';
import 'media_gallery_screen.dart';
import 'storage_stats_screen.dart';
import 'debug_screen.dart';
import 'notification_test_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _notifications = true;
  bool _readReceipts = true;
  bool _typingIndicators = true;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<ApiAuthProvider>(context);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Account Section
        _buildSectionHeader('Account'),
        _buildSettingCard(
          icon: Icons.person,
          title: 'Account Information',
          subtitle: 'View and edit your account details',
          onTap: () {
            // Navigate to account details screen
          },
        ),
        _buildSettingCard(
          icon: Icons.lock,
          title: 'Privacy & Security',
          subtitle: 'Manage your privacy settings',
          onTap: () {
            // Navigate to privacy settings screen
          },
        ),

        // Appearance Section
        _buildSectionHeader('Appearance'),
        _buildSwitchCard(
          icon: Icons.dark_mode,
          title: 'Dark Mode',
          value: _darkMode,
          onChanged: (value) {
            setState(() {
              _darkMode = value;
              // TODO: Implement theme switching - will be addressed in future updates
            });
          },
        ),

        // Notifications Section
        _buildSectionHeader('Notifications'),
        _buildSwitchCard(
          icon: Icons.notifications,
          title: 'Push Notifications',
          subtitle: 'Receive notifications for new messages',
          value: _notifications,
          onChanged: (value) {
            setState(() {
              _notifications = value;
              // TODO: Implement notification settings - will be addressed in future updates
            });
          },
        ),

        // Chat Settings Section
        _buildSectionHeader('Chat Settings'),
        _buildSwitchCard(
          icon: Icons.done_all,
          title: 'Read Receipts',
          subtitle: 'Let others know when you\'ve read their messages',
          value: _readReceipts,
          onChanged: (value) {
            setState(() {
              _readReceipts = value;
              // TODO: Implement read receipts settings - will be addressed in future updates
            });
          },
        ),
        _buildSwitchCard(
          icon: Icons.keyboard,
          title: 'Typing Indicators',
          subtitle: 'Show when you\'re typing a message',
          value: _typingIndicators,
          onChanged: (value) {
            setState(() {
              _typingIndicators = value;
              // TODO: Implement typing indicators settings - will be addressed in future updates
            });
          },
        ),

        // Media & Storage Section
        _buildSectionHeader('Media & Storage'),
        _buildSettingCard(
          icon: Icons.photo_library,
          title: 'Media Gallery',
          subtitle: 'View all shared media files',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MediaGalleryScreen(),
              ),
            );
          },
        ),
        _buildSettingCard(
          icon: Icons.storage,
          title: 'Storage Statistics',
          subtitle: 'View storage usage and statistics',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StorageStatsScreen(),
              ),
            );
          },
        ),

        // About Section
        _buildSectionHeader('About'),
        _buildSettingCard(
          icon: Icons.info_outline,
          title: 'About Chat App',
          subtitle: 'Version 1.0.0',
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: 'Chat App',
              applicationVersion: '1.0.0',
              applicationIcon: Icon(
                Icons.chat_rounded,
                color: theme.colorScheme.primary,
                size: 40,
              ),
              applicationLegalese: '© 2023 Chat App',
            );
          },
        ),
        _buildSettingCard(
          icon: Icons.help_outline,
          title: 'Help & Support',
          subtitle: 'Get help with using the app',
          onTap: () {
            // Navigate to help screen
          },
        ),
        _buildSettingCard(
          icon: Icons.bug_report,
          title: 'Debug API',
          subtitle: 'Test API endpoints',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DebugScreen()),
            );
          },
        ),
        _buildSettingCard(
          icon: Icons.animation,
          title: 'Shimmer Effects Test',
          subtitle: 'View all shimmer loading animations',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ShimmerTestScreen(),
              ),
            );
          },
        ),
        _buildSettingCard(
          icon: Icons.notifications_active,
          title: 'Notification Test',
          subtitle: 'Test notification system and permissions',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationTestScreen(),
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        // Logout Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: CustomButton(
            text: 'Logout',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
              );
              if (confirm == true) {
                try {
                  await authProvider.logout();
                  // Navigate to login screen and clear all previous routes
                  if (mounted) {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error logging out: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            isLoading: authProvider.isLoading,
            color: Colors.red,
            height: 50,
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SwitchListTile(
        secondary: Icon(icon),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
