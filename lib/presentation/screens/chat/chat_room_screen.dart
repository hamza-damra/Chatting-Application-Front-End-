import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/models/chat_room_model.dart';
import '../../../domain/models/message_model.dart';
import '../../../presentation/blocs/chat/chat_bloc.dart';
import '../../../presentation/blocs/chat/chat_state.dart';
import '../../../presentation/blocs/messages/message_bloc.dart';
import '../../../presentation/blocs/messages/message_event.dart';
import '../../../presentation/widgets/chat/chat_messages_widget.dart';
import '../../../presentation/widgets/chat/professional_chat_input.dart';
import '../../../presentation/widgets/chat/professional_attachment_menu.dart';
import '../../../widgets/shimmer_widgets.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatRoomId;

  const ChatRoomScreen({super.key, required this.chatRoomId});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isTyping = false;
  bool _isAttachmentMenuOpen = false;
  ChatRoomModel? _chatRoom;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();

    // Load chat room details
    _loadChatRoom();

    // Load messages
    context.read<MessageBloc>().add(
      LoadMessages(chatRoomId: widget.chatRoomId),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _loadChatRoom() {
    // Get the current state of the ChatBloc
    final chatState = context.read<ChatBloc>().state;

    if (chatState is ChatRoomsLoaded) {
      setState(() {
        // Find the chat room or set to null
        _chatRoom = chatState.chatRooms.cast<ChatRoomModel?>().firstWhere(
          (room) => room != null && room.id == widget.chatRoomId,
          orElse: () => null,
        );
        _currentUserId = chatState.currentUserId;
      });
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();

    if (message.isNotEmpty && _currentUserId != null) {
      context.read<MessageBloc>().add(
        SendMessage(
          chatRoomId: widget.chatRoomId,
          content: message,
          contentType: MessageContentType.text,
        ),
      );

      _messageController.clear();
    }
  }

  void _sendTypingIndicator(bool isTyping) {
    if (_isTyping != isTyping) {
      setState(() {
        _isTyping = isTyping;
      });

      context.read<MessageBloc>().add(
        SendTypingIndicator(chatRoomId: widget.chatRoomId, isTyping: isTyping),
      );
    }
  }

  void _toggleAttachmentMenu() {
    setState(() {
      _isAttachmentMenuOpen = !_isAttachmentMenuOpen;
    });
  }

  Widget _buildProfessionalAttachmentMenu() {
    return ProfessionalAttachmentMenu(
      onPhotoPressed: () {
        _toggleAttachmentMenu();
        // Implement photo attachment
      },
      onCameraPressed: () {
        _toggleAttachmentMenu();
        // Implement camera capture
      },
      onVideoPressed: () {
        _toggleAttachmentMenu();
        // Implement video attachment
      },
      onFilePressed: () {
        _toggleAttachmentMenu();
        // Implement file attachment
      },
      isEnabled: true,
      isUploading: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildAppBarTitle(),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showOptions(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child:
                _currentUserId != null
                    ? ChatMessagesWidget(
                      chatRoomId: widget.chatRoomId,
                      currentUserId: _currentUserId!,
                    )
                    : Center(child: ShimmerWidgets.authLoadingShimmer()),
          ),

          // Professional attachment menu
          if (_isAttachmentMenuOpen) _buildProfessionalAttachmentMenu(),

          // Professional message input
          ProfessionalChatInput(
            controller: _messageController,
            onSendMessage: _sendMessage,
            onAttachmentPressed: _toggleAttachmentMenu,
            onTypingChanged: _sendTypingIndicator,
            hintText: 'Type a message...',
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarTitle() {
    if (_chatRoom == null || _currentUserId == null) {
      return const Text('Chat');
    }

    final displayName = _chatRoom!.getDisplayName(_currentUserId!);
    final isGroup = _chatRoom!.type == ChatRoomType.group;
    final isOnline = !isGroup && _chatRoom!.isUserOnline(_currentUserId!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(displayName),
        Text(
          isGroup
              ? '${_chatRoom!.participants.length} members'
              : (isOnline ? 'Online' : 'Offline'),
          style: TextStyle(
            fontSize: 12,
            color: isOnline ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Search messages'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement search functionality
                },
              ),
              if (_chatRoom?.type == ChatRoomType.group)
                ListTile(
                  leading: const Icon(Icons.group),
                  title: const Text('View members'),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to group members screen
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Clear chat'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement clear chat functionality
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
