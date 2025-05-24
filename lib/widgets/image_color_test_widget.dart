import 'package:flutter/material.dart';
import '../widgets/chat_image_thumbnail.dart';
import '../widgets/chat_image_widget.dart';

/// Test widget to verify no red coloring appears in image display components
class ImageColorTestWidget extends StatefulWidget {
  const ImageColorTestWidget({super.key});

  @override
  State<ImageColorTestWidget> createState() => _ImageColorTestWidgetState();
}

class _ImageColorTestWidgetState extends State<ImageColorTestWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Color Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Image Color Test - No Red Coloring',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This test verifies that no red coloring appears in image components:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Working images should display normally\n'
              '• Error states should use neutral gray colors\n'
              '• Loading states should use neutral colors\n'
              '• No red tints or overlays should appear',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: ListView(
                children: [
                  _buildTestSection(
                    'Working Image (ChatImageThumbnail)',
                    ChatImageThumbnail(
                      imageUrl: 'https://picsum.photos/300/200?random=1',
                      heroTag: 'working-image-1',
                      width: 240,
                      height: 180,
                      isCurrentUser: false,
                    ),
                  ),

                  _buildTestSection(
                    'Working Image - Current User (ChatImageThumbnail)',
                    ChatImageThumbnail(
                      imageUrl: 'https://picsum.photos/300/200?random=2',
                      heroTag: 'working-image-2',
                      width: 240,
                      height: 180,
                      isCurrentUser: true,
                    ),
                  ),

                  _buildTestSection(
                    'Broken Image (ChatImageThumbnail)',
                    ChatImageThumbnail(
                      imageUrl:
                          'https://broken-url-that-does-not-exist.com/image.jpg',
                      heroTag: 'broken-image-1',
                      width: 240,
                      height: 180,
                      isCurrentUser: false,
                    ),
                  ),

                  _buildTestSection(
                    'Broken Image - Current User (ChatImageThumbnail)',
                    ChatImageThumbnail(
                      imageUrl:
                          'https://broken-url-that-does-not-exist.com/image2.jpg',
                      heroTag: 'broken-image-2',
                      width: 240,
                      height: 180,
                      isCurrentUser: true,
                    ),
                  ),

                  _buildTestSection(
                    'Working Image (ChatImageWidget)',
                    ChatImageWidget(
                      uri: 'https://picsum.photos/300/200?random=3',
                      width: 240,
                      height: 180,
                      fit: BoxFit.cover,
                      isCurrentUser: false,
                      theme: Theme.of(context),
                    ),
                  ),

                  _buildTestSection(
                    'Working Image - Current User (ChatImageWidget)',
                    ChatImageWidget(
                      uri: 'https://picsum.photos/300/200?random=4',
                      width: 240,
                      height: 180,
                      fit: BoxFit.cover,
                      isCurrentUser: true,
                      theme: Theme.of(context),
                    ),
                  ),

                  _buildTestSection(
                    'Broken Image (ChatImageWidget)',
                    ChatImageWidget(
                      uri:
                          'https://broken-url-that-does-not-exist.com/image3.jpg',
                      width: 240,
                      height: 180,
                      fit: BoxFit.cover,
                      isCurrentUser: false,
                      theme: Theme.of(context),
                    ),
                  ),

                  _buildTestSection(
                    'Broken Image - Current User (ChatImageWidget)',
                    ChatImageWidget(
                      uri:
                          'https://broken-url-that-does-not-exist.com/image4.jpg',
                      width: 240,
                      height: 180,
                      fit: BoxFit.cover,
                      isCurrentUser: true,
                      theme: Theme.of(context),
                    ),
                  ),

                  _buildTestSection(
                    'Invalid URI (ChatImageWidget)',
                    ChatImageWidget(
                      uri: 'invalid-uri-format',
                      width: 240,
                      height: 180,
                      fit: BoxFit.cover,
                      isCurrentUser: false,
                      theme: Theme.of(context),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'Expected Results:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '✅ Working images: Display normally with no color tints\n'
                    '✅ Error states: Gray background with gray icons/text\n'
                    '✅ Loading states: Gray background with gray spinner\n'
                    '❌ NO RED COLORING should appear anywhere',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection(String title, Widget child) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Center(child: child),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Check: No red coloring should appear in this image component',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
