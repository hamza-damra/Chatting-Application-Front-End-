class UnreadMessageNotification {
  final int messageId;
  final int chatRoomId;
  final String chatRoomName;
  final int senderId;
  final String senderUsername;
  final String? senderFullName;
  final String? contentPreview;
  final String contentType;
  final DateTime sentAt;
  final DateTime notificationTimestamp;
  final int unreadCount;
  final int totalUnreadCount;
  final int recipientUserId;
  final bool isPrivateChat;
  final int participantCount;
  final String? attachmentUrl;
  final NotificationType notificationType;

  UnreadMessageNotification({
    required this.messageId,
    required this.chatRoomId,
    required this.chatRoomName,
    required this.senderId,
    required this.senderUsername,
    this.senderFullName,
    this.contentPreview,
    required this.contentType,
    required this.sentAt,
    required this.notificationTimestamp,
    required this.unreadCount,
    required this.totalUnreadCount,
    required this.recipientUserId,
    required this.isPrivateChat,
    required this.participantCount,
    this.attachmentUrl,
    required this.notificationType,
  });

  factory UnreadMessageNotification.fromJson(Map<String, dynamic> json) {
    return UnreadMessageNotification(
      messageId: json['messageId'] as int,
      chatRoomId: json['chatRoomId'] as int,
      chatRoomName: json['chatRoomName'] as String,
      senderId: json['senderId'] as int,
      senderUsername: json['senderUsername'] as String,
      senderFullName: json['senderFullName'] as String?,
      contentPreview: json['contentPreview'] as String?,
      contentType: json['contentType'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
      notificationTimestamp: DateTime.parse(json['notificationTimestamp'] as String),
      unreadCount: json['unreadCount'] as int,
      totalUnreadCount: json['totalUnreadCount'] as int,
      recipientUserId: json['recipientUserId'] as int,
      isPrivateChat: json['isPrivateChat'] as bool,
      participantCount: json['participantCount'] as int,
      attachmentUrl: json['attachmentUrl'] as String?,
      notificationType: NotificationType.fromString(json['notificationType'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'chatRoomId': chatRoomId,
      'chatRoomName': chatRoomName,
      'senderId': senderId,
      'senderUsername': senderUsername,
      'senderFullName': senderFullName,
      'contentPreview': contentPreview,
      'contentType': contentType,
      'sentAt': sentAt.toIso8601String(),
      'notificationTimestamp': notificationTimestamp.toIso8601String(),
      'unreadCount': unreadCount,
      'totalUnreadCount': totalUnreadCount,
      'recipientUserId': recipientUserId,
      'isPrivateChat': isPrivateChat,
      'participantCount': participantCount,
      'attachmentUrl': attachmentUrl,
      'notificationType': notificationType.value,
    };
  }

  @override
  String toString() {
    return 'UnreadMessageNotification(messageId: $messageId, chatRoomName: $chatRoomName, senderUsername: $senderUsername, contentPreview: $contentPreview)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnreadMessageNotification &&
        other.messageId == messageId &&
        other.chatRoomId == chatRoomId;
  }

  @override
  int get hashCode => messageId.hashCode ^ chatRoomId.hashCode;
}

enum NotificationType {
  newMessage('NEW_MESSAGE'),
  mention('MENTION'),
  privateMessage('PRIVATE_MESSAGE'),
  groupMessage('GROUP_MESSAGE');

  const NotificationType(this.value);
  final String value;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.newMessage,
    );
  }

  String get displayName {
    switch (this) {
      case NotificationType.newMessage:
        return 'New Message';
      case NotificationType.mention:
        return 'Mention';
      case NotificationType.privateMessage:
        return 'Private Message';
      case NotificationType.groupMessage:
        return 'Group Message';
    }
  }
}
