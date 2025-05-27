import 'dart:async';
import 'package:vector/models/chat_room.dart';
import 'package:vector/providers/api_auth_provider.dart';
import 'package:vector/providers/chat_provider.dart';
import 'package:vector/services/improved_file_upload_service.dart';
import 'package:vector/services/websocket_service.dart' as ws;
import 'package:vector/screens/chat/group_settings_screen.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

import '../../widgets/custom_chat_widget_new.dart';
import '../../widgets/block_user_button.dart';
import '../../services/screen_state_manager.dart';
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

  // Get the other user's ID for private chats (excluding current user)
  int? get _otherUserId {
    if (widget.chatRoom.participantIds.length == 2) {
      try {
        return widget.chatRoom.participantIds.firstWhere(
          (id) => id != _currentUserId,
        );
      } catch (e) {
        AppLogger.w('ChatScreen', 'Could not find other user ID: $e');
        return null;
      }
    }
    return null;
  }

  // Get the other user's name for private chats
  String get _otherUserName {
    if (widget.chatRoom.participantIds.length == 2) {
      // For private chats, use the room name which should be the other user's name
      return widget.chatRoom.name ?? 'User';
    }
    return widget.chatRoom.name ?? 'Chat';
  }

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

      // Update screen state to indicate user is in this chat room
      ScreenStateManager.instance.updateCurrentScreen(
        ScreenStateManager.chatRoomScreen,
        chatRoomId: _roomIdString,
      );
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

    // Clear screen state when leaving chat room
    ScreenStateManager.instance.updateCurrentScreen(
      ScreenStateManager.otherScreen,
    );

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
        // App is backgrounded, leave room and clear screen state
        _webSocketService.leaveRoom(_roomId);
        ScreenStateManager.instance.clearCurrentScreen();
        AppLogger.i('ChatScreen', 'App backgrounded, left room $_roomId');
        break;
      case AppLifecycleState.resumed:
        // App is foregrounded, re-enter room and restore screen state
        _webSocketService.enterRoom(_roomId);
        ScreenStateManager.instance.updateCurrentScreen(
          ScreenStateManager.chatRoomScreen,
          chatRoomId: _roomIdString,
        );
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

  void _handleGroupLeft() {
    // Navigate back to group list
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showGroupMenu() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Group Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                GroupSettingsScreen(chatRoom: widget.chatRoom),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.red),
                  title: const Text(
                    'Leave Group',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showLeaveGroupDialog();
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showPrivateChatMenu() {
    final otherUserId = _otherUserId;
    if (otherUserId == null || otherUserId <= 0) {
      AppLogger.w(
        'ChatScreen',
        'Cannot show private chat menu: invalid other user ID',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: const Text(
                    'Block User',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showBlockUserDialog();
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showBlockUserDialog() {
    final otherUserId = _otherUserId;
    if (otherUserId == null || otherUserId <= 0) {
      AppLogger.w(
        'ChatScreen',
        'Cannot show block dialog: invalid other user ID',
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Block $_otherUserName?'),
            content: const Text(
              'This user will not be able to send you messages. You can unblock them later from Settings > Blocked Users.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              BlockUserButton(
                userId: otherUserId,
                userName: _otherUserName,
                onBlockStatusChanged: () {
                  Navigator.of(context).pop();
                  // Optionally navigate back or show a message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$_otherUserName has been blocked'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
    );
  }

  void _showLeaveGroupDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Leave Group'),
            content: Text(
              'Are you sure you want to leave "${widget.chatRoom.name}"?\n\n'
              'You will no longer receive messages from this group.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _leaveGroup();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Leave Group'),
              ),
            ],
          ),
    );
  }

  Future<void> _leaveGroup() async {
    try {
      final success = await _chatProvider.leaveGroup(widget.chatRoom.id);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully left the group'),
            backgroundColor: Colors.green,
          ),
        );
        _handleGroupLeft();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_chatProvider.error ?? 'Failed to leave group'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error leaving group: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if this is a group chat (has multiple participants)
    final isGroupChat = widget.chatRoom.participantIds.length > 2;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatRoom.name ?? 'Chat'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMessages),
          if (isGroupChat)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showGroupMenu,
            )
          else
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showPrivateChatMenu,
            ),
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

    // Use the new pagination-enabled chat widget
    return CustomChatWidgetNew(
      onSendMessage: (message) => _sendTextMessage(message),
      onSendAttachment:
          (url, contentType) => _sendFileMessage(url, contentType),
      currentUserId: _currentUserId,
      webSocketService: _uploadService,
      roomId: widget.chatRoom.id,
      otherUserId: _otherUserId,
      otherUserName: _otherUserName,
      pageSize: 20, // Configure page size for pagination
    );
  }
}
