import 'package:equatable/equatable.dart';
import 'user_model.dart';
import 'chat_room_model.dart';

enum MessageStatus { sending, sent, delivered, read, failed }

enum MessageContentType { text, image, file, audio, video, location }

class MessageModel extends Equatable {
  final String id;
  final UserModel sender;
  final ChatRoomModel chatRoom;
  final String content;
  final MessageContentType type;
  final MessageStatus status;
  final Map<String, dynamic>? metadata;
  final DateTime sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;

  const MessageModel({
    required this.id,
    required this.sender,
    required this.chatRoom,
    required this.content,
    required this.type,
    required this.status,
    this.metadata,
    required this.sentAt,
    this.deliveredAt,
    this.readAt,
  });

  MessageModel copyWith({
    String? id,
    UserModel? sender,
    ChatRoomModel? chatRoom,
    String? content,
    MessageContentType? type,
    MessageStatus? status,
    Map<String, dynamic>? metadata,
    DateTime? sentAt,
    DateTime? deliveredAt,
    DateTime? readAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      chatRoom: chatRoom ?? this.chatRoom,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender.toMap(),
      'chatRoom': chatRoom.toMap(),
      'content': content,
      'contentType': type.toString().split('.').last.toUpperCase(),
      'status': status.toString().split('.').last.toUpperCase(),
      'metadata': metadata,
      'sentAt': sentAt.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'].toString(),
      sender: UserModel.fromMap(map['sender']),
      chatRoom: ChatRoomModel.fromMap(map['chatRoom']),
      content: map['content'],
      type: parseMessageType(map['contentType']),
      status: _parseMessageStatus(map['status']),
      metadata: map['metadata'],
      sentAt:
          map['sentAt'] != null
              ? DateTime.parse(map['sentAt'])
              : DateTime.now(),
      deliveredAt:
          map['deliveredAt'] != null
              ? DateTime.parse(map['deliveredAt'])
              : null,
      readAt: map['readAt'] != null ? DateTime.parse(map['readAt']) : null,
    );
  }

  // Alias methods for backward compatibility
  Map<String, dynamic> toJson() => toMap();
  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      MessageModel.fromMap(json);

  // Make this method public for testing
  static MessageContentType parseMessageType(String? type) {
    if (type == null) return MessageContentType.text;

    final typeUpper = type.toUpperCase();

    // Handle exact matches first
    switch (typeUpper) {
      case 'TEXT':
        return MessageContentType.text;
      case 'IMAGE':
        return MessageContentType.image;
      case 'FILE':
        return MessageContentType.file;
      case 'AUDIO':
        return MessageContentType.audio;
      case 'VIDEO':
        return MessageContentType.video;
      case 'LOCATION':
        return MessageContentType.location;
    }

    // Handle MIME types
    if (typeUpper.startsWith('IMAGE/')) {
      return MessageContentType.image;
    } else if (typeUpper.startsWith('VIDEO/')) {
      return MessageContentType.video;
    } else if (typeUpper.startsWith('AUDIO/')) {
      return MessageContentType.audio;
    } else if (typeUpper.startsWith('APPLICATION/') ||
        typeUpper.startsWith('TEXT/') ||
        typeUpper.contains('DOCUMENT') ||
        typeUpper.contains('PDF')) {
      return MessageContentType.file;
    }

    // Default fallback
    return MessageContentType.text;
  }

  static MessageStatus _parseMessageStatus(String? status) {
    if (status == null) return MessageStatus.sent;

    switch (status.toUpperCase()) {
      case 'SENDING':
        return MessageStatus.sending;
      case 'SENT':
        return MessageStatus.sent;
      case 'DELIVERED':
        return MessageStatus.delivered;
      case 'READ':
        return MessageStatus.read;
      case 'FAILED':
        return MessageStatus.failed;
      default:
        return MessageStatus.sent;
    }
  }

  @override
  List<Object?> get props => [
    id,
    sender,
    chatRoom,
    content,
    type,
    status,
    metadata,
    sentAt,
    deliveredAt,
    readAt,
  ];
}
