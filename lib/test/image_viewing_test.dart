import 'package:flutter/material.dart';
import '../domain/models/message_model.dart';
import '../domain/models/user_model.dart';
import '../domain/models/chat_room_model.dart';
import '../presentation/widgets/chat/message_bubble.dart';
import '../utils/logger.dart';

/// Test widget to verify image viewing functionality is working
class ImageViewingTest extends StatelessWidget {
  const ImageViewingTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Viewing Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Testing Image Message Display',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Test case 1: Image with relative path (from WebSocket upload)
            const Text('Test 1: Relative path from WebSocket upload'),
            const SizedBox(height: 8),
            _buildTestMessage(
              content: 'uploads/images/20250124-123456-test.jpg',
              contentType: MessageContentType.image,
              metadata: {
                'attachmentUrl': 'uploads/images/20250124-123456-test.jpg',
                'originalContent': 'test.jpg',
                'contentType': 'image/jpeg',
              },
            ),

            const SizedBox(height: 24),

            // Test case 2: Image with just filename
            const Text('Test 2: Just filename (should be normalized)'),
            const SizedBox(height: 8),
            _buildTestMessage(
              content: 'example.jpg',
              contentType: MessageContentType.image,
              metadata: {'contentType': 'image/jpeg'},
            ),

            const SizedBox(height: 24),

            // Test case 3: Image with full URL
            const Text('Test 3: Full URL'),
            const SizedBox(height: 8),
            _buildTestMessage(
              content:
                  'http://abusaker.zapto.org:8080/uploads/images/sample.jpg',
              contentType: MessageContentType.image,
              metadata: {'contentType': 'image/jpeg'},
            ),

            const SizedBox(height: 24),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔍 How to Test',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Tap on any image above to open the image viewer\n'
                    '2. Check if images load correctly\n'
                    '3. Verify that URLs are being normalized properly\n'
                    '4. Check console logs for URL processing details',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestMessage({
    required String content,
    required MessageContentType contentType,
    Map<String, dynamic>? metadata,
  }) {
    // Create test user
    final testUser = UserModel(
      id: 1,
      username: 'testuser',
      email: 'test@example.com',
      fullName: 'Test User',
      isOnline: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Create test chat room
    final testChatRoom = ChatRoomModel(
      id: '1',
      name: 'Test Room',
      type: ChatRoomType.group,
      createdAt: DateTime.now(),
      participants: [testUser],
    );

    // Create test message
    final testMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: testUser,
      chatRoom: testChatRoom,
      content: content,
      type: contentType,
      status: MessageStatus.sent,
      metadata: metadata,
      sentAt: DateTime.now(),
    );

    AppLogger.i(
      'ImageViewingTest',
      'Created test message with content: $content',
    );
    if (metadata != null) {
      AppLogger.i('ImageViewingTest', 'Message metadata: $metadata');
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: MessageBubble(message: testMessage, isMe: false),
    );
  }
}

/// Extension to easily add this test to any app
extension ImageViewingTestExtension on BuildContext {
  void showImageViewingTest() {
    Navigator.push(
      this,
      MaterialPageRoute(builder: (context) => const ImageViewingTest()),
    );
  }
}
