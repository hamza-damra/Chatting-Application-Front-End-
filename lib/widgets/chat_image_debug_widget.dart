import 'package:flutter/material.dart';
import '../domain/models/message_model.dart';
import '../domain/models/user_model.dart';
import '../domain/models/chat_room_model.dart';
import '../presentation/widgets/chat/message_bubble.dart';
import '../utils/logger.dart';

/// Debug widget to test image display in chat messages
class ChatImageDebugWidget extends StatefulWidget {
  const ChatImageDebugWidget({super.key});

  @override
  State<ChatImageDebugWidget> createState() => _ChatImageDebugWidgetState();
}

class _ChatImageDebugWidgetState extends State<ChatImageDebugWidget> {
  late List<MessageModel> _testMessages;

  @override
  void initState() {
    super.initState();
    _createTestMessages();
  }

  void _createTestMessages() {
    final testUser = UserModel(
      id: 1, // UserModel expects int, not String
      username: 'testuser',
      email: 'test@example.com',
      fullName: 'Test User',
      createdAt: DateTime.now(),
    );

    final testChatRoom = ChatRoomModel(
      id: '1',
      name: 'Test Room',
      type: ChatRoomType.private, // Required parameter
      createdAt: DateTime.now(),
      participants: [testUser],
    );

    _testMessages = [
      // Test 1: Image with MIME type
      MessageModel(
        id: '1',
        sender: testUser,
        chatRoom: testChatRoom,
        content: 'https://picsum.photos/300/200?random=1',
        type: MessageContentType.image,
        status: MessageStatus.sent,
        sentAt: DateTime.now(),
        metadata: {
          'contentType': 'image/jpeg',
          'attachmentUrl': 'https://picsum.photos/300/200?random=1',
        },
      ),

      // Test 2: Image with just filename
      MessageModel(
        id: '2',
        sender: testUser,
        chatRoom: testChatRoom,
        content: 'test-image.jpg',
        type: MessageContentType.image,
        status: MessageStatus.sent,
        sentAt: DateTime.now(),
        metadata: {'contentType': 'image/jpeg'},
      ),

      // Test 3: Image with relative path
      MessageModel(
        id: '3',
        sender: testUser,
        chatRoom: testChatRoom,
        content: 'uploads/images/photo.png',
        type: MessageContentType.image,
        status: MessageStatus.sent,
        sentAt: DateTime.now(),
        metadata: {'contentType': 'image/png'},
      ),

      // Test 4: Text message for comparison
      MessageModel(
        id: '4',
        sender: testUser,
        chatRoom: testChatRoom,
        content: 'This is a text message',
        type: MessageContentType.text,
        status: MessageStatus.sent,
        sentAt: DateTime.now(),
      ),

      // Test 5: Image with metadata URL
      MessageModel(
        id: '5',
        sender: testUser,
        chatRoom: testChatRoom,
        content: '',
        type: MessageContentType.image,
        status: MessageStatus.sent,
        sentAt: DateTime.now(),
        metadata: {
          'contentType': 'image/jpeg',
          'uri':
              'https://via.placeholder.com/300x200/FF0000/FFFFFF?text=Test+Image',
        },
      ),

      // Test 6: Simulate backend message with MIME type
      MessageModel(
        id: '6',
        sender: testUser,
        chatRoom: testChatRoom,
        content: 'image_123456.jpg',
        type:
            MessageContentType.image, // This should be parsed from 'image/jpeg'
        status: MessageStatus.sent,
        sentAt: DateTime.now(),
        metadata: {
          'originalContentType': 'image/jpeg', // Simulate what backend sends
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Image Debug'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _createTestMessages();
              });
              AppLogger.i('ChatImageDebug', 'Test messages refreshed');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chat Image Display Debug',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This widget tests different image message scenarios:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  '• Network URLs\n'
                  '• Filenames only\n'
                  '• Relative paths\n'
                  '• Metadata URLs\n'
                  '• MIME type parsing',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _testMessageTypeParsing,
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Test Type Parsing'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _testMessages.length,
              itemBuilder: (context, index) {
                final message = _testMessages[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Test ${index + 1}: ${message.type.toString().split('.').last.toUpperCase()}',
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ID: ${message.id}'),
                              Text('Content: ${message.content}'),
                              Text('Type: ${message.type}'),
                              Text('Metadata: ${message.metadata}'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Rendered Message:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        MessageBubble(message: message, isMe: index % 2 == 0),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _testMessageTypeParsing() {
    AppLogger.i('ChatImageDebug', 'Testing message type parsing...');

    final testCases = [
      'image/jpeg',
      'image/png',
      'image/gif',
      'video/mp4',
      'audio/mpeg',
      'application/pdf',
      'text/plain',
      'IMAGE',
      'TEXT',
      'VIDEO',
      null,
      '',
    ];

    for (final testCase in testCases) {
      final parsedType = MessageModel.parseMessageType(testCase);
      AppLogger.i(
        'ChatImageDebug',
        'ContentType: "$testCase" -> Parsed as: $parsedType',
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Type parsing test completed. Check logs for results.'),
        duration: Duration(seconds: 3),
      ),
    );
  }
}
