import 'package:equatable/equatable.dart';
import '../../../domain/models/message_model.dart';

abstract class MessageEvent extends Equatable {
  const MessageEvent();

  @override
  List<Object?> get props => [];
}

// Load messages for a chat room
class LoadMessages extends MessageEvent {
  final String chatRoomId;
  final int page;
  final int size;

  const LoadMessages({required this.chatRoomId, this.page = 0, this.size = 20});

  @override
  List<Object?> get props => [chatRoomId, page, size];
}

// Send a new message
class SendMessage extends MessageEvent {
  final String chatRoomId;
  final String content;
  final MessageContentType contentType;

  const SendMessage({
    required this.chatRoomId,
    required this.content,
    required this.contentType,
  });

  @override
  List<Object?> get props => [chatRoomId, content, contentType];
}

// Mark a message as read
class MarkMessageAsRead extends MessageEvent {
  final String messageId;

  const MarkMessageAsRead({required this.messageId});

  @override
  List<Object?> get props => [messageId];
}

// Mark all messages in a chat room as read
class MarkAllMessagesAsRead extends MessageEvent {
  final String chatRoomId;

  const MarkAllMessagesAsRead({required this.chatRoomId});

  @override
  List<Object?> get props => [chatRoomId];
}

// Delete a message
class DeleteMessage extends MessageEvent {
  final String messageId;

  const DeleteMessage({required this.messageId});

  @override
  List<Object?> get props => [messageId];
}

// Send typing indicator
class SendTypingIndicator extends MessageEvent {
  final String chatRoomId;
  final bool isTyping;

  const SendTypingIndicator({required this.chatRoomId, required this.isTyping});

  @override
  List<Object?> get props => [chatRoomId, isTyping];
}

// New message received
class MessageReceived extends MessageEvent {
  final MessageModel message;

  const MessageReceived({required this.message});

  @override
  List<Object?> get props => [message];
}

// Message status updated
class MessageStatusUpdated extends MessageEvent {
  final String messageId;
  final MessageStatus status;

  const MessageStatusUpdated({required this.messageId, required this.status});

  @override
  List<Object?> get props => [messageId, status];
}

// Typing indicator received
class TypingIndicatorReceived extends MessageEvent {
  final String chatRoomId;
  final String userId;
  final String userName;
  final bool isTyping;

  const TypingIndicatorReceived({
    required this.chatRoomId,
    required this.userId,
    required this.userName,
    required this.isTyping,
  });

  @override
  List<Object?> get props => [chatRoomId, userId, userName, isTyping];
}
