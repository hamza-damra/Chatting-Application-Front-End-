import 'package:flutter/material.dart';
import '../widgets/shimmer_widgets.dart';

class ShimmerTestScreen extends StatelessWidget {
  const ShimmerTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shimmer Effects Test'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Auth Loading Shimmer',
              ShimmerWidgets.authLoadingShimmer(),
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Button Shimmer',
              Row(
                children: [
                  ShimmerWidgets.buttonShimmer(),
                  const SizedBox(width: 16),
                  ShimmerWidgets.buttonShimmer(
                    width: 30,
                    height: 30,
                    baseColor: Colors.blue.withValues(alpha: 0.3),
                    highlightColor: Colors.blue.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Image Shimmer',
              ShimmerWidgets.imageShimmer(
                width: 200,
                height: 150,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Chat Image Shimmer (Current User)',
              ShimmerWidgets.chatImageShimmer(
                width: 250,
                height: 180,
                isCurrentUser: true,
                primaryColor: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Chat Image Shimmer (Other User)',
              ShimmerWidgets.chatImageShimmer(
                width: 250,
                height: 180,
                isCurrentUser: false,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              'List Item Shimmer',
              Column(
                children: [
                  ShimmerWidgets.listItemShimmer(),
                  ShimmerWidgets.listItemShimmer(),
                  ShimmerWidgets.listItemShimmer(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              'File Loading Shimmer',
              ShimmerWidgets.fileLoadingShimmer(),
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Media Preview Shimmer',
              ShimmerWidgets.mediaPreviewShimmer(),
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Full Screen Image Shimmer',
              Container(
                height: 200,
                child: ShimmerWidgets.fullScreenImageShimmer(),
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Circular Shimmer',
              Row(
                children: [
                  ShimmerWidgets.circularShimmer(size: 40),
                  const SizedBox(width: 16),
                  ShimmerWidgets.circularShimmer(size: 60),
                  const SizedBox(width: 16),
                  ShimmerWidgets.circularShimmer(size: 80),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Avatar Shimmer',
              Row(
                children: [
                  ShimmerWidgets.avatarShimmer(size: 40),
                  const SizedBox(width: 16),
                  ShimmerWidgets.avatarShimmer(size: 60),
                  const SizedBox(width: 16),
                  ShimmerWidgets.avatarShimmer(size: 80),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Profile Info Card Shimmer',
              Column(
                children: [
                  ShimmerWidgets.profileInfoCardShimmer(),
                  ShimmerWidgets.profileInfoCardShimmer(),
                  ShimmerWidgets.profileInfoCardShimmer(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Profile Screen Shimmer',
              SizedBox(height: 400, child: ShimmerWidgets.profileShimmer()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: child,
        ),
      ],
    );
  }
}
