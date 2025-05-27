import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/api_auth_provider.dart';

import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/shimmer_widgets.dart';
import '../widgets/profile_image_widget.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  File? _imageFile;
  bool _isEditing = false;

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
      // Extract first and last name from fullName
      final nameParts = user.fullName.split(' ');
      _firstNameController.text = nameParts.isNotEmpty ? nameParts[0] : '';
      _lastNameController.text =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      _emailController.text = user.email;
    }
  }

  Future<void> _pickImage() async {
    // Show bottom sheet to choose between camera and gallery
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<ApiAuthProvider>(context, listen: false);

      try {
        // Combine first and last name into fullName
        final fullName =
            "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}";

        bool success = true;

        // Upload profile image if a new image was selected
        if (_imageFile != null) {
          success = await authProvider.setProfileImage(imageFile: _imageFile!);

          if (!success) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    authProvider.error ?? 'Failed to upload profile image',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        }

        // Update profile information (name)
        if (success) {
          success = await authProvider.updateProfile(
            fullName: fullName,
            profilePicture:
                null, // Don't update profile picture URL here since it's handled above
          );
        }

        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.error ?? 'Failed to update profile'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );

          setState(() {
            _isEditing = false;
            _imageFile = null;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating profile: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<ApiAuthProvider>(context);
    final user = authProvider.user;
    final theme = Theme.of(context);

    if (user == null) {
      return ShimmerWidgets.profileShimmer(context: context);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_isEditing) ...[
              _buildEditingView(user, authProvider, theme),
            ] else ...[
              _buildProfileView(user, theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileView(UserModel user, ThemeData theme) {
    return Column(
      children: [
        // Profile Header Section
        _buildProfileHeader(user, theme),
        const SizedBox(height: 32),

        // Account Information Section
        _buildAccountInfoSection(user, theme),
        const SizedBox(height: 24),

        // Statistics Section
        _buildStatisticsSection(user, theme),
        const SizedBox(height: 24),

        // Action Buttons
        _buildActionButtons(theme),
      ],
    );
  }

  Widget _buildEditingView(
    UserModel user,
    ApiAuthProvider authProvider,
    ThemeData theme,
  ) {
    return Column(
      children: [
        // Profile Image with Edit
        _buildEditableProfileImage(user, theme),
        const SizedBox(height: 32),

        // Edit Form
        _buildEditForm(),
        const SizedBox(height: 32),

        // Save/Cancel Buttons
        _buildEditButtons(authProvider),
      ],
    );
  }

  Widget _buildProfileHeader(UserModel user, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            theme.colorScheme.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Stack(
        children: [
          // Edit Profile Button - Top Right
          Positioned(top: 0, right: 0, child: _buildModernEditButton(theme)),

          // Main Profile Content
          Column(
            children: [
              // Profile Image with Status
              Stack(
                children: [
                  EditableProfileImageWidget(
                    userId: user.id,
                    userName: user.fullName,
                    size: 120,
                    onTap: null,
                    showEditIcon: false,
                  ),
                  // Online Status Indicator
                  if (user.isOnline)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.circle,
                          color: Colors.green,
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // User Name with Role Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      user.fullName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildRoleBadge(user.role, theme),
                ],
              ),
              const SizedBox(height: 8),

              // Username
              Text(
                '@${user.username}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),

              // Email
              Text(
                user.email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),

              // Status Text
              Text(
                user.isOnline
                    ? 'Online'
                    : 'Last seen ${_formatLastSeen(user.lastSeen)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      user.isOnline
                          ? Colors.green
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(UserRole role, ThemeData theme) {
    final isAdmin = role == UserRole.admin;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            isAdmin
                ? Colors.orange.withValues(alpha: 0.1)
                : theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAdmin ? Colors.orange : theme.colorScheme.primary,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdmin ? Icons.admin_panel_settings : Icons.person,
            size: 12,
            color: isAdmin ? Colors.orange : theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            isAdmin ? 'Admin' : 'User',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isAdmin ? Colors.orange : theme.colorScheme.primary,
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

  Widget _buildAccountInfoSection(UserModel user, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Account Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          icon: Icons.badge,
          title: 'User ID',
          value: '#${user.id}',
          theme: theme,
        ),
        _buildInfoCard(
          icon: Icons.alternate_email,
          title: 'Username',
          value: user.username,
          theme: theme,
        ),
        _buildInfoCard(
          icon: Icons.email_outlined,
          title: 'Email Address',
          value: user.email,
          theme: theme,
        ),
        _buildInfoCard(
          icon: Icons.calendar_today,
          title: 'Member Since',
          value: _formatDate(user.createdAt),
          theme: theme,
        ),
        _buildInfoCard(
          icon: Icons.update,
          title: 'Last Updated',
          value: _formatDate(user.updatedAt),
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildStatisticsSection(UserModel user, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Account Statistics',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.access_time,
                  label: 'Days Active',
                  value: _calculateDaysActive(user.createdAt).toString(),
                  theme: theme,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.security,
                  label: 'Account Type',
                  value: user.role == UserRole.admin ? 'Admin' : 'Standard',
                  theme: theme,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.verified_user,
                  label: 'Status',
                  value: 'Verified',
                  theme: theme,
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
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
    required ThemeData theme,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernEditButton(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            theme.colorScheme.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _isEditing = true;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(Icons.edit, color: theme.colorScheme.primary, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        // Logout Button
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: 'Logout',
            onPressed: () async {
              final authProvider = Provider.of<ApiAuthProvider>(
                context,
                listen: false,
              );
              // Show confirmation dialog
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
                  // when the authentication state changes
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
            isOutlined: true,
            height: 50,
            borderRadius: 12,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildEditableProfileImage(UserModel user, ThemeData theme) {
    return Stack(
      children: [
        _imageFile != null
            ? Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.file(
                  _imageFile!,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            )
            : EditableProfileImageWidget(
              userId: user.id,
              userName: user.fullName,
              size: 120,
              onTap: _pickImage,
              showEditIcon: true,
            ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Column(
      children: [
        // First Name Field
        CustomTextField(
          label: 'First Name',
          controller: _firstNameController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your first name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Last Name Field
        CustomTextField(
          label: 'Last Name',
          controller: _lastNameController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your last name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Email Field (disabled)
        CustomTextField(
          label: 'Email',
          controller: _emailController,
          enabled: false,
        ),
      ],
    );
  }

  Widget _buildEditButtons(ApiAuthProvider authProvider) {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: 'Cancel',
            onPressed: () {
              setState(() {
                _isEditing = false;
                _imageFile = null;
                _loadUserData();
              });
            },
            isOutlined: true,
            height: 50,
            borderRadius: 12,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CustomButton(
            text: 'Save',
            onPressed: _saveProfile,
            isLoading: authProvider.isLoading,
            height: 50,
            borderRadius: 12,
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
