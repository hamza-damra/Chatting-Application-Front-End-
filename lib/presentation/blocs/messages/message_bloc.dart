import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/message_repository.dart';
import '../../../domain/models/message_model.dart';
import '../../../utils/logger.dart';
import 'message_event.dart';
import 'message_state.dart';

class MessageBloc extends Bloc<MessageEvent, MessageState> {
  final MessageRepository _messageRepository;
  late StreamSubscription<MessageModel> _messageSubscription;
  late StreamSubscription<dynamic> _statusSubscription;

  MessageBloc(this._messageRepository) : super(MessageInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
    on<MarkMessageAsRead>(_onMarkMessageAsRead);
    on<MarkAllMessagesAsRead>(_onMarkAllMessagesAsRead);
    on<DeleteMessage>(_onDeleteMessage);
    on<SendTypingIndicator>(_onSendTypingIndicator);
    on<MessageReceived>(_onMessageReceived);
    on<MessageStatusUpdated>(_onMessageStatusUpdated);
    on<TypingIndicatorReceived>(_onTypingIndicatorReceived);

    // Subscribe to message stream
    _messageSubscription = _messageRepository.getMessageStream().listen((
      message,
    ) {
      add(MessageReceived(message: message));
    });

    // Subscribe to status stream
    _statusSubscription = _messageRepository.getMessageStatusStream().listen((
      status,
    ) {
      add(
        MessageStatusUpdated(
          messageId: status.message.id,
          status: status.status,
        ),
      );
    });

    // Subscribe to typing indicators
    _messageRepository.getMessageStream().listen((message) {
      // Handle typing indicators
      if (message.type == MessageContentType.text &&
          message.content.startsWith('TYPING:')) {
        final parts = message.content.split(':');
        if (parts.length >= 3) {
          final isTyping = parts[1] == 'true';
          final userName = parts[2];
          add(
            TypingIndicatorReceived(
              chatRoomId: message.chatRoom.id,
              userId: message.sender.id.toString(),
              userName: userName,
              isTyping: isTyping,
            ),
          );
        }
      }
    });
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<MessageState> emit,
  ) async {
    try {
      // If it's the first page, show loading state
      if (event.page == 0) {
        emit(MessagesLoading());
      }

      // Get current state if it's a pagination request
      final currentState = state;
      List<MessageModel> oldMessages = [];
      bool hasReachedMax = false;

      if (currentState is MessagesLoaded && event.page > 0) {
        oldMessages = currentState.messages;
      }

      final messages = await _messageRepository.getChatRoomMessages(
        event.chatRoomId,
        page: event.page,
        size: event.size,
      );

      // If we got fewer messages than requested, we've reached the end
      if (messages.length < event.size) {
        hasReachedMax = true;
      }

      // Combine old and new messages, removing duplicates
      final allMessages = [...oldMessages];
      for (final message in messages) {
        if (!allMessages.any((m) => m.id == message.id)) {
          allMessages.add(message);
        }
      }

      // Sort messages by timestamp, oldest first
      allMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));

      emit(
        MessagesLoaded(
          messages: allMessages,
          chatRoomId: event.chatRoomId,
          currentPage: event.page,
          hasReachedMax: hasReachedMax,
        ),
      );
    } catch (e) {
      AppLogger.e('MessageBloc', 'Error loading messages: $e');
      emit(MessageFailure(e.toString()));
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<MessageState> emit,
  ) async {
    try {
      // Generate a temporary ID for the message
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();

      // Emit sending state
      emit(
        MessageSending(
          tempId: tempId,
          content: event.content,
          chatRoomId: event.chatRoomId,
        ),
      );

      // Send the message
      final message = await _messageRepository.sendMessage(
        event.chatRoomId,
        event.content,
        event.contentType,
      );

      // Emit sent state
      emit(MessageSent(message: message));

      // Update the messages list
      if (state is MessagesLoaded) {
        final currentState = state as MessagesLoaded;
        final updatedMessages = [...currentState.messages, message];

        // Sort messages by timestamp, oldest first
        updatedMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));

        emit(currentState.copyWith(messages: updatedMessages));
      }
    } catch (e) {
      AppLogger.e('MessageBloc', 'Error sending message: $e');
      emit(MessageFailure(e.toString()));
    }
  }

  Future<void> _onMarkMessageAsRead(
    MarkMessageAsRead event,
    Emitter<MessageState> emit,
  ) async {
    try {
      await _messageRepository.markMessageAsRead(event.messageId);

      // Update the message status in the state
      if (state is MessagesLoaded) {
        final currentState = state as MessagesLoaded;
        final updatedMessages =
            currentState.messages.map((message) {
              if (message.id == event.messageId) {
                return message.copyWith(status: MessageStatus.read);
              }
              return message;
            }).toList();

        emit(currentState.copyWith(messages: updatedMessages));
      }
    } catch (e) {
      AppLogger.e('MessageBloc', 'Error marking message as read: $e');
      // Don't emit failure for read status updates
    }
  }

  Future<void> _onMarkAllMessagesAsRead(
    MarkAllMessagesAsRead event,
    Emitter<MessageState> emit,
  ) async {
    try {
      await _messageRepository.markAllMessagesAsRead(event.chatRoomId);

      // Update all message statuses in the state
      if (state is MessagesLoaded) {
        final currentState = state as MessagesLoaded;
        final updatedMessages =
            currentState.messages.map((message) {
              return message.copyWith(status: MessageStatus.read);
            }).toList();

        emit(currentState.copyWith(messages: updatedMessages));
      }
    } catch (e) {
      AppLogger.e('MessageBloc', 'Error marking all messages as read: $e');
      // Don't emit failure for read status updates
    }
  }

  Future<void> _onDeleteMessage(
    DeleteMessage event,
    Emitter<MessageState> emit,
  ) async {
    try {
      await _messageRepository.deleteMessage(event.messageId);

      // Remove the message from the state
      if (state is MessagesLoaded) {
        final currentState = state as MessagesLoaded;
        final updatedMessages =
            currentState.messages
                .where((message) => message.id != event.messageId)
                .toList();

        emit(currentState.copyWith(messages: updatedMessages));
      }
    } catch (e) {
      AppLogger.e('MessageBloc', 'Error deleting message: $e');
      emit(MessageFailure(e.toString()));
    }
  }

  Future<void> _onSendTypingIndicator(
    SendTypingIndicator event,
    Emitter<MessageState> emit,
  ) async {
    try {
      await _messageRepository.sendTypingIndicator(
        event.chatRoomId,
        event.isTyping,
      );
    } catch (e) {
      AppLogger.e('MessageBloc', 'Error sending typing indicator: $e');
      // Don't emit failure for typing indicators
    }
  }

  void _onMessageReceived(MessageReceived event, Emitter<MessageState> emit) {
    if (state is MessagesLoaded) {
      final currentState = state as MessagesLoaded;

      // Only add the message if it's for the current chat room
      if (event.message.chatRoom.id == currentState.chatRoomId) {
        // Check if the message already exists
        if (!currentState.messages.any((m) => m.id == event.message.id)) {
          final updatedMessages = [...currentState.messages, event.message];

          // Sort messages by timestamp, oldest first
          updatedMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));

          emit(currentState.copyWith(messages: updatedMessages));
        }
      }
    }
  }

  void _onMessageStatusUpdated(
    MessageStatusUpdated event,
    Emitter<MessageState> emit,
  ) {
    if (state is MessagesLoaded) {
      final currentState = state as MessagesLoaded;
      final updatedMessages =
          currentState.messages.map((message) {
            if (message.id == event.messageId) {
              return message.copyWith(status: event.status);
            }
            return message;
          }).toList();

      emit(currentState.copyWith(messages: updatedMessages));
    }
  }

  void _onTypingIndicatorReceived(
    TypingIndicatorReceived event,
    Emitter<MessageState> emit,
  ) {
    emit(
      TypingIndicatorState(
        chatRoomId: event.chatRoomId,
        userId: event.userId,
        userName: event.userName,
        isTyping: event.isTyping,
      ),
    );
  }

  @override
  Future<void> close() {
    _messageSubscription.cancel();
    _statusSubscription.cancel();
    return super.close();
  }
}
