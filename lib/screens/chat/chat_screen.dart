import 'dart:async';
import 'package:chatting_application/models/chat_room.dart';
import 'package:chatting_application/models/message.dart';
import 'package:chatting_application/providers/api_auth_provider.dart';
import 'package:chatting_application/providers/chat_provider.dart';
import 'package:chatting_application/services/improved_file_upload_service.dart';
import 'package:chatting_application/services/websocket_service.dart' as ws;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

import '../../widgets/custom_chat_widget_new.dart';
import '../../utils/logger.dart';

class ChatScreen extends StatefulWidget {
  final ChatRoom chatRoom;

  const ChatScreen({super.key, required this.chatRoom});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  late final ChatProvider _chatProvider;
  late final ImprovedFileUploadService _uploadService;
  late final ws.WebSocketService _webSocketService;
  late final int _currentUserId;

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  final ScrollController _scrollController = ScrollController();

  String get _roomIdString => widget.chatRoom.id.toString();
  int get _roomId => widget.chatRoom.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize providers after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatProvider = Provider.of<ChatProvider>(context, listen: false);
      _uploadService = Provider.of<ImprovedFileUploadService>(
        context,
        listen: false,
      );
      _webSocketService = Provider.of<ws.WebSocketService>(
        context,
        listen: false,
      );
      final auth = Provider.of<ApiAuthProvider>(context, listen: false);
      _currentUserId = auth.user?.id ?? 0;

      _loadMessages();
      _setupWebSocketListener();

      // Mark user as active in this room
      _webSocketService.enterRoom(_roomId);
    });
  }

  @override
  void dispose() {
    // Mark user as inactive in this room
    _webSocketService.leaveRoom(_roomId);

    // Clear unread count immediately when leaving the chat screen
    _chatProvider.clearUnreadCount(_roomIdString);

    // Unsubscribe from room messages when leaving the chat screen
    _chatProvider.unsubscribeFromRoom(_roomIdString);

    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    AppLogger.i(
      'ChatScreen',
      'Unsubscribed from room $_roomIdString on dispose',
    );
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // App is backgrounded, leave room
        _webSocketService.leaveRoom(_roomId);
        AppLogger.i('ChatScreen', 'App backgrounded, left room $_roomId');
        break;
      case AppLifecycleState.resumed:
        // App is foregrounded, re-enter room
        _webSocketService.enterRoom(_roomId);
        AppLogger.i('ChatScreen', 'App resumed, entered room $_roomId');
        break;
      default:
        break;
    }
  }

  void _setupWebSocketListener() {
    AppLogger.i(
      'ChatScreen',
      'Setting up WebSocket listener for room: $_roomIdString',
    );

    // WebSocket subscription is now handled by ChatProvider
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Create a types.Room for the ChatProvider
      final room = types.Room(
        id: _roomIdString,
        type: types.RoomType.direct,
        users: [], // Will be populated by the provider
      );

      // Select the room in ChatProvider - this will load messages automatically
      await _chatProvider.selectRoom(room);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Scroll to bottom after loading messages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load messages: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendTextMessage(String content) async {
    try {
      // The ChatProvider will handle adding the message to its list
      // and the UI will update automatically via Consumer<ChatProvider>
      await _chatProvider.sendTextMessage(
        roomId: widget.chatRoom.id.toString(),
        text: content,
      );

      if (mounted) {
        // Force a frame to be rendered before scrolling
        await Future.delayed(const Duration(milliseconds: 50));
        _scrollToBottom();
      }
    } catch (e) {
      _showError('Failed to send message: $e');
    }
  }

  Future<void> _sendFileMessage(String url, String contentType) async {
    try {
      // Check if URL is empty
      if (url.isEmpty) {
        _showError(
          'File upload completed but no URL was returned. The file may still be processing.',
        );
        return;
      }

      // The ChatProvider will handle adding the message to its list
      // and the UI will update automatically via Consumer<ChatProvider>
      await _chatProvider.sendFileMessage(_roomIdString, url, contentType);

      if (mounted) {
        // Force a frame to be rendered before scrolling
        await Future.delayed(const Duration(milliseconds: 50));
        _scrollToBottom();
      }
    } catch (e) {
      _showError('Failed to send file: $e');
    }
  }

  void _scrollToBottom() {
    // For reversed ListView, scroll to position 0
    if (_scrollController.hasClients) {
      try {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
        );
      } catch (e) {
        // Try again after a short delay
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0.0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  // Convert types.Message to Message for the CustomChatWidgetNew
  Message _convertTypesMessageToMessage(types.Message typesMsg) {
    String? attachmentUrl;
    String? contentType;
    String? content = typesMsg.id; // Default content

    if (typesMsg is types.TextMessage) {
      content = typesMsg.text;
      contentType = 'text/plain';
    } else if (typesMsg is types.ImageMessage) {
      attachmentUrl = typesMsg.uri;
      contentType = 'image/jpeg';
      content = typesMsg.name;
    } else if (typesMsg is types.FileMessage) {
      // Handle file messages (including text files)
      content = typesMsg.uri; // Use the file URL as content
      attachmentUrl = typesMsg.uri;
      contentType = typesMsg.mimeType ?? 'application/octet-stream';
      // For text files, we want the URL in the content field for detection
    } else if (typesMsg is types.CustomMessage) {
      // Handle custom messages (videos, files, etc.)
      final metadata = typesMsg.metadata;
      if (metadata != null) {
        attachmentUrl = metadata['attachmentUrl'] as String?;
        contentType = metadata['contentType'] as String?;
        content = metadata['fileName'] as String? ?? 'File';
      }
    }

    return Message(
      id: int.tryParse(typesMsg.id) ?? 0,
      senderId: int.tryParse(typesMsg.author.id) ?? 0,
      senderName:
          '${typesMsg.author.firstName ?? ''} ${typesMsg.author.lastName ?? ''}'
              .trim(),
      content: content,
      contentType: contentType,
      attachmentUrl: attachmentUrl,
      sentAt:
          typesMsg.createdAt != null
              ? DateTime.fromMillisecondsSinceEpoch(typesMsg.createdAt!)
              : DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatRoom.name ?? 'Chat'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMessages),
        ],
      ),
      body: _buildMessageList(),
    );
  }

  Widget _buildMessageList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading messages',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(_errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMessages,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Use ChatProvider's messages instead of local _messages
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final providerMessages = chatProvider.getMessages(_roomIdString);

        // Convert types.Message to Message for the widget
        final convertedMessages =
            providerMessages.map((typesMsg) {
              return _convertTypesMessageToMessage(typesMsg);
            }).toList();

        return CustomChatWidgetNew(
          messages: convertedMessages,
          onSendMessage: (message) => _sendTextMessage(message),
          onSendAttachment:
              (url, contentType) => _sendFileMessage(url, contentType),
          currentUserId: _currentUserId,
          webSocketService: _uploadService,
          roomId: widget.chatRoom.id,
        );
      },
    );
  }
}
