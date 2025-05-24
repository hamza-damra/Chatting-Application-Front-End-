import 'package:flutter/material.dart';
import '../widgets/chat_image_debug_widget.dart';
import '../widgets/image_view_test_widget.dart';
import '../widgets/api_message_test_widget.dart';

import '../domain/models/message_model.dart';
import '../utils/logger.dart';

class DebugImageScreen extends StatelessWidget {
  const DebugImageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Debug Tools'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Image Display Debug Tools',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Message Type Parsing Test
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Message Type Parsing Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Test how different content types are parsed into MessageContentType enum.',
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _testMessageTypeParsing(context),
                      icon: const Icon(Icons.science),
                      label: const Text('Run Type Parsing Test'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Chat Image Debug
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chat Message Image Display',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Test how images are displayed in chat message bubbles.',
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChatImageDebugWidget(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble),
                      label: const Text('Open Chat Image Debug'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // API Message Test
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'API Message Mapping Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Test how API messages are converted to flutter_chat_types.',
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ApiMessageTestWidget(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.api),
                      label: const Text('Open API Message Test'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Image Widget Test
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Image Widget Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Test image loading, caching, and error handling.',
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ImageViewTestWidget(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('Open Image Widget Test'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Quick Test Results
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Test Results',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTestResult(
                                'image/jpeg',
                                MessageModel.parseMessageType('image/jpeg'),
                              ),
                              _buildTestResult(
                                'image/png',
                                MessageModel.parseMessageType('image/png'),
                              ),
                              _buildTestResult(
                                'video/mp4',
                                MessageModel.parseMessageType('video/mp4'),
                              ),
                              _buildTestResult(
                                'audio/mpeg',
                                MessageModel.parseMessageType('audio/mpeg'),
                              ),
                              _buildTestResult(
                                'application/pdf',
                                MessageModel.parseMessageType(
                                  'application/pdf',
                                ),
                              ),
                              _buildTestResult(
                                'TEXT',
                                MessageModel.parseMessageType('TEXT'),
                              ),
                              _buildTestResult(
                                'IMAGE',
                                MessageModel.parseMessageType('IMAGE'),
                              ),
                              _buildTestResult(
                                'null',
                                MessageModel.parseMessageType(null),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResult(String input, MessageContentType result) {
    Color resultColor;
    switch (result) {
      case MessageContentType.image:
        resultColor = Colors.green;
        break;
      case MessageContentType.video:
        resultColor = Colors.blue;
        break;
      case MessageContentType.audio:
        resultColor = Colors.orange;
        break;
      case MessageContentType.file:
        resultColor = Colors.purple;
        break;
      case MessageContentType.text:
        resultColor = Colors.grey;
        break;
      case MessageContentType.location:
        resultColor = Colors.red;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(input, style: const TextStyle(fontFamily: 'monospace')),
          ),
          const Text(' → '),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: resultColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: resultColor),
              ),
              child: Text(
                result.toString().split('.').last.toUpperCase(),
                style: TextStyle(
                  color: resultColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _testMessageTypeParsing(BuildContext context) {
    AppLogger.i('DebugImageScreen', 'Running message type parsing test...');

    final testCases = [
      'image/jpeg',
      'image/png',
      'image/gif',
      'video/mp4',
      'video/mpeg',
      'audio/mpeg',
      'audio/wav',
      'application/pdf',
      'application/msword',
      'text/plain',
      'TEXT',
      'IMAGE',
      'VIDEO',
      'AUDIO',
      'FILE',
      null,
      '',
      'unknown/type',
    ];

    for (final testCase in testCases) {
      final result = MessageModel.parseMessageType(testCase);
      AppLogger.i('DebugImageScreen', 'Input: "$testCase" -> Result: $result');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Message type parsing test completed. Check logs for detailed results.',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }
}
