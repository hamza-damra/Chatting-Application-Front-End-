class ChatRoom {
  final int id;
  final String? name;
  final String? description;
  final bool isPrivate;
  final int? lastMessageId;
  final DateTime? lastActivity;
  final int unreadCount;
  final List<int> participantIds;

  ChatRoom({
    required this.id,
    this.name,
    this.description,
    required this.isPrivate,
    this.lastMessageId,
    this.lastActivity,
    this.unreadCount = 0,
    required this.participantIds,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] as int,
      name: json['name'] as String?,
      description: json['description'] as String?,
      isPrivate: json['isPrivate'] as bool? ?? false,
      lastMessageId: json['lastMessageId'] as int?,
      lastActivity:
          json['lastActivity'] != null
              ? DateTime.parse(json['lastActivity'] as String)
              : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      participantIds:
          (json['participantIds'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isPrivate': isPrivate,
      'lastMessageId': lastMessageId,
      'lastActivity': lastActivity?.toIso8601String(),
      'unreadCount': unreadCount,
      'participantIds': participantIds,
    };
  }

  // Helper method to get display name for private chats
  String getDisplayName(
    int currentUserId,
    String Function(int userId)? getUserName,
  ) {
    if (!isPrivate) {
      // For group chats, return the room name
      return name ?? 'Group Chat';
    } else {
      // For private chats, show the other participant's name
      if (getUserName != null && participantIds.length >= 2) {
        final otherUserId = participantIds.firstWhere(
          (id) => id != currentUserId,
          orElse: () => participantIds.first,
        );
        return getUserName(otherUserId);
      }
      // Fallback to room name or default
      return name ?? 'Private Chat';
    }
  }
}
