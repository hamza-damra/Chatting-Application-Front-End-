import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import '../services/api_chat_service.dart';
import '../services/websocket_service.dart';

class ApiChatProvider with ChangeNotifier {
  final ApiChatService _chatService;
  final WebSocketService _webSocketService;

  List<types.Room> _rooms = [];
  final Map<String, List<types.Message>> _messages = {};
  bool _isLoading = false;
  String? _error;
  types.Room? _selectedRoom;
  final Map<String, StreamSubscription<types.Message>> _messageSubscriptions =
      {};

  // Getters
  List<types.Room> get rooms => _rooms;
  List<types.Message> getMessages(String roomId) => _messages[roomId] ?? [];
  bool get isLoading => _isLoading;
  String? get error => _error;
  types.Room? get selectedRoom => _selectedRoom;

  // Constructor
  ApiChatProvider({
    required ApiChatService chatService,
    required WebSocketService webSocketService,
  }) : _chatService = chatService,
       _webSocketService = webSocketService {
    _init();
  }

  // Initialize the provider
  Future<void> _init() async {
    await _loadRooms();
    await _webSocketService.connect();
  }

  @override
  void dispose() {
    // Cancel all message subscriptions
    for (final subscription in _messageSubscriptions.values) {
      subscription.cancel();
    }
    _messageSubscriptions.clear();

    // Disconnect WebSocket
    _webSocketService.disconnect();

    super.dispose();
  }

  // Load all chat rooms
  Future<void> _loadRooms() async {
    _isLoading = true;
    notifyListeners();

    try {
      _rooms = await _chatService.getChatRooms();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Select a room and load its messages
  Future<void> selectRoom(types.Room room) async {
    _selectedRoom = room;
    await _loadMessages(room.id);

    // Subscribe to real-time messages for this room
    _subscribeToRoomMessages(room.id);

    notifyListeners();
  }

  // Load messages for a specific room
  Future<void> _loadMessages(String roomId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final messages = await _chatService.getMessages(
        roomId: int.parse(roomId),
      );

      _messages[roomId] = messages;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Subscribe to real-time messages for a room
  void _subscribeToRoomMessages(String roomId) {
    // Cancel existing subscription if any
    _messageSubscriptions[roomId]?.cancel();

    // Subscribe to new messages
    final subscription = _webSocketService.subscribeToRoom(roomId).listen((
      message,
    ) {
      if (_messages.containsKey(roomId)) {
        _messages[roomId] = [message, ..._messages[roomId]!];
        notifyListeners();
      }
    });

    _messageSubscriptions[roomId] = subscription;
  }

  // Create a new chat room
  Future<types.Room?> createRoom({
    required String name,
    required List<int> participantIds,
    bool isPrivate = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final room = await _chatService.createChatRoom(
        name: name,
        participantIds: participantIds,
        isPrivate: isPrivate,
      );

      _rooms = [..._rooms, room];
      return room;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update a chat room
  Future<bool> updateRoom({
    required int roomId,
    required String name,
    required bool isPrivate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedRoom = await _chatService.updateChatRoom(
        roomId: roomId,
        name: name,
        isPrivate: isPrivate,
      );

      // Update the room in the list
      final index = _rooms.indexWhere((room) => room.id == roomId.toString());
      if (index != -1) {
        _rooms[index] = updatedRoom;
      }

      // Update selected room if it's the one being updated
      if (_selectedRoom?.id == roomId.toString()) {
        _selectedRoom = updatedRoom;
      }

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add participant to a chat room
  Future<bool> addParticipant({
    required int roomId,
    required int userId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _chatService.addParticipant(roomId: roomId, userId: userId);

      // Reload the room to get updated participants
      final updatedRoom = await _chatService.getChatRoomById(roomId);

      // Update the room in the list
      final index = _rooms.indexWhere((room) => room.id == roomId.toString());
      if (index != -1) {
        _rooms[index] = updatedRoom;
      }

      // Update selected room if it's the one being updated
      if (_selectedRoom?.id == roomId.toString()) {
        _selectedRoom = updatedRoom;
      }

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Remove participant from a chat room
  Future<bool> removeParticipant({
    required int roomId,
    required int userId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _chatService.removeParticipant(roomId: roomId, userId: userId);

      // Reload the room to get updated participants
      final updatedRoom = await _chatService.getChatRoomById(roomId);

      // Update the room in the list
      final index = _rooms.indexWhere((room) => room.id == roomId.toString());
      if (index != -1) {
        _rooms[index] = updatedRoom;
      }

      // Update selected room if it's the one being updated
      if (_selectedRoom?.id == roomId.toString()) {
        _selectedRoom = updatedRoom;
      }

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send a text message
  Future<void> sendTextMessage({
    required String roomId,
    required String text,
  }) async {
    try {
      // Send message via WebSocket for real-time delivery
      _webSocketService.sendMessage(
        roomId: int.parse(roomId),
        content: text,
        contentType: 'TEXT',
      );

      // Also send via REST API as a fallback
      await _chatService.sendTextMessage(
        roomId: int.parse(roomId),
        content: text,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Send an image message
  Future<void> sendImageMessage({
    required String roomId,
    required File imageFile,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Note: Image upload functionality removed
      // In a real app, you would implement image upload to your backend

      // For now, we'll use a placeholder URL
      const imageUrl = "https://example.com/placeholder-image.jpg";

      // Send message via WebSocket for real-time delivery
      _webSocketService.sendMessage(
        roomId: int.parse(roomId),
        content: imageUrl,
        contentType: 'IMAGE',
      );

      // Also send via REST API as a fallback
      await _chatService.sendImageMessage(
        roomId: int.parse(roomId),
        imageUrl: imageUrl,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update message status
  Future<void> updateMessageStatus({
    required String messageId,
    required String status,
  }) async {
    try {
      await _chatService.updateMessageStatus(
        messageId: int.parse(messageId),
        status: status,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Refresh rooms
  Future<void> refreshRooms() async {
    await _loadRooms();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
