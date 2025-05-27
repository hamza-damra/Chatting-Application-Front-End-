class Message {
  final int? id;
  final int? roomId;
  final int senderId;
  final String? senderName;
  final String? content;
  final String? attachmentUrl;
  final String? downloadUrl;
  final String? contentType;
  final DateTime? sentAt;
  final bool isRead;

  Message({
    this.id,
    this.roomId,
    required this.senderId,
    this.senderName,
    this.content,
    this.attachmentUrl,
    this.downloadUrl,
    this.contentType,
    this.sentAt,
    this.isRead = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    // Handle different backend response formats
    int? senderId;
    String? senderName;
    int? roomId;

    // Extract sender information
    if (json['sender'] != null && json['sender'] is Map<String, dynamic>) {
      final senderData = json['sender'] as Map<String, dynamic>;
      senderId = senderData['id'] as int?;
      senderName =
          senderData['fullName'] as String? ??
          senderData['username'] as String? ??
          'Unknown User';
    } else if (json['senderId'] != null) {
      senderId = json['senderId'] as int?;
      senderName = json['senderName'] as String?;
    }

    // Extract room ID
    roomId = json['chatRoomId'] as int? ?? json['roomId'] as int?;

    return Message(
      id: json['id'] as int?,
      roomId: roomId,
      senderId: senderId ?? 0,
      senderName: senderName,
      content: json['content'] as String?,
      attachmentUrl: json['attachmentUrl'] as String?,
      downloadUrl: json['downloadUrl'] as String?,
      contentType: json['contentType'] as String?,
      sentAt:
          json['sentAt'] != null
              ? DateTime.parse(json['sentAt'] as String)
              : null,
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'attachmentUrl': attachmentUrl,
      'downloadUrl': downloadUrl,
      'contentType': contentType,
      'sentAt': sentAt?.toIso8601String(),
      'isRead': isRead,
    };
  }
}
