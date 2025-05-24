import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import 'animated_message_bubble.dart';

class ChatWidget extends StatefulWidget {
  final List<types.Message> messages;
  final types.User user;
  final void Function(types.PartialText) onSendPressed;
  final VoidCallback onAttachmentPressed;
  final bool isAttachmentUploading;
  final types.RoomType roomType;

  const ChatWidget({
    super.key,
    required this.messages,
    required this.user,
    required this.onSendPressed,
    required this.onAttachmentPressed,
    required this.isAttachmentUploading,
    required this.roomType,
  });

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  bool _keyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = View.of(context).viewInsets.bottom;
    final newKeyboardVisible = bottomInset > 0.0;
    if (newKeyboardVisible != _keyboardVisible) {
      setState(() {
        _keyboardVisible = newKeyboardVisible;
      });
      if (_keyboardVisible) {
        Future.delayed(const Duration(milliseconds: 300), () {
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
  }

  Widget _buildMessage(types.Message message) {
    final isCurrentUser = message.author.id == widget.user.id;

    BoxDecoration decoration = BoxDecoration(
      color: isCurrentUser ? Colors.blueAccent : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );

    Widget messageContent;

    if (message is types.TextMessage) {
      messageContent = Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(
          message.text,
          style: TextStyle(
            color: isCurrentUser ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
      );
    } else if (message is types.ImageMessage) {
      messageContent = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          message.uri,
          width: 240,
          height: 180,
          fit: BoxFit.cover,
        ),
      );
    } else {
      messageContent = const SizedBox.shrink();
    }

    return AnimatedMessageBubble(
      isNewMessage: true,
      isCurrentUser: isCurrentUser,
      decoration: decoration,
      child: messageContent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final isLoading = chatProvider.isLoading;

    final sortedMessages = List<types.Message>.from(widget.messages);

    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: EdgeInsets.only(
            bottom:
                _keyboardVisible
                    ? MediaQuery.of(context).viewInsets.bottom
                    : 16,
            top: 16,
          ),
          itemCount: sortedMessages.length,
          itemBuilder: (context, index) {
            final message = sortedMessages[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: _buildMessage(message),
            );
          },
        ),
        if (widget.isAttachmentUploading)
          Container(
            color: Colors.black.withAlpha(76),
            child: const Center(child: CircularProgressIndicator()),
          ),
        if (isLoading)
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
