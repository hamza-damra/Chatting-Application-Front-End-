import 'package:flutter/material.dart';
import '../models/chat_room.dart';
import '../models/message.dart';
import '../presentation/widgets/chat/professional_chat_input.dart';
import '../presentation/widgets/chat/professional_attachment_menu.dart';
import '../widgets/enhanced_file_viewer.dart';

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

              return _buildMessageItem(message, isCurrentUser);
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

  Widget _buildMessageItem(Message message, bool isCurrentUser) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isCurrentUser ? Theme.of(context).primaryColor : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isCurrentUser && widget.showUserAvatars)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  message.senderName ?? 'Unknown',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCurrentUser ? Colors.white : Colors.black87,
                    fontSize: 12,
                  ),
                ),
              ),
            if (message.attachmentUrl != null)
              _buildAttachment(message.attachmentUrl!, message.contentType),
            if (message.content != null && message.content!.isNotEmpty)
              Text(
                message.content!,
                style: TextStyle(
                  color: isCurrentUser ? Colors.white : Colors.black87,
                ),
              ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _formatTime(message.sentAt),
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        isCurrentUser
                            ? Colors.white.withAlpha(179)
                            : Colors.black54,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachment(String url, String? contentType) {
    return EnhancedFileViewer(fileUrl: url, contentType: contentType);
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Yesterday ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
