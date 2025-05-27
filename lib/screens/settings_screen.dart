import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/api_auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_button.dart';
import '../services/background_notification_manager.dart';
import 'media_gallery_screen.dart';
import 'storage_stats_screen.dart';
import 'blocked_users_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _readReceipts = true;
  bool _typingIndicators = true;

  /// Request background notification permissions
  Future<void> _requestBackgroundNotificationPermissions() async {
    try {
      final granted =
          await BackgroundNotificationManager.requestPermissionsWithContext(
            context,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              granted
                  ? 'Background notification permissions granted!'
                  : 'Some permissions were denied. Background notifications may not work properly.',
            ),
            backgroundColor: granted ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting permissions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<ApiAuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account Section
          _buildSectionHeader('Account', theme),
          const SizedBox(height: 16),
          _buildModernSettingCard(
            icon: Icons.person,
            title: 'Account Information',
            subtitle: 'View and edit your account details',
            theme: theme,
            onTap: () {
              // Navigate to account details screen
            },
          ),
          const SizedBox(height: 12),
          _buildModernSettingCard(
            icon: Icons.lock,
            title: 'Privacy & Security',
            subtitle: 'Manage your privacy settings',
            theme: theme,
            onTap: () {
              // Navigate to privacy settings screen
            },
          ),
          const SizedBox(height: 12),
          _buildModernSettingCard(
            icon: Icons.block,
            title: 'Blocked Users',
            subtitle: 'Manage blocked users',
            theme: theme,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BlockedUsersScreen(),
                ),
              );
            },
          ),

          // Appearance Section
          const SizedBox(height: 32),
          _buildSectionHeader('Appearance', theme),
          const SizedBox(height: 16),
          _buildThemeCard(themeProvider, theme),

          // Notifications Section
          const SizedBox(height: 32),
          _buildSectionHeader('Notifications', theme),
          const SizedBox(height: 16),
          _buildModernSwitchCard(
            icon: Icons.notifications,
            title: 'Push Notifications',
            subtitle: 'Receive notifications for new messages',
            value: _notifications,
            theme: theme,
            onChanged: (value) {
              setState(() {
                _notifications = value;
                // Notification settings functionality to be implemented
              });
            },
          ),
          const SizedBox(height: 12),
          _buildModernSettingCard(
            icon: Icons.security,
            title: 'Background Notification Permissions',
            subtitle: 'Grant permissions for background notifications',
            theme: theme,
            onTap: () => _requestBackgroundNotificationPermissions(),
          ),

          // Chat Settings Section
          const SizedBox(height: 32),
          _buildSectionHeader('Chat Settings', theme),
          const SizedBox(height: 16),
          _buildModernSwitchCard(
            icon: Icons.done_all,
            title: 'Read Receipts',
            subtitle: 'Let others know when you\'ve read their messages',
            value: _readReceipts,
            theme: theme,
            onChanged: (value) {
              setState(() {
                _readReceipts = value;
                // Read receipts functionality to be implemented
              });
            },
          ),
          const SizedBox(height: 12),
          _buildModernSwitchCard(
            icon: Icons.keyboard,
            title: 'Typing Indicators',
            subtitle: 'Show when you\'re typing a message',
            value: _typingIndicators,
            theme: theme,
            onChanged: (value) {
              setState(() {
                _typingIndicators = value;
                // Typing indicators functionality to be implemented
              });
            },
          ),

          // Media & Storage Section
          const SizedBox(height: 32),
          _buildSectionHeader('Media & Storage', theme),
          const SizedBox(height: 16),
          _buildModernSettingCard(
            icon: Icons.photo_library,
            title: 'Media Gallery',
            subtitle: 'View all shared media files',
            theme: theme,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MediaGalleryScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildModernSettingCard(
            icon: Icons.storage,
            title: 'Storage Statistics',
            subtitle: 'View storage usage and statistics',
            theme: theme,
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
          const SizedBox(height: 32),
          _buildSectionHeader('About', theme),
          const SizedBox(height: 16),
          _buildModernSettingCard(
            icon: Icons.info_outline,
            title: 'About Vector',
            subtitle: 'Version 1.0.0',
            theme: theme,
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Vector',
                applicationVersion: '1.0.0',
                applicationIcon: Icon(
                  Icons.chat_rounded,
                  color: theme.colorScheme.primary,
                  size: 40,
                ),
                applicationLegalese: '© 2023 Vector Chat App',
              );
            },
          ),
          const SizedBox(height: 12),
          _buildModernSettingCard(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help with using the app',
            theme: theme,
            onTap: () {
              // Navigate to help screen
            },
          ),

          const SizedBox(height: 32),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Logout',
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);

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
                    // The AuthWrapper will automatically handle navigation to login
                    // when the authentication state changes, so no manual navigation needed
                  } catch (e) {
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
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
              borderRadius: 12,
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildModernSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSwitchCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ThemeData theme,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(ThemeProvider themeProvider, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : themeProvider.themeMode == ThemeMode.light
                  ? Icons.light_mode
                  : Icons.brightness_auto,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getThemeModeText(themeProvider.themeMode),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: themeProvider.themeMode == ThemeMode.dark,
            onChanged: (value) {
              themeProvider.setThemeMode(
                value ? ThemeMode.dark : ThemeMode.light,
              );
            },
            activeColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  String _getThemeModeText(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Light Mode';
      case ThemeMode.dark:
        return 'Dark Mode';
      case ThemeMode.system:
        return 'System Default';
    }
  }
}
