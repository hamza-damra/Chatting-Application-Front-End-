import 'package:flutter/material.dart';
import '../models/chat_room.dart';
import '../models/message.dart';

class ChatProvider extends ChangeNotifier {
  final Map<int, List<Message>> _messages = {};
  final List<ChatRoom> _chatRooms = [];
  
  List<ChatRoom> get chatRooms => _chatRooms;
  
  // Get all chat rooms
  Future<List<ChatRoom>> getAllChatRooms() async {
    // In a real implementation, this would fetch from an API
    return _chatRooms;
  }
  
  // Get private chat rooms
  Future<List<ChatRoom>> getPrivateChatRooms() async {
    return _chatRooms.where((room) => room.isPrivate).toList();
  }
  
  // Get group chat rooms
  Future<List<ChatRoom>> getGroupChatRooms() async {
    return _chatRooms.where((room) => !room.isPrivate).toList();
  }
  
  // Get messages for a specific room
  Future<List<Message>> getMessagesForRoom({
    required int roomId,
    required int currentUserId,
  }) async {
    // In a real implementation, this would fetch from an API
    return _messages[roomId] ?? [];
  }
  
  // Send a message
  Future<Message> sendMessage({
    required int roomId,
    required int senderId,
    required String content,
    String? senderName,
  }) async {
    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch,
      roomId: roomId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      sentAt: DateTime.now(),
    );
    
    if (!_messages.containsKey(roomId)) {
      _messages[roomId] = [];
    }
    
    _messages[roomId]!.add(message);
    notifyListeners();
    
    return message;
  }
  
  // Send a file message
  Future<Message> sendFileMessage({
    required int roomId,
    required int senderId,
    required String attachmentUrl,
    required String contentType,
    String? senderName,
  }) async {
    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch,
      roomId: roomId,
      senderId: senderId,
      senderName: senderName,
      attachmentUrl: attachmentUrl,
      contentType: contentType,
      sentAt: DateTime.now(),
    );
    
    if (!_messages.containsKey(roomId)) {
      _messages[roomId] = [];
    }
    
    _messages[roomId]!.add(message);
    notifyListeners();
    
    return message;
  }
  
  // Mark messages as read
  Future<void> markMessagesAsRead({
    required int roomId,
    required int userId,
  }) async {
    if (_messages.containsKey(roomId)) {
      for (var i = 0; i < _messages[roomId]!.length; i++) {
        if (_messages[roomId]![i].senderId != userId && !_messages[roomId]![i].isRead) {
          final updatedMessage = Message(
            id: _messages[roomId]![i].id,
            roomId: _messages[roomId]![i].roomId,
            senderId: _messages[roomId]![i].senderId,
            senderName: _messages[roomId]![i].senderName,
            content: _messages[roomId]![i].content,
            attachmentUrl: _messages[roomId]![i].attachmentUrl,
            contentType: _messages[roomId]![i].contentType,
            sentAt: _messages[roomId]![i].sentAt,
            isRead: true,
          );
          
          _messages[roomId]![i] = updatedMessage;
        }
      }
      
      // Update unread count in chat room
      for (var i = 0; i < _chatRooms.length; i++) {
        if (_chatRooms[i].id == roomId) {
          final updatedRoom = ChatRoom(
            id: _chatRooms[i].id,
            name: _chatRooms[i].name,
            description: _chatRooms[i].description,
            isPrivate: _chatRooms[i].isPrivate,
            lastMessageId: _chatRooms[i].lastMessageId,
            lastActivity: _chatRooms[i].lastActivity,
            unreadCount: 0,
            participantIds: _chatRooms[i].participantIds,
          );
          
          _chatRooms[i] = updatedRoom;
          break;
        }
      }
      
      notifyListeners();
    }
  }
  
  // Get unread count for a specific room
  int getUnreadCount(int roomId) {
    for (final room in _chatRooms) {
      if (room.id == roomId) {
        return room.unreadCount;
      }
    }
    return 0;
  }
}
