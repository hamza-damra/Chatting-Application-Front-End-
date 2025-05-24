import 'package:equatable/equatable.dart';
import 'message_model.dart';

class MessageStatusModel extends Equatable {
  final MessageModel message;
  final MessageStatus status;
  final DateTime timestamp;

  const MessageStatusModel({
    required this.message,
    required this.status,
    required this.timestamp,
  });

  MessageStatusModel copyWith({
    MessageModel? message,
    MessageStatus? status,
    DateTime? timestamp,
  }) {
    return MessageStatusModel(
      message: message ?? this.message,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message': message.toMap(),
      'status': status.toString().split('.').last.toUpperCase(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory MessageStatusModel.fromMap(Map<String, dynamic> map) {
    return MessageStatusModel(
      message: MessageModel.fromMap(map['message']),
      status: _parseMessageStatus(map['status']),
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp']) 
          : DateTime.now(),
    );
  }

  // Alias methods for backward compatibility
  Map<String, dynamic> toJson() => toMap();
  factory MessageStatusModel.fromJson(Map<String, dynamic> json) => MessageStatusModel.fromMap(json);

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
  List<Object?> get props => [message, status, timestamp];
}
