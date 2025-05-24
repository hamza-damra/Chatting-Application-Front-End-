import 'package:equatable/equatable.dart';
import 'user_model.dart';

enum ChatRoomType {
  private,
  group
}

class ChatRoomModel extends Equatable {
  final String id;
  final String name;
  final ChatRoomType type;
  final List<UserModel> participants;
  final UserModel? createdBy;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatRoomModel({
    required this.id,
    required this.name,
    required this.type,
    required this.participants,
    this.createdBy,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  ChatRoomModel copyWith({
    String? id,
    String? name,
    ChatRoomType? type,
    List<UserModel>? participants,
    UserModel? createdBy,
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
      createdBy: createdBy ?? this.createdBy,
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
      'type': type == ChatRoomType.group ? 'GROUP' : 'PRIVATE',
      'participants': participants.map((p) => p.toMap()).toList(),
      'createdBy': createdBy?.toMap(),
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'unreadCount': unreadCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ChatRoomModel.fromMap(Map<String, dynamic> map) {
    return ChatRoomModel(
      id: map['id'].toString(),
      name: map['name'],
      type: map['type'] == 'GROUP' ? ChatRoomType.group : ChatRoomType.private,
      participants: (map['participants'] as List?)
          ?.map((p) => UserModel.fromMap(p is Map<String, dynamic> ? p : p['user'] ?? p))
          .toList() ?? [],
      createdBy: map['createdBy'] != null ? UserModel.fromMap(map['createdBy']) : null,
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] != null 
          ? DateTime.parse(map['lastMessageTime']) 
          : null,
      unreadCount: map['unreadCount'] ?? 0,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : DateTime.now(),
    );
  }

  // Alias methods for backward compatibility
  Map<String, dynamic> toJson() => toMap();
  factory ChatRoomModel.fromJson(Map<String, dynamic> json) => ChatRoomModel.fromMap(json);

  // Helper methods for UI
  String getDisplayName(String currentUserId) {
    if (type == ChatRoomType.group) {
      return name;
    } else {
      // For private chats, show the other participant's name
      final otherUser = participants.firstWhere(
        (user) => user.id.toString() != currentUserId,
        orElse: () => participants.first,
      );
      return otherUser.fullName;
    }
  }

  String getAvatarUrl(String currentUserId) {
    if (type == ChatRoomType.group) {
      // Return group avatar or empty string
      return '';
    } else {
      // For private chats, show the other participant's avatar
      final otherUser = participants.firstWhere(
        (user) => user.id.toString() != currentUserId,
        orElse: () => participants.first,
      );
      return otherUser.profilePicture ?? '';
    }
  }

  bool isUserOnline(String currentUserId) {
    if (type == ChatRoomType.private) {
      final otherUser = participants.firstWhere(
        (user) => user.id.toString() != currentUserId,
        orElse: () => participants.first,
      );
      return otherUser.isOnline;
    }
    return false;
  }

  @override
  List<Object?> get props => [
    id, 
    name, 
    type, 
    participants, 
    createdBy, 
    lastMessage, 
    lastMessageTime, 
    unreadCount, 
    createdAt, 
    updatedAt
  ];
}
