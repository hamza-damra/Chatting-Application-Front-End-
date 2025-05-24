import 'package:flutter/material.dart';
import '../services/websocket_service.dart';
import '../widgets/file_upload_widget.dart';

/// Example of how to properly integrate WebSocket file upload in a chat screen
/// This shows the CORRECT way to handle file uploads via WebSocket chunks
class CorrectFileUploadExample extends StatefulWidget {
  final int chatRoomId;
  final WebSocketService webSocketService;

  const CorrectFileUploadExample({
    super.key,
    required this.chatRoomId,
    required this.webSocketService,
  });

  @override
  State<CorrectFileUploadExample> createState() =>
      _CorrectFileUploadExampleState();
}

class _CorrectFileUploadExampleState extends State<CorrectFileUploadExample> {
  final TextEditingController _messageController = TextEditingController();
  bool _showFileUpload = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Room ${widget.chatRoomId}'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // Success banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '✅ CORRECT: Using WebSocket Chunked File Upload',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Files are uploaded via /app/file.chunk endpoint in 32KB chunks',
                  style: TextStyle(color: Colors.green.shade600, fontSize: 12),
                ),
              ],
            ),
          ),

          // Chat messages area (placeholder)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: const Center(
                child: Text(
                  'Chat messages would appear here...\n\n'
                  'Files uploaded via this widget will appear as proper attachments,\n'
                  'not as text messages with file paths.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),

          // File upload widget (conditionally shown)
          if (_showFileUpload)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border(top: BorderSide(color: Colors.blue.shade200)),
              ),
              child: FileUploadWidget(
                chatRoomId: widget.chatRoomId,
                webSocketService: widget.webSocketService,
                onUploadStart: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📤 Starting file upload...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                onUploadComplete: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ File uploaded successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  setState(() {
                    _showFileUpload = false;
                  });
                },
                onUploadError: (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Upload failed: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              ),
            ),

          // Bottom input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                // File attachment button
                IconButton(
                  icon: Icon(
                    Icons.attach_file,
                    color: _showFileUpload ? Colors.blue : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _showFileUpload = !_showFileUpload;
                    });
                  },
                  tooltip: 'Attach File (WebSocket Upload)',
                ),

                // Text input
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),

                const SizedBox(width: 8),

                // Send button
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (_messageController.text.trim().isNotEmpty) {
                      // ✅ CORRECT: Send text message via WebSocket
                      _sendTextMessage(_messageController.text.trim());
                      _messageController.clear();
                    }
                  },
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ CORRECT: Send text message via WebSocket
  void _sendTextMessage(String content) {
    try {
      widget.webSocketService.sendMessage(
        roomId: widget.chatRoomId,
        content: content,
        contentType: 'TEXT',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📤 Message sent'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Example of WRONG approach (DO NOT USE)
class WrongFileUploadExample extends StatelessWidget {
  const WrongFileUploadExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.red.shade50,
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.error, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '❌ WRONG: Do NOT send file paths as messages',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Example of what NOT to do:\n'
            '• sendMessage("uploads/auto_generated/123/file.jpg")\n'
            '• Using HTTP upload instead of WebSocket\n'
            '• Creating fake file paths client-side',
            style: TextStyle(color: Colors.red.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
