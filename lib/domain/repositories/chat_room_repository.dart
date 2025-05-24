import '../models/chat_room_model.dart';
import '../models/user_model.dart';

abstract class ChatRoomRepository {
  // Get all chat rooms for current user
  Future<List<ChatRoomModel>> getUserChatRooms();
  
  // Get chat room by ID
  Future<ChatRoomModel> getChatRoomById(String id);
  
  // Create a new chat room (group)
  Future<ChatRoomModel> createChatRoom(String name, bool isPrivate, List<String> participantIds);
  
  // Create a private chat with another user
  Future<ChatRoomModel> createPrivateChat(String userId);
  
  // Update chat room
  Future<ChatRoomModel> updateChatRoom(String id, String name, bool isPrivate);
  
  // Delete chat room
  Future<void> deleteChatRoom(String id);
  
  // Get chat room participants
  Future<List<UserModel>> getChatRoomParticipants(String id);
  
  // Add participant to chat room
  Future<void> addParticipant(String chatRoomId, String userId);
  
  // Remove participant from chat room
  Future<void> removeParticipant(String chatRoomId, String userId);
}
