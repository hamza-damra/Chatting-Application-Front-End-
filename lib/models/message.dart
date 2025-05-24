class Message {
  final int? id;
  final int? roomId;
  final int senderId;
  final String? senderName;
  final String? content;
  final String? attachmentUrl;
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
    this.contentType,
    this.sentAt,
    this.isRead = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as int?,
      roomId: json['roomId'] as int?,
      senderId: json['senderId'] as int,
      senderName: json['senderName'] as String?,
      content: json['content'] as String?,
      attachmentUrl: json['attachmentUrl'] as String?,
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
      'contentType': contentType,
      'sentAt': sentAt?.toIso8601String(),
      'isRead': isRead,
    };
  }
}
