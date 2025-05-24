import '../models/message_model.dart';
import '../models/message_status_model.dart';
import 'dart:async';

abstract class MessageRepository {
  // Get messages for a chat room
  Future<List<MessageModel>> getChatRoomMessages(String chatRoomId, {int page = 0, int size = 20});
  
  // Send a message
  Future<MessageModel> sendMessage(String chatRoomId, String content, MessageContentType contentType);
  
  // Mark message as read
  Future<void> markMessageAsRead(String messageId);
  
  // Mark all messages in a chat room as read
  Future<void> markAllMessagesAsRead(String chatRoomId);
  
  // Delete a message
  Future<void> deleteMessage(String messageId);
  
  // Get stream of new messages
  Stream<MessageModel> getMessageStream();
  
  // Get stream of message status updates
  Stream<MessageStatusModel> getMessageStatusStream();
  
  // Send typing indicator
  Future<void> sendTypingIndicator(String chatRoomId, bool isTyping);
}
