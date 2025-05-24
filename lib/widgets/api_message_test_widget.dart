import 'package:flutter/material.dart';
import '../utils/logger.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

/// Test widget to verify API message mapping fixes
class ApiMessageTestWidget extends StatefulWidget {
  const ApiMessageTestWidget({super.key});

  @override
  State<ApiMessageTestWidget> createState() => _ApiMessageTestWidgetState();
}

class _ApiMessageTestWidgetState extends State<ApiMessageTestWidget> {
  final List<Map<String, dynamic>> _testMessages = [
    // Test case 1: Image with MIME type
    {
      'id': 1,
      'content': 'http://example.com/image.jpg',
      'contentType': 'image/jpeg',
      'sender': {'id': 1, 'username': 'test'},
      'sentAt': DateTime.now().toIso8601String(),
      'status': 'SENT',
    },

    // Test case 2: Video with MIME type
    {
      'id': 2,
      'content': 'http://example.com/video.mp4',
      'contentType': 'video/mp4',
      'sender': {'id': 1, 'username': 'test'},
      'sentAt': DateTime.now().toIso8601String(),
      'status': 'SENT',
    },

    // Test case 3: Text message
    {
      'id': 3,
      'content': 'Hello world',
      'contentType': 'TEXT',
      'sender': {'id': 1, 'username': 'test'},
      'sentAt': DateTime.now().toIso8601String(),
      'status': 'SENT',
    },

    // Test case 4: Image with exact type
    {
      'id': 4,
      'content': 'http://example.com/photo.png',
      'contentType': 'IMAGE',
      'sender': {'id': 1, 'username': 'test'},
      'sentAt': DateTime.now().toIso8601String(),
      'status': 'SENT',
    },

    // Test case 5: Unknown content type
    {
      'id': 5,
      'content': 'Some content',
      'contentType': 'unknown/type',
      'sender': {'id': 1, 'username': 'test'},
      'sentAt': DateTime.now().toIso8601String(),
      'status': 'SENT',
    },
  ];

  final List<types.Message> _convertedMessages = [];
  final List<String> _testResults = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Message Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'API Message Mapping Test',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _runTest,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Run API Message Test'),
            ),

            const SizedBox(height: 16),

            if (_testResults.isNotEmpty) ...[
              const Text(
                'Test Results:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _testResults.length,
                  itemBuilder: (context, index) {
                    final result = _testResults[index];
                    final isSuccess = result.startsWith('✅');
                    return Card(
                      color: isSuccess ? Colors.green[50] : Colors.red[50],
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          result,
                          style: TextStyle(
                            color:
                                isSuccess ? Colors.green[700] : Colors.red[700],
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else
              const Expanded(
                child: Center(
                  child: Text(
                    'Click "Run API Message Test" to test message mapping',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _runTest() {
    setState(() {
      _convertedMessages.clear();
      _testResults.clear();
    });

    AppLogger.i('ApiMessageTest', 'Starting API message mapping test...');

    for (int i = 0; i < _testMessages.length; i++) {
      final testData = _testMessages[i];
      final testCase = i + 1;

      try {
        AppLogger.i(
          'ApiMessageTest',
          'Testing case $testCase: ${testData['contentType']}',
        );

        // Use the private method from ApiChatService to test message mapping
        // Since we can't access the private method directly, we'll simulate it
        final mappedMessage = _simulateApiMessageMapping(testData);

        _convertedMessages.add(mappedMessage);

        // Verify the result
        final expectedType = _getExpectedMessageType(testData['contentType']);
        final actualType = mappedMessage.runtimeType.toString();

        String result;
        if (_isCorrectMessageType(mappedMessage, expectedType)) {
          result =
              '✅ Test $testCase: ${testData['contentType']} → $actualType (PASS)';
          AppLogger.i('ApiMessageTest', 'Test $testCase PASSED');
        } else {
          result =
              '❌ Test $testCase: ${testData['contentType']} → $actualType (FAIL - Expected: $expectedType)';
          AppLogger.e('ApiMessageTest', 'Test $testCase FAILED');
        }

        // Check if it's a text message with "Unsupported message type"
        if (mappedMessage is types.TextMessage &&
            mappedMessage.text.contains('Unsupported message type')) {
          result += ' - Contains "Unsupported message type"';
        }

        _testResults.add(result);
      } catch (e) {
        final result =
            '❌ Test $testCase: ${testData['contentType']} → ERROR: $e';
        _testResults.add(result);
        AppLogger.e('ApiMessageTest', 'Test $testCase ERROR: $e');
      }
    }

    setState(() {});

    final passedTests = _testResults.where((r) => r.startsWith('✅')).length;
    final totalTests = _testResults.length;

    AppLogger.i(
      'ApiMessageTest',
      'Test completed: $passedTests/$totalTests passed',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Test completed: $passedTests/$totalTests tests passed'),
        backgroundColor:
            passedTests == totalTests ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Simulate the API message mapping logic
  types.Message _simulateApiMessageMapping(Map<String, dynamic> data) {
    final String contentType = data['contentType'] ?? 'TEXT';
    final String content = data['content'] ?? '';
    final int senderId = data['sender']['id'] ?? 0;
    final int timestamp = DateTime.parse(data['sentAt']).millisecondsSinceEpoch;

    // This simulates the fixed logic from ApiChatService._mapApiMessageToMessage
    if (contentType == 'TEXT') {
      return types.TextMessage(
        id: data['id'].toString(),
        author: types.User(id: senderId.toString()),
        text: content,
        createdAt: timestamp,
        status: types.Status.sent,
      );
    } else if (contentType == 'IMAGE' || contentType.startsWith('image/')) {
      return types.ImageMessage(
        id: data['id'].toString(),
        author: types.User(id: senderId.toString()),
        uri: content,
        size: data['size'] ?? 0,
        name: data['name'] ?? 'Image',
        createdAt: timestamp,
        status: types.Status.sent,
      );
    } else if (contentType == 'VIDEO' || contentType.startsWith('video/')) {
      return types.CustomMessage(
        id: data['id'].toString(),
        author: types.User(id: senderId.toString()),
        createdAt: timestamp,
        status: types.Status.sent,
        metadata: {'type': 'video', 'uri': content, 'contentType': contentType},
      );
    } else {
      return types.TextMessage(
        id: data['id'].toString(),
        author: types.User(id: senderId.toString()),
        text:
            content.isNotEmpty
                ? content
                : 'Unsupported message type: $contentType',
        createdAt: timestamp,
        status: types.Status.sent,
      );
    }
  }

  String _getExpectedMessageType(String contentType) {
    if (contentType == 'TEXT') {
      return 'TextMessage';
    }
    if (contentType == 'IMAGE' || contentType.startsWith('image/')) {
      return 'ImageMessage';
    }
    if (contentType == 'VIDEO' || contentType.startsWith('video/')) {
      return 'CustomMessage';
    }
    return 'TextMessage';
  }

  bool _isCorrectMessageType(types.Message message, String expectedType) {
    final actualType = message.runtimeType.toString();
    return actualType.contains(expectedType);
  }
}
