import 'package:flutter/material.dart';
import '../models/chat_room.dart';
import '../models/message.dart';
import '../presentation/widgets/chat/professional_chat_input.dart';
import '../presentation/widgets/chat/professional_attachment_menu.dart';
import '../widgets/modern_message_bubble.dart';

class CustomChatWidget extends StatefulWidget {
  final ChatRoom chatRoom;
  final List<Message> messages;
  final Function(String) onSendMessage;
  final Function(String) onSendAttachment;
  final int currentUserId;
  final bool showUserAvatars;

  const CustomChatWidget({
    super.key,
    required this.chatRoom,
    required this.messages,
    required this.onSendMessage,
    required this.onSendAttachment,
    required this.currentUserId,
    this.showUserAvatars = true,
  });

  @override
  State<CustomChatWidget> createState() => _CustomChatWidgetState();
}

class _CustomChatWidgetState extends State<CustomChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAttachmentMenuOpen = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      widget.onSendMessage(message);
      _messageController.clear();

      // Scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _toggleAttachmentMenu() {
    setState(() {
      _isAttachmentMenuOpen = !_isAttachmentMenuOpen;
    });
  }

  bool _shouldShowSenderName(int index) {
    if (index == 0) return true;

    final currentMessage = widget.messages[index];
    final previousMessage = widget.messages[index - 1];

    // Show sender name if different from previous message sender
    return currentMessage.senderId != previousMessage.senderId;
  }

  void _onMessageTap(Message message) {
    // Handle message tap (e.g., show details, copy text, etc.)
    // You can customize this based on your needs
    // For example: show message details, copy text, etc.
  }

  void _onMessageLongPress(Message message) {
    // Handle message long press (e.g., show context menu)
    _showMessageContextMenu(message);
  }

  void _showMessageContextMenu(Message message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text('Copy'),
                  onTap: () {
                    Navigator.pop(context);
                    // Copy message content
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.reply),
                  title: const Text('Reply'),
                  onTap: () {
                    Navigator.pop(context);
                    // Reply to message
                  },
                ),
                if (message.senderId == widget.currentUserId)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      // Delete message
                    },
                  ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: widget.messages.length,
            itemBuilder: (context, index) {
              final message = widget.messages[index];
              final isCurrentUser = message.senderId == widget.currentUserId;

              // Determine if we should show sender name (for group chats)
              final showSenderName = _shouldShowSenderName(index);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: ModernMessageBubble(
                  message: message,
                  isCurrentUser: isCurrentUser,
                  showSenderName:
                      showSenderName &&
                      !isCurrentUser &&
                      widget.showUserAvatars,
                  showTimestamp: true,
                  onTap: () => _onMessageTap(message),
                  onLongPress: () => _onMessageLongPress(message),
                ),
              );
            },
          ),
        ),
        if (_isAttachmentMenuOpen) _buildProfessionalAttachmentMenu(),
        ProfessionalChatInput(
          controller: _messageController,
          onSendMessage: _sendMessage,
          onAttachmentPressed: _toggleAttachmentMenu,
          hintText: 'Type a message...',
        ),
      ],
    );
  }

  Widget _buildProfessionalAttachmentMenu() {
    return ProfessionalAttachmentMenu(
      onPhotoPressed: () {
        widget.onSendAttachment('image');
        setState(() {
          _isAttachmentMenuOpen = false;
        });
      },
      onCameraPressed: () {
        widget.onSendAttachment('camera');
        setState(() {
          _isAttachmentMenuOpen = false;
        });
      },
      onVideoPressed: () {
        widget.onSendAttachment('video');
        setState(() {
          _isAttachmentMenuOpen = false;
        });
      },
      onFilePressed: () {
        widget.onSendAttachment('document');
        setState(() {
          _isAttachmentMenuOpen = false;
        });
      },
      isEnabled: true,
      isUploading: false,
    );
  }
}
