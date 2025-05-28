import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../presentation/blocs/messages/message_bloc.dart';
import '../../../presentation/blocs/messages/message_event.dart';
import '../../../presentation/blocs/messages/message_state.dart';
import '../../../domain/models/message_model.dart';
import '../../../core/constants/app_theme.dart';
import '../../../widgets/scroll_to_bottom_button.dart';
import 'typing_indicator.dart';
import 'message_bubble.dart';

class ChatMessagesWidget extends StatefulWidget {
  final String chatRoomId;
  final String currentUserId;

  const ChatMessagesWidget({
    super.key,
    required this.chatRoomId,
    required this.currentUserId,
  });

  @override
  State<ChatMessagesWidget> createState() => _ChatMessagesWidgetState();
}

class _ChatMessagesWidgetState extends State<ChatMessagesWidget> {
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  String _typingUserId = '';
  String _typingUserName = '';

  // Scroll position tracking for "move to new messages" button
  bool _showScrollToBottomButton = false;
  bool _isNearBottom = true;
  static const double _bottomThreshold = 100.0;

  @override
  void initState() {
    super.initState();

    // Load messages when widget initializes
    context.read<MessageBloc>().add(
      LoadMessages(chatRoomId: widget.chatRoomId),
    );

    // Set up scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      final state = context.read<MessageBloc>().state;
      if (state is MessagesLoaded && !state.hasReachedMax) {
        context.read<MessageBloc>().add(
          LoadMessages(
            chatRoomId: widget.chatRoomId,
            page: state.currentPage + 1,
          ),
        );
      }
    }

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

  void _markAsRead(String messageId) {
    context.read<MessageBloc>().add(MarkMessageAsRead(messageId: messageId));
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MessageBloc, MessageState>(
      listener: (context, state) {
        // Listen for typing indicators
        if (state is TypingIndicatorState) {
          if (state.chatRoomId == widget.chatRoomId &&
              state.userId != widget.currentUserId) {
            setState(() {
              _isTyping = state.isTyping;
              _typingUserId = state.userId;
              _typingUserName = state.userName;
            });
          }
        }

        // Listen for new messages and show scroll button if not near bottom
        if (state is MessagesLoaded && state.messages.isNotEmpty) {
          // If user is not near bottom when new messages arrive, show the button
          if (!_isNearBottom && !_showScrollToBottomButton) {
            setState(() {
              _showScrollToBottomButton = true;
            });
          }
        }
      },
      builder: (context, state) {
        if (state is MessagesLoaded) {
          if (state.messages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start the conversation',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          // Mark messages as read
          for (final message in state.messages) {
            if (message.sender.id.toString() != widget.currentUserId &&
                message.status != MessageStatus.read) {
              _markAsRead(message.id);
            }
          }

          return Stack(
            children: [
              ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount:
                    state.messages.length + (state.hasReachedMax ? 0 : 1),
                itemBuilder: (context, index) {
                  if (index >= state.messages.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final message = state.messages[index];
                  final isMe =
                      message.sender.id.toString() == widget.currentUserId;

                  return MessageBubble(message: message, isMe: isMe);
                },
              ),

              // Scroll to bottom button
              if (_showScrollToBottomButton)
                Positioned(
                  bottom:
                      _isTyping
                          ? 80
                          : 16, // Adjust position if typing indicator is shown
                  right: 16,
                  child: ScrollToBottomButton(
                    onPressed: _onScrollToBottomPressed,
                    hasUnreadMessages: true,
                  ),
                ),

              // Typing indicator
              if (_isTyping)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: TypingIndicator(
                    userName: _typingUserName,
                    userId: _typingUserId,
                  ),
                ),
            ],
          );
        } else if (state is MessageFailure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: AppTheme.errorColor),
                const SizedBox(height: 16),
                Text(
                  'Failed to load messages',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  state.error,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    context.read<MessageBloc>().add(
                      LoadMessages(chatRoomId: widget.chatRoomId),
                    );
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
