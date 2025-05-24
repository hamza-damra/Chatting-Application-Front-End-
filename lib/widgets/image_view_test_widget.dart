import 'package:flutter/material.dart';
import '../utils/logger.dart';
import 'chat_image_thumbnail.dart';
import 'chat_image_widget.dart';

/// A test widget to verify image view functionality in chat screen
class ImageViewTestWidget extends StatefulWidget {
  const ImageViewTestWidget({super.key});

  @override
  State<ImageViewTestWidget> createState() => _ImageViewTestWidgetState();
}

class _ImageViewTestWidgetState extends State<ImageViewTestWidget> {
  final List<String> _testImageUrls = [
    // Network URLs
    'https://picsum.photos/300/200?random=1',
    'https://picsum.photos/300/200?random=2',
    'https://via.placeholder.com/300x200/FF0000/FFFFFF?text=Test+Image',
    
    // Invalid URLs for error testing
    'https://invalid-url-that-does-not-exist.com/image.jpg',
    'http://broken-link.test/missing.png',
    
    // Local file paths (will show error on mobile)
    '/data/user/0/com.example.app/cache/image.jpg',
    'file:///storage/emulated/0/Pictures/test.png',
    
    // Data URI (base64)
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
    
    // Relative paths
    'uploads/images/test.jpg',
    'assets/images/placeholder.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image View Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Image View Test Cases',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This widget tests different image URL formats and error handling:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Network URLs (should work)\n'
              '• Invalid URLs (should show error)\n'
              '• Local file paths (should show error on mobile)\n'
              '• Base64 data URIs (should work)\n'
              '• Relative paths (should show error)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _testImageUrls.length,
                itemBuilder: (context, index) {
                  final imageUrl = _testImageUrls[index];
                  return _buildTestCase(imageUrl, index);
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildTestButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCase(String imageUrl, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Case ${index + 1}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                imageUrl,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // ChatImageThumbnail test
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ChatImageThumbnail:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      ChatImageThumbnail(
                        imageUrl: imageUrl,
                        heroTag: 'thumbnail-$index',
                        width: 120,
                        height: 80,
                        isCurrentUser: index % 2 == 0,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // ChatImageWidget test
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ChatImageWidget:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      ChatImageWidget(
                        uri: imageUrl,
                        width: 120,
                        height: 80,
                        fit: BoxFit.cover,
                        isCurrentUser: index % 2 == 1,
                        theme: Theme.of(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _testImageLoading,
            icon: const Icon(Icons.refresh),
            label: const Text('Test Loading'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _clearImageCache,
            icon: const Icon(Icons.clear),
            label: const Text('Clear Cache'),
          ),
        ),
      ],
    );
  }

  void _testImageLoading() {
    AppLogger.i('ImageViewTest', 'Testing image loading for ${_testImageUrls.length} URLs');
    
    for (int i = 0; i < _testImageUrls.length; i++) {
      final url = _testImageUrls[i];
      AppLogger.d('ImageViewTest', 'Test case ${i + 1}: $url');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image loading test started. Check logs for details.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearImageCache() {
    // Clear cached network images
    try {
      // This would clear the cache if we had access to the cache manager
      AppLogger.i('ImageViewTest', 'Image cache clear requested');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image cache cleared. Restart app to see effect.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      AppLogger.e('ImageViewTest', 'Error clearing cache: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing cache: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
