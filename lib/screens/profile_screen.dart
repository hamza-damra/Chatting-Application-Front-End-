import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/api_auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/user_avatar.dart';
import '../widgets/shimmer_widgets.dart';

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
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 500,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<ApiAuthProvider>(context, listen: false);

      // Note: Image upload functionality removed
      // In a real app, you would implement image upload to your backend

      // For now, we'll use a placeholder URL if an image was selected
      String? profilePicture;
      if (_imageFile != null) {
        profilePicture = "https://example.com/placeholder-profile.jpg";
      }

      // Combine first and last name into fullName
      final fullName =
          "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}";

      final success = await authProvider.updateProfile(
        fullName: fullName,
        profilePicture: profilePicture,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Failed to update profile'),
            backgroundColor: Colors.red,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<ApiAuthProvider>(context);
    final user = authProvider.user;
    final theme = Theme.of(context);

    if (user == null) {
      return ShimmerWidgets.profileShimmer();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Image
            Stack(
              children: [
                UserAvatar(
                  imageUrl: _imageFile != null ? null : user.profilePicture,
                  name: user.fullName,
                  size: 120,
                  backgroundColor: theme.colorScheme.primary,
                ),
                if (_imageFile != null)
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: FileImage(_imageFile!),
                  ),
                if (_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // User Name
            if (!_isEditing)
              Text(
                user.fullName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

            // User Email
            if (!_isEditing)
              Text(
                user.email,
                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
              ),

            const SizedBox(height: 32),

            if (_isEditing) ...[
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
              const SizedBox(height: 32),

              // Save Button
              Row(
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
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      text: 'Save',
                      onPressed: _saveProfile,
                      isLoading: authProvider.isLoading,
                      height: 50,
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Profile Info Cards
              _buildInfoCard(
                icon: Icons.person,
                title: 'Name',
                value: user.fullName,
              ),
              _buildInfoCard(
                icon: Icons.email,
                title: 'Email',
                value: user.email,
              ),
              _buildInfoCard(
                icon: Icons.calendar_today,
                title: 'Joined',
                value: _formatDate(
                  user.lastSeen,
                ), // Using lastSeen as a substitute for createdAt
              ),
              const SizedBox(height: 32),

              // Edit Profile Button
              CustomButton(
                text: 'Edit Profile',
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
                height: 50,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
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
