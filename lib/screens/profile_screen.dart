import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/api_auth_provider.dart';

import '../design_system/components/app_avatar.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_card.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/components/responsive_container.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/states/skeleton_tile.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  File? _imageFile;
  bool _isEditing = false;

  // State preservation for orientation changes
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final user = Provider.of<ApiAuthProvider>(context, listen: false).user;
    if (user != null) {
      final nameParts = user.fullName.split(' ');
      _firstNameController.text = nameParts.isNotEmpty ? nameParts[0] : '';
      _lastNameController.text =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      _emailController.text = user.email;
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromSource(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromSource(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Failed to pick image: $e');
      }
    }
  }

  void _showSuccessSnackbar(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? const DarkAppColors() : const LightAppColors();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: colors.textOnPrimary, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: colors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        margin: const EdgeInsets.all(AppSpacing.lg),
      ),
    );
  }

  void _showErrorSnackbar(String message, {VoidCallback? onRetry}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? const DarkAppColors() : const LightAppColors();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: colors.textOnPrimary, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: colors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        margin: const EdgeInsets.all(AppSpacing.lg),
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: colors.textOnPrimary,
                onPressed: onRetry,
              )
            : null,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<ApiAuthProvider>(context, listen: false);

      try {
        final fullName =
            "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}";

        bool success = true;

        if (_imageFile != null) {
          success = await authProvider.setProfileImage(imageFile: _imageFile!);

          if (!success) {
            if (mounted) {
              _showErrorSnackbar(
                authProvider.error ?? 'Failed to upload profile image',
                onRetry: _saveProfile,
              );
            }
            return;
          }
        }

        if (success) {
          success = await authProvider.updateProfile(
            fullName: fullName,
            profilePicture: null,
          );
        }

        if (!success && mounted) {
          _showErrorSnackbar(
            authProvider.error ?? 'Failed to update profile',
            onRetry: _saveProfile,
          );
        } else if (mounted) {
          _showSuccessSnackbar('Profile updated successfully');

          setState(() {
            _isEditing = false;
            _imageFile = null;
          });
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackbar(
            'Error updating profile: $e',
            onRetry: _saveProfile,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Required for AutomaticKeepAliveClientMixin to preserve state
    super.build(context);
    
    final authProvider = Provider.of<ApiAuthProvider>(context);
    final user = authProvider.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? const DarkAppColors() : const LightAppColors();

    if (user == null) {
      return _buildLoadingSkeleton(colors);
    }

    return ResponsiveContainer(
      maxWidth: ResponsiveMaxWidths.profileSettings,
      scrollable: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_isEditing) ...[
              _buildEditingView(user, authProvider, colors),
            ] else ...[
              _buildProfileView(user, colors),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(AppColors colors) {
    return ResponsiveContainer(
      maxWidth: ResponsiveMaxWidths.profileSettings,
      scrollable: true,
      child: Shimmer.fromColors(
        baseColor: colors.shimmerBase,
        highlightColor: colors.shimmerHighlight,
        child: Column(
          children: [
            // Profile header skeleton
            const SkeletonTile(type: SkeletonTileType.profileHeader, animate: false),
            const SizedBox(height: AppSpacing.sectionSpacing),
            
            // Section header skeleton
            _buildSectionHeaderSkeleton(colors),
            const SizedBox(height: AppSpacing.lg),
            
            // Info cards skeleton
            ...List.generate(5, (index) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Container(
                width: double.infinity,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.shimmerBase,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            )),
            
            const SizedBox(height: AppSpacing.sectionSpacing),
            
            // Statistics section skeleton
            _buildSectionHeaderSkeleton(colors),
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: colors.shimmerBase,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeaderSkeleton(AppColors colors) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 150,
        height: 20,
        decoration: BoxDecoration(
          color: colors.shimmerBase,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
    );
  }

  Widget _buildProfileView(UserModel user, AppColors colors) {
    return Column(
      children: [
        // Profile Header Section
        _buildProfileHeader(user, colors),
        const SizedBox(height: AppSpacing.sectionSpacing),

        // Account Information Section
        _buildAccountInfoSection(user, colors),
        const SizedBox(height: AppSpacing.sectionSpacing),

        // Statistics Section
        _buildStatisticsSection(user, colors),
        const SizedBox(height: AppSpacing.sectionSpacing),

        // Action Buttons
        _buildActionButtons(colors),
      ],
    );
  }

  Widget _buildEditingView(
    UserModel user,
    ApiAuthProvider authProvider,
    AppColors colors,
  ) {
    return Column(
      children: [
        // Profile Image with Edit
        _buildEditableProfileImage(user, colors),
        const SizedBox(height: AppSpacing.sectionSpacing),

        // Edit Form
        _buildEditForm(colors),
        const SizedBox(height: AppSpacing.sectionSpacing),

        // Save/Cancel Buttons
        _buildEditButtons(authProvider, colors),
      ],
    );
  }

  Widget _buildProfileHeader(UserModel user, AppColors colors) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      backgroundColor: colors.surfaceElevated,
      child: Stack(
        children: [
          // Edit Profile Button - Top Right
          Positioned(
            top: 0,
            right: 0,
            child: _buildEditButton(colors),
          ),

          // Main Profile Content
          Column(
            children: [
              // Profile Avatar with Online Status
              AppAvatar(
                name: user.fullName,
                size: AppAvatarSize.extraLarge,
                showOnlineIndicator: true,
                isOnline: user.isOnline,
                semanticLabel: 'Profile picture of ${user.fullName}',
              ),
              const SizedBox(height: AppSpacing.lg),

              // User Name with Role Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      user.fullName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _buildRoleBadge(user.role, colors),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Username
              Text(
                '@${user.username}',
                style: TextStyle(
                  fontSize: 14,
                  color: colors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // Email
              Text(
                user.email,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Status Text
              Text(
                user.isOnline
                    ? 'Online'
                    : 'Last seen ${_formatLastSeen(user.lastSeen)}',
                style: TextStyle(
                  fontSize: 12,
                  color: user.isOnline ? colors.online : colors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton(AppColors colors) {
    return Semantics(
      button: true,
      label: 'Edit profile',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _isEditing = true;
            });
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              Icons.edit,
              color: colors.primary,
              size: AppSpacing.iconMd,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(UserRole role, AppColors colors) {
    final isAdmin = role == UserRole.admin;
    final badgeColor = isAdmin ? colors.warning : colors.primary;
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdmin ? Icons.admin_panel_settings : Icons.person,
            size: 12,
            color: badgeColor,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            isAdmin ? 'Admin' : 'User',
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'unknown';

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return _formatDate(lastSeen);
    }
  }

  Widget _buildAccountInfoSection(UserModel user, AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Account Information', colors),
        const SizedBox(height: AppSpacing.lg),
        _buildInfoCard(
          icon: Icons.badge,
          title: 'User ID',
          value: '#${user.id}',
          colors: colors,
        ),
        _buildInfoCard(
          icon: Icons.alternate_email,
          title: 'Username',
          value: user.username,
          colors: colors,
        ),
        _buildInfoCard(
          icon: Icons.email_outlined,
          title: 'Email Address',
          value: user.email,
          colors: colors,
        ),
        _buildInfoCard(
          icon: Icons.calendar_today,
          title: 'Member Since',
          value: _formatDate(user.createdAt),
          colors: colors,
        ),
        _buildInfoCard(
          icon: Icons.update,
          title: 'Last Updated',
          value: _formatDate(user.updatedAt),
          colors: colors,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: colors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(UserModel user, AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Account Statistics', colors),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          backgroundColor: colors.surface,
          child: Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.access_time,
                  label: 'Days Active',
                  value: _calculateDaysActive(user.createdAt).toString(),
                  colors: colors,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: colors.divider,
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.security,
                  label: 'Account Type',
                  value: user.role == UserRole.admin ? 'Admin' : 'Standard',
                  colors: colors,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: colors.divider,
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.verified_user,
                  label: 'Status',
                  value: 'Verified',
                  colors: colors,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required AppColors colors,
  }) {
    return Column(
      children: [
        Icon(icon, color: colors.primary, size: AppSpacing.iconLg),
        const SizedBox(height: AppSpacing.sm),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  int _calculateDaysActive(DateTime createdAt) {
    final now = DateTime.now();
    return now.difference(createdAt).inDays;
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required AppColors colors,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        backgroundColor: colors.surface,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(icon, color: colors.primary, size: AppSpacing.iconMd),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(AppColors colors) {
    return AppButton(
      label: 'Logout',
      onPressed: _handleLogout,
      variant: AppButtonVariant.outlined,
      isDestructive: true,
      expanded: true,
      size: AppButtonSize.large,
      icon: Icons.logout,
      semanticLabel: 'Logout from account',
    );
  }

  Future<void> _handleLogout() async {
    final authProvider = Provider.of<ApiAuthProvider>(context, listen: false);
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final colors = isDark ? const DarkAppColors() : const LightAppColors();
        
        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          title: Text(
            'Logout',
            style: TextStyle(color: colors.textPrimary),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: colors.textSecondary),
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
                style: TextStyle(color: colors.error),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await authProvider.logout();
      } catch (e) {
        if (mounted) {
          _showErrorSnackbar('Error logging out: ${e.toString()}');
        }
      }
    }
  }

  Widget _buildEditableProfileImage(UserModel user, AppColors colors) {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          if (_imageFile != null)
            Container(
              width: AppSpacing.avatarXl,
              height: AppSpacing.avatarXl,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.outline,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.file(
                  _imageFile!,
                  width: AppSpacing.avatarXl,
                  height: AppSpacing.avatarXl,
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            AppAvatar(
              name: user.fullName,
              size: AppAvatarSize.extraLarge,
              semanticLabel: 'Profile picture of ${user.fullName}',
            ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.surface,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.camera_alt,
                color: colors.textOnPrimary,
                size: AppSpacing.iconSm,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm(AppColors colors) {
    return Column(
      children: [
        AppTextField(
          labelText: 'First Name',
          controller: _firstNameController,
          prefixIcon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your first name';
            }
            return null;
          },
          semanticLabel: 'First name input field',
        ),
        const SizedBox(height: AppSpacing.lg),

        AppTextField(
          labelText: 'Last Name',
          controller: _lastNameController,
          prefixIcon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your last name';
            }
            return null;
          },
          semanticLabel: 'Last name input field',
        ),
        const SizedBox(height: AppSpacing.lg),

        AppTextField(
          labelText: 'Email',
          controller: _emailController,
          prefixIcon: Icons.email_outlined,
          enabled: false,
          helperText: 'Email cannot be changed',
          semanticLabel: 'Email address (read only)',
        ),
      ],
    );
  }

  Widget _buildEditButtons(ApiAuthProvider authProvider, AppColors colors) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'Cancel',
            onPressed: () {
              setState(() {
                _isEditing = false;
                _imageFile = null;
                _loadUserData();
              });
            },
            variant: AppButtonVariant.outlined,
            size: AppButtonSize.large,
            semanticLabel: 'Cancel editing profile',
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: AppButton(
            label: 'Save',
            onPressed: _saveProfile,
            isLoading: authProvider.isLoading,
            size: AppButtonSize.large,
            semanticLabel: 'Save profile changes',
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Not available';
    }

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays < 2) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else {
      return '${(difference.inDays / 365).floor()} years ago';
    }
  }
}
