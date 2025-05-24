import 'package:equatable/equatable.dart';
import '../../../domain/models/message_model.dart';

abstract class MessageState extends Equatable {
  const MessageState();

  @override
  List<Object?> get props => [];
}

// Initial state
class MessageInitial extends MessageState {}

// Loading messages
class MessagesLoading extends MessageState {}

// Messages loaded successfully
class MessagesLoaded extends MessageState {
  final List<MessageModel> messages;
  final String chatRoomId;
  final int currentPage;
  final bool hasReachedMax;

  const MessagesLoaded({
    required this.messages,
    required this.chatRoomId,
    required this.currentPage,
    this.hasReachedMax = false,
  });

  MessagesLoaded copyWith({
    List<MessageModel>? messages,
    String? chatRoomId,
    int? currentPage,
    bool? hasReachedMax,
  }) {
    return MessagesLoaded(
      messages: messages ?? this.messages,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object?> get props => [messages, chatRoomId, currentPage, hasReachedMax];
}

// Message sending in progress
class MessageSending extends MessageState {
  final String tempId;
  final String content;
  final String chatRoomId;

  const MessageSending({
    required this.tempId,
    required this.content,
    required this.chatRoomId,
  });

  @override
  List<Object?> get props => [tempId, content, chatRoomId];
}

// Message sent successfully
class MessageSent extends MessageState {
  final MessageModel message;

  const MessageSent({required this.message});

  @override
  List<Object?> get props => [message];
}

// Message operation failed
class MessageFailure extends MessageState {
  final String error;

  const MessageFailure(this.error);

  @override
  List<Object?> get props => [error];
}

// Typing indicator state
class TypingIndicatorState extends MessageState {
  final String chatRoomId;
  final String userId;
  final String userName;
  final bool isTyping;

  const TypingIndicatorState({
    required this.chatRoomId,
    required this.userId,
    required this.userName,
    required this.isTyping,
  });

  @override
  List<Object?> get props => [chatRoomId, userId, userName, isTyping];
}
