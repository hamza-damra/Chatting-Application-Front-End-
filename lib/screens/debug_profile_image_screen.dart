import 'package:flutter/material.dart';
import '../widgets/profile_image_test_widget.dart';
import '../widgets/debug_profile_image_widget.dart';

/// Debug screen for testing profile image upload functionality
class DebugProfileImageScreen extends StatelessWidget {
  const DebugProfileImageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Image Debug'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: const SingleChildScrollView(
        child: Column(
          children: [
            ProfileImageTestWidget(),
            DebugProfileImageWidget(
              userId: null, // Test current user
              userName: 'Current User',
            ),
          ],
        ),
      ),
    );
  }
}
