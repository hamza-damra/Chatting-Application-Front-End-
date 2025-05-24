import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import '../models/message_model.dart';
import '../models/message_status_model.dart';
import '../models/user_model.dart';
import '../models/chat_room_model.dart';

/// Utility class to convert between our MessageModel and flutter_chat_types Message
class MessageConverter {
  /// Convert a MessageModel to a flutter_chat_types Message
  static types.Message toFlutterChatMessage(MessageModel message) {
    final author = types.User(
      id: message.sender.id.toString(),
      firstName: message.sender.fullName.split(' ').first,
      lastName:
          message.sender.fullName.split(' ').length > 1
              ? message.sender.fullName.split(' ').last
              : '',
      imageUrl: message.sender.profilePicture,
    );

    final createdAt = message.sentAt.millisecondsSinceEpoch;
    final status = _convertMessageStatus(message.status);

    // Convert based on message type
    if (message.type == MessageContentType.text) {
      return types.TextMessage(
        id: message.id,
        author: author,
        text: message.content,
        createdAt: createdAt,
        status: status,
        metadata: message.metadata,
      );
    } else if (message.type == MessageContentType.image) {
      return types.ImageMessage(
        id: message.id,
        author: author,
        uri: message.content,
        name: message.metadata?['name'] ?? 'Image',
        size: message.metadata?['size'] ?? 0,
        createdAt: createdAt,
        status: status,
        metadata: message.metadata,
      );
    } else if (message.type == MessageContentType.file) {
      return types.FileMessage(
        id: message.id,
        author: author,
        uri: message.content,
        name: message.metadata?['name'] ?? 'File',
        size: message.metadata?['size'] ?? 0,
        createdAt: createdAt,
        status: status,
        metadata: message.metadata,
      );
    } else if (message.type == MessageContentType.audio) {
      return types.CustomMessage(
        id: message.id,
        author: author,
        createdAt: createdAt,
        status: status,
        metadata: {
          'type': 'audio',
          'uri': message.content,
          ...?message.metadata,
        },
      );
    } else if (message.type == MessageContentType.video) {
      return types.CustomMessage(
        id: message.id,
        author: author,
        createdAt: createdAt,
        status: status,
        metadata: {
          'type': 'video',
          'uri': message.content,
          ...?message.metadata,
        },
      );
    } else if (message.type == MessageContentType.location) {
      return types.CustomMessage(
        id: message.id,
        author: author,
        createdAt: createdAt,
        status: status,
        metadata: {
          'type': 'location',
          'content': message.content,
          ...?message.metadata,
        },
      );
    } else {
      // Default fallback for any unhandled message type
      return types.TextMessage(
        id: message.id,
        author: author,
        text: message.content,
        createdAt: createdAt,
        status: status,
        metadata: message.metadata,
      );
    }
  }

  /// Convert a flutter_chat_types Message to our MessageModel
  static MessageModel fromFlutterChatMessage(
    types.Message message,
    UserModel sender,
    ChatRoomModel chatRoom,
  ) {
    final sentAt =
        message.createdAt != null
            ? DateTime.fromMillisecondsSinceEpoch(message.createdAt!)
            : DateTime.now();

    final status = _convertTypesStatus(message.status);

    if (message is types.TextMessage) {
      return MessageModel(
        id: message.id,
        sender: sender,
        chatRoom: chatRoom,
        content: message.text,
        type: MessageContentType.text,
        status: status,
        metadata: message.metadata,
        sentAt: sentAt,
      );
    } else if (message is types.ImageMessage) {
      return MessageModel(
        id: message.id,
        sender: sender,
        chatRoom: chatRoom,
        content: message.uri,
        type: MessageContentType.image,
        status: status,
        metadata: {
          'name': message.name,
          'size': message.size,
          ...?message.metadata,
        },
        sentAt: sentAt,
      );
    } else if (message is types.FileMessage) {
      return MessageModel(
        id: message.id,
        sender: sender,
        chatRoom: chatRoom,
        content: message.uri,
        type: MessageContentType.file,
        status: status,
        metadata: {
          'name': message.name,
          'size': message.size,
          ...?message.metadata,
        },
        sentAt: sentAt,
      );
    } else if (message is types.CustomMessage) {
      final type = message.metadata?['type'] as String?;

      if (type == 'audio') {
        return MessageModel(
          id: message.id,
          sender: sender,
          chatRoom: chatRoom,
          content: message.metadata?['uri'] ?? '',
          type: MessageContentType.audio,
          status: status,
          metadata: message.metadata,
          sentAt: sentAt,
        );
      } else if (type == 'video') {
        return MessageModel(
          id: message.id,
          sender: sender,
          chatRoom: chatRoom,
          content: message.metadata?['uri'] ?? '',
          type: MessageContentType.video,
          status: status,
          metadata: message.metadata,
          sentAt: sentAt,
        );
      } else if (type == 'location') {
        return MessageModel(
          id: message.id,
          sender: sender,
          chatRoom: chatRoom,
          content: message.metadata?['content'] ?? '',
          type: MessageContentType.location,
          status: status,
          metadata: message.metadata,
          sentAt: sentAt,
        );
      }
    }

    // Default fallback
    return MessageModel(
      id: message.id,
      sender: sender,
      chatRoom: chatRoom,
      content:
          message is types.TextMessage
              ? message.text
              : 'Unsupported message type',
      type: MessageContentType.text,
      status: status,
      metadata: message is types.TextMessage ? message.metadata : null,
      sentAt: sentAt,
    );
  }

  /// Convert MessageStatus to types.Status
  static types.Status _convertMessageStatus(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return types.Status.sending;
      case MessageStatus.sent:
        return types.Status.sent;
      case MessageStatus.delivered:
        return types.Status.delivered;
      case MessageStatus.read:
        return types.Status.seen;
      case MessageStatus.failed:
        return types.Status.error;
    }
  }

  /// Convert types.Status to MessageStatus
  static MessageStatus _convertTypesStatus(types.Status? status) {
    if (status == null) return MessageStatus.sent;

    switch (status) {
      case types.Status.sending:
        return MessageStatus.sending;
      case types.Status.sent:
        return MessageStatus.sent;
      case types.Status.delivered:
        return MessageStatus.delivered;
      case types.Status.seen:
        return MessageStatus.read;
      case types.Status.error:
        return MessageStatus.failed;
    }
  }

  /// Create a MessageStatusModel from a flutter_chat_types Message
  static MessageStatusModel createMessageStatus(
    types.Message message,
    UserModel sender,
    ChatRoomModel chatRoom,
    MessageStatus status,
  ) {
    final messageModel = fromFlutterChatMessage(message, sender, chatRoom);

    return MessageStatusModel(
      message: messageModel,
      status: status,
      timestamp: DateTime.now(),
    );
  }

  /// Update a MessageModel with a new status
  static MessageModel updateMessageStatus(
    MessageModel message,
    MessageStatus status,
  ) {
    return message.copyWith(status: status);
  }
}
