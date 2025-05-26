import 'package:equatable/equatable.dart';
import 'user_model.dart';

enum ChatRoomType { private, group }

class ChatRoomModel extends Equatable {
  final String id;
  final String name;
  final ChatRoomType type;
  final List<UserModel> participants;
  final UserModel? creator;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ChatRoomModel({
    required this.id,
    required this.name,
    required this.type,
    required this.participants,
    this.creator,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  ChatRoomModel copyWith({
    String? id,
    String? name,
    ChatRoomType? type,
    List<UserModel>? participants,
    UserModel? creator,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatRoomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      creator: creator ?? this.creator,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'participants': participants.map((p) => p.toMap()).toList(),
      'creator': creator?.toMap(),
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'unreadCount': unreadCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ChatRoomModel.fromMap(Map<String, dynamic> map) {
    return ChatRoomModel(
      id: map['id'].toString(),
      name: map['name'],
      type: _parseChatRoomType(map['type']),
      participants: List<UserModel>.from(
        (map['participants'] as List).map((p) => UserModel.fromMap(p)),
      ),
      creator:
          map['creator'] != null ? UserModel.fromMap(map['creator']) : null,
      lastMessage: map['lastMessage'],
      lastMessageTime:
          map['lastMessageTime'] != null
              ? DateTime.parse(map['lastMessageTime'])
              : null,
      unreadCount: map['unreadCount'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  // Alias methods for backward compatibility
  Map<String, dynamic> toJson() => toMap();
  factory ChatRoomModel.fromJson(Map<String, dynamic> json) =>
      ChatRoomModel.fromMap(json);

  static ChatRoomType _parseChatRoomType(String? type) {
    if (type == null) return ChatRoomType.private;

    switch (type.toLowerCase()) {
      case 'group':
        return ChatRoomType.group;
      case 'private':
      default:
        return ChatRoomType.private;
    }
  }

  // Helper methods for UI display
  String getDisplayName(String currentUserId) {
    if (type == ChatRoomType.group) {
      return name;
    } else {
      // For private chats, show the other participant's name
      final otherParticipant = participants.firstWhere(
        (p) => p.id.toString() != currentUserId,
        orElse: () => participants.first,
      );
      return otherParticipant.fullName;
    }
  }

  String getAvatarUrl(String currentUserId) {
    if (type == ChatRoomType.group) {
      // Return a group avatar or empty string
      return '';
    } else {
      // For private chats, show the other participant's avatar
      final otherParticipant = participants.firstWhere(
        (p) => p.id.toString() != currentUserId,
        orElse: () => participants.first,
      );
      return otherParticipant.profilePicture ?? '';
    }
  }

  bool isUserOnline(String currentUserId) {
    if (type == ChatRoomType.group) {
      return false;
    } else {
      // For private chats, check if the other participant is online
      final otherParticipant = participants.firstWhere(
        (p) => p.id.toString() != currentUserId,
        orElse: () => participants.first,
      );
      return otherParticipant.isOnline;
    }
  }

  int? getOtherUserId(String currentUserId) {
    if (type == ChatRoomType.group) {
      return null; // No "other user" in group chats
    } else {
      // For private chats, get the other participant's ID
      final otherParticipant = participants.firstWhere(
        (p) => p.id.toString() != currentUserId,
        orElse: () => participants.first,
      );
      return otherParticipant.id;
    }
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    participants,
    creator,
    lastMessage,
    lastMessageTime,
    unreadCount,
    createdAt,
    updatedAt,
  ];
}
