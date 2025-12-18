import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/api_auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/background_notification_manager.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_list_tile.dart';
import '../design_system/components/responsive_container.dart';
import '../design_system/states/skeleton_tile.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import 'media_gallery_screen.dart';
import 'storage_stats_screen.dart';
import 'blocked_users_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with AutomaticKeepAliveClientMixin {
  bool _notifications = true;
  bool _readReceipts = true;
  bool _typingIndicators = true;
  bool _isLoading = false;

  // State preservation for orientation changes
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    // Simulate loading remote settings
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

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


  /// Show logout confirmation dialog
  /// Returns true if user confirms logout, false otherwise
  Future<bool> _showLogoutConfirmationDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? const DarkAppColors() : const LightAppColors();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Logout',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to logout? You will need to sign in again to access your messages.',
          style: TextStyle(color: colors.textSecondary),
        ),
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Logout',
              style: TextStyle(
                color: colors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _handleLogout() async {
    final confirmed = await _showLogoutConfirmationDialog();
    if (!confirmed) return;

    final authProvider = Provider.of<ApiAuthProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await authProvider.logout();
      // The AuthWrapper will automatically handle navigation to login
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

  @override
  Widget build(BuildContext context) {
    // Required for AutomaticKeepAliveClientMixin to preserve state
    super.build(context);
    
    final authProvider = Provider.of<ApiAuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? const DarkAppColors() : const LightAppColors();

    if (_isLoading) {
      return _buildLoadingState();
    }

    return ResponsiveContainer(
      maxWidth: ResponsiveMaxWidths.profileSettings,
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account Section
          _buildSectionHeader('Account', colors),
          const SizedBox(height: AppSpacing.md),
          _buildSectionCard(
            colors: colors,
            children: [
              AppListTile(
                leadingIcon: Icons.person,
                title: 'Account Information',
                subtitle: 'View and edit your account details',
                trailing: AppListTileTrailing.chevron,
                showDivider: true,
                onTap: () {
                  // Navigate to account details screen
                },
              ),
              AppListTile(
                leadingIcon: Icons.lock,
                title: 'Privacy & Security',
                subtitle: 'Manage your privacy settings',
                trailing: AppListTileTrailing.chevron,
                showDivider: true,
                onTap: () {
                  // Navigate to privacy settings screen
                },
              ),
              AppListTile(
                leadingIcon: Icons.block,
                title: 'Blocked Users',
                subtitle: 'Manage blocked users',
                trailing: AppListTileTrailing.chevron,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BlockedUsersScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sectionSpacing),

          // Notifications Section
          _buildSectionHeader('Notifications', colors),
          const SizedBox(height: AppSpacing.md),
          _buildSectionCard(
            colors: colors,
            children: [
              AppListTile(
                leadingIcon: Icons.notifications,
                title: 'Push Notifications',
                subtitle: 'Receive notifications for new messages',
                trailing: AppListTileTrailing.toggle,
                toggleValue: _notifications,
                showDivider: true,
                onToggleChanged: (value) {
                  setState(() => _notifications = value);
                },
              ),
              AppListTile(
                leadingIcon: Icons.security,
                title: 'Background Permissions',
                subtitle: 'Grant permissions for background notifications',
                trailing: AppListTileTrailing.chevron,
                onTap: () => _requestBackgroundNotificationPermissions(),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sectionSpacing),

          // Chat Section
          _buildSectionHeader('Chat', colors),
          const SizedBox(height: AppSpacing.md),
          _buildSectionCard(
            colors: colors,
            children: [
              AppListTile(
                leadingIcon: Icons.done_all,
                title: 'Read Receipts',
                subtitle: 'Let others know when you\'ve read their messages',
                trailing: AppListTileTrailing.toggle,
                toggleValue: _readReceipts,
                showDivider: true,
                onToggleChanged: (value) {
                  setState(() => _readReceipts = value);
                },
              ),
              AppListTile(
                leadingIcon: Icons.keyboard,
                title: 'Typing Indicators',
                subtitle: 'Show when you\'re typing a message',
                trailing: AppListTileTrailing.toggle,
                toggleValue: _typingIndicators,
                showDivider: true,
                onToggleChanged: (value) {
                  setState(() => _typingIndicators = value);
                },
              ),
              _buildThemeTile(themeProvider, colors),
            ],
          ),

          const SizedBox(height: AppSpacing.sectionSpacing),

          // Media Section
          _buildSectionHeader('Media', colors),
          const SizedBox(height: AppSpacing.md),
          _buildSectionCard(
            colors: colors,
            children: [
              AppListTile(
                leadingIcon: Icons.photo_library,
                title: 'Media Gallery',
                subtitle: 'View all shared media files',
                trailing: AppListTileTrailing.chevron,
                showDivider: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MediaGalleryScreen(),
                    ),
                  );
                },
              ),
              AppListTile(
                leadingIcon: Icons.storage,
                title: 'Storage Statistics',
                subtitle: 'View storage usage and statistics',
                trailing: AppListTileTrailing.chevron,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StorageStatsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sectionSpacing),

          // About Section
          _buildSectionHeader('About', colors),
          const SizedBox(height: AppSpacing.md),
          _buildSectionCard(
            colors: colors,
            children: [
              AppListTile(
                leadingIcon: Icons.info_outline,
                title: 'About Vector',
                subtitle: 'Version 1.0.0',
                trailing: AppListTileTrailing.chevron,
                showDivider: true,
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Vector',
                    applicationVersion: '1.0.0',
                    applicationIcon: Icon(
                      Icons.chat_rounded,
                      color: colors.primary,
                      size: 40,
                    ),
                    applicationLegalese: '© 2023 Vector Chat App',
                  );
                },
              ),
              AppListTile(
                leadingIcon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'Get help with using the app',
                trailing: AppListTileTrailing.chevron,
                onTap: () {
                  // Navigate to help screen
                },
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xxxl),

          // Logout Button - Destructive styling
          AppButton(
            label: 'Logout',
            onPressed: _handleLogout,
            isLoading: authProvider.isLoading,
            isDestructive: true,
            expanded: true,
            size: AppButtonSize.large,
            icon: Icons.logout,
            semanticLabel: 'Logout from your account',
          ),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }


  Widget _buildLoadingState() {
    return ResponsiveContainer(
      maxWidth: ResponsiveMaxWidths.profileSettings,
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Generate skeleton tiles for loading state
          ...List.generate(
            8,
            (index) => const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: SkeletonTile(type: SkeletonTileType.settingsItem),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: colors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required AppColors colors,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget _buildThemeTile(ThemeProvider themeProvider, AppColors colors) {
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    
    return AppListTile(
      leadingIcon: isDarkMode ? Icons.dark_mode : Icons.light_mode,
      title: 'Dark Mode',
      subtitle: isDarkMode ? 'Dark theme enabled' : 'Light theme enabled',
      trailing: AppListTileTrailing.toggle,
      toggleValue: isDarkMode,
      onToggleChanged: (value) {
        themeProvider.setThemeMode(
          value ? ThemeMode.dark : ThemeMode.light,
        );
      },
    );
  }
}
