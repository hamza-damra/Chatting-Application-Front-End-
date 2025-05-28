import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import 'animated_message_bubble.dart';
import 'scroll_to_bottom_button.dart';

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

  // Scroll position tracking for "move to new messages" button
  bool _showScrollToBottomButton = false;
  bool _isNearBottom = true;
  static const double _bottomThreshold = 100.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ChatWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if new messages were added
    if (widget.messages.length > oldWidget.messages.length) {
      // If user is not near bottom when new messages arrive, show the button
      if (!_isNearBottom && !_showScrollToBottomButton) {
        setState(() {
          _showScrollToBottomButton = true;
        });
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    // Track scroll position for "move to new messages" button
    // In a reversed ListView, position 0 is the bottom (newest messages)
    final position = _scrollController.position;
    final wasNearBottom = _isNearBottom;
    _isNearBottom = position.pixels <= _bottomThreshold;

    // Show/hide scroll to bottom button based on scroll position
    final shouldShowButton = !_isNearBottom;
    if (_showScrollToBottomButton != shouldShowButton) {
      setState(() {
        _showScrollToBottomButton = shouldShowButton;
      });
    }

    // If we just scrolled to the bottom, hide the button
    if (_isNearBottom && !wasNearBottom && _showScrollToBottomButton) {
      setState(() {
        _showScrollToBottomButton = false;
      });
    }
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

  /// Scroll to bottom of the chat
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      try {
        _scrollController.animateTo(
          0.0, // In a reversed ListView, 0 is the bottom
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
        );
      } catch (e) {
        // If there's an error, try again with a delay
        Future.delayed(const Duration(milliseconds: 200), () {
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

  /// Handle scroll-to-bottom button press
  void _onScrollToBottomPressed() {
    _scrollToBottom();
    // Hide the button immediately when pressed
    setState(() {
      _showScrollToBottomButton = false;
    });
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

        // Scroll to bottom button
        if (_showScrollToBottomButton &&
            !widget.isAttachmentUploading &&
            !isLoading)
          Positioned(
            bottom:
                _keyboardVisible
                    ? MediaQuery.of(context).viewInsets.bottom + 16
                    : 16,
            right: 16,
            child: ScrollToBottomButton(
              onPressed: _onScrollToBottomPressed,
              hasUnreadMessages: true,
            ),
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
