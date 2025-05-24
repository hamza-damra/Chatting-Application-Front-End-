import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../presentation/blocs/messages/message_bloc.dart';
import '../../../presentation/blocs/messages/message_event.dart';
import '../../../presentation/blocs/messages/message_state.dart';
import '../../../domain/models/message_model.dart';
import '../../../core/constants/app_theme.dart';
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
  }

  void _markAsRead(String messageId) {
    context.read<MessageBloc>().add(MarkMessageAsRead(messageId: messageId));
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
