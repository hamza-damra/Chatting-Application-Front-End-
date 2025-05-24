import '../../core/services/api_service.dart';
import '../../domain/models/chat_room_model.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/chat_room_repository.dart';
import '../../utils/logger.dart';

class ChatRoomRepositoryImpl implements ChatRoomRepository {
  final ApiService _apiService;

  ChatRoomRepositoryImpl(this._apiService);

  @override
  Future<List<ChatRoomModel>> getUserChatRooms() async {
    try {
      final response = await _apiService.get('/api/chatrooms');
      final List<dynamic> roomsData = response.data;
      return roomsData
          .map((roomData) => ChatRoomModel.fromJson(roomData))
          .toList();
    } catch (e) {
      AppLogger.e(
        'ChatRoomRepositoryImpl',
        'Error getting user chat rooms: $e',
      );
      rethrow;
    }
  }

  @override
  Future<ChatRoomModel> getChatRoomById(String id) async {
    try {
      final response = await _apiService.get('/api/chatrooms/$id');
      return ChatRoomModel.fromJson(response.data);
    } catch (e) {
      AppLogger.e(
        'ChatRoomRepositoryImpl',
        'Error getting chat room by ID: $e',
      );
      rethrow;
    }
  }

  @override
  Future<ChatRoomModel> createChatRoom(
    String name,
    bool isPrivate,
    List<String> participantIds,
  ) async {
    try {
      final response = await _apiService.post(
        '/api/chatrooms',
        data: {
          'name': name,
          'isPrivate': isPrivate,
          'participantIds': participantIds,
        },
      );
      return ChatRoomModel.fromJson(response.data);
    } catch (e) {
      AppLogger.e('ChatRoomRepositoryImpl', 'Error creating chat room: $e');
      rethrow;
    }
  }

  @override
  Future<ChatRoomModel> createPrivateChat(String userId) async {
    try {
      final response = await _apiService.post(
        '/api/chatrooms/private',
        data: {'userId': userId},
      );
      return ChatRoomModel.fromJson(response.data);
    } catch (e) {
      AppLogger.e('ChatRoomRepositoryImpl', 'Error creating private chat: $e');
      rethrow;
    }
  }

  @override
  Future<ChatRoomModel> updateChatRoom(
    String id,
    String name,
    bool isPrivate,
  ) async {
    try {
      final response = await _apiService.put(
        '/api/chatrooms/$id',
        data: {'name': name, 'isPrivate': isPrivate},
      );
      return ChatRoomModel.fromJson(response.data);
    } catch (e) {
      AppLogger.e('ChatRoomRepositoryImpl', 'Error updating chat room: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteChatRoom(String id) async {
    try {
      await _apiService.delete('/api/chatrooms/$id');
    } catch (e) {
      AppLogger.e('ChatRoomRepositoryImpl', 'Error deleting chat room: $e');
      rethrow;
    }
  }

  @override
  Future<List<UserModel>> getChatRoomParticipants(String id) async {
    try {
      final response = await _apiService.get('/api/chatrooms/$id/participants');
      final List<dynamic> participantsData = response.data;
      return participantsData
          .map((participantData) => UserModel.fromJson(participantData))
          .toList();
    } catch (e) {
      AppLogger.e(
        'ChatRoomRepositoryImpl',
        'Error getting chat room participants: $e',
      );
      rethrow;
    }
  }

  @override
  Future<void> addParticipant(String chatRoomId, String userId) async {
    try {
      await _apiService.post(
        '/api/chatrooms/$chatRoomId/participants',
        data: {'userId': userId},
      );
    } catch (e) {
      AppLogger.e('ChatRoomRepositoryImpl', 'Error adding participant: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeParticipant(String chatRoomId, String userId) async {
    try {
      await _apiService.delete(
        '/api/chatrooms/$chatRoomId/participants/$userId',
      );
    } catch (e) {
      AppLogger.e('ChatRoomRepositoryImpl', 'Error removing participant: $e');
      rethrow;
    }
  }
}
