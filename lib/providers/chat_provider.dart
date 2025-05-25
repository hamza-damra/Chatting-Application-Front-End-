import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:chatting_application/models/chat_room.dart';
import 'package:chatting_application/models/message.dart' as app_models;
import '../services/api_chat_service.dart';
import '../services/websocket_service.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';
import '../providers/api_auth_provider.dart';
import '../models/unread_message_notification.dart';
import '../utils/url_utils.dart';

class ChatProvider with ChangeNotifier {
  final ApiChatService _chatService;
  final WebSocketService _webSocketService;
  final ApiAuthProvider _authProvider;

  // Optional notification provider for rich notifications
  Function(UnreadMessageNotification)? _onNotificationReceived;

  List<types.Room> _rooms = [];
  final Map<String, List<types.Message>> _messages = {};
  bool _isLoading = false;
  String? _error;
  types.Room? _selectedRoom;
  List<UserModel> _users = [];
  final Map<String, int> _unreadMessageCounts = {};

  // Track active WebSocket subscriptions to prevent duplicates
  final Set<String> _activeSubscriptions = {};

  // Getters
  List<types.Room> get rooms => _rooms;
  int get currentUserId => _authProvider.user?.id ?? 0;

  // Return private chat rooms (direct chats) as ChatRoom objects
  List<ChatRoom> get privateChatRooms {
    final privateRooms =
        _rooms.where((room) => room.type == types.RoomType.direct).toList();
    return privateRooms.map(_convertTypesRoomToChatRoom).toList();
  }

  // Return group chat rooms as ChatRoom objects
  List<ChatRoom> get groupChatRooms {
    final groupRooms =
        _rooms.where((room) => room.type == types.RoomType.group).toList();
    return groupRooms.map(_convertTypesRoomToChatRoom).toList();
  }

  // Helper method to convert types.Room to ChatRoom
  ChatRoom _convertTypesRoomToChatRoom(types.Room room) {
    // Use calculated unread count based on actual message statuses
    final unreadCount = getUnreadCount(room.id);

    return ChatRoom(
      id: int.parse(room.id),
      name: room.name,
      description: room.metadata?['description'] as String?,
      isPrivate: room.type == types.RoomType.direct,
      lastMessageId: null, // Not available in types.Room
      lastActivity:
          room.metadata?['lastMessageTime'] != null
              ? DateTime.tryParse(room.metadata!['lastMessageTime'] as String)
              : null,
      unreadCount: unreadCount,
      participantIds: room.users.map((user) => int.parse(user.id)).toList(),
    );
  }

  // Public method to convert types.Room to ChatRoom
  ChatRoom convertRoomToChatRoom(types.Room room) {
    // Use calculated unread count based on actual message statuses
    final unreadCount = getUnreadCount(room.id);

    return ChatRoom(
      id: int.parse(room.id),
      name: room.name ?? '',
      description: room.metadata?['description'] as String?,
      isPrivate: room.type == types.RoomType.direct,
      lastMessageId: null,
      lastActivity:
          room.metadata?['lastMessageTime'] != null
              ? DateTime.tryParse(room.metadata!['lastMessageTime'] as String)
              : null,
      unreadCount: unreadCount,
      participantIds: room.users.map((user) => int.parse(user.id)).toList(),
    );
  }

  // Return private chat rooms (direct chats)
  Future<List<ChatRoom>> getPrivateChatRooms() async {
    try {
      // Force refresh from server to get latest data
      await _loadRooms();

      // Filter rooms for private/direct chats
      final privateRooms =
          _rooms.where((room) {
            return room.type == types.RoomType.direct;
          }).toList();

      // Convert types.Room to ChatRoom model
      return privateRooms.map(_convertTypesRoomToChatRoom).toList();
    } catch (e) {
      AppLogger.e('ChatProvider', 'Error getting private chat rooms: $e');
      rethrow;
    }
  }

  // Get group chat rooms
  Future<List<ChatRoom>> getGroupChatRooms() async {
    try {
      // Force refresh from server to get latest data
      await _loadRooms();

      final groupRooms =
          _rooms.where((room) => room.type == types.RoomType.group).toList();
      return groupRooms.map(_convertTypesRoomToChatRoom).toList();
    } catch (e) {
      AppLogger.e('ChatProvider', 'Error getting group chat rooms: $e');
      rethrow;
    }
  }

  // Get messages for a room - messages are stored with newest at the end
  List<types.Message> getMessages(String roomId) => _messages[roomId] ?? [];

  Future<List<app_models.Message>> getMessagesForRoom(String roomId) async {
    final messages = await _chatService.getMessages(roomId: int.parse(roomId));
    // Ensure chronological order: oldest first, newest last
    // Most APIs return newest first, so we need to reverse to show oldest first in UI
    final sortedMessages =
        messages.toList(); // Create a copy to avoid modifying original
    sortedMessages.sort(
      (a, b) => a.createdAt?.compareTo(b.createdAt ?? 0) ?? 0,
    ); // Sort by timestamp
    return sortedMessages.map(_convertTypesMessageToAppMessage).toList();
  }

  Future<app_models.Message> sendMessageContentInternal(
    String roomId,
    String content,
  ) async {
    try {
      final message = await _chatService.sendMessage(
        content: content,
        roomId: int.parse(roomId),
        senderId: currentUserId,
      );
      notifyListeners();
      return _convertTypesMessageToAppMessage(message);
    } catch (e) {
      if (e.toString().contains('Room with ID') &&
          e.toString().contains('does not exist')) {
        // Room was deleted, refresh the room list
        await _loadRooms();
        // Remove the room from local state
        _rooms.removeWhere((room) => room.id == roomId);
        _messages.remove(roomId);
        if (_selectedRoom?.id == roomId) {
          _selectedRoom = null;
        }
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<app_models.Message> sendFileMessage(
    String roomId,
    String attachmentUrl,
    String contentType,
  ) async {
    try {
      AppLogger.i('ChatProvider', 'Sending file message to room $roomId');
      AppLogger.i('ChatProvider', 'File URL: $attachmentUrl');
      AppLogger.i('ChatProvider', 'Content Type: $contentType');

      // If the URL is empty, handle error
      if (attachmentUrl.isEmpty) {
        throw Exception(
          'Empty attachment URL. The file may not have been uploaded correctly.',
        );
      }

      // For auto-generated URLs (when server doesn't respond), we need a special handling
      // These URLs don't have a path separator but are still valid for our purposes
      final bool isAutoGenerated =
          attachmentUrl.contains('-') &&
          (attachmentUrl.contains('.jpg') ||
              attachmentUrl.contains('.jpeg') ||
              attachmentUrl.contains('.png') ||
              attachmentUrl.contains('.pdf') ||
              attachmentUrl.contains('.mp4') ||
              attachmentUrl.contains('.mp3'));

      if (!attachmentUrl.contains('/') && !isAutoGenerated) {
        throw Exception(
          'Invalid attachment URL format. The file may not have been uploaded correctly.',
        );
      }

      // First try to send the message via WebSocket for real-time delivery
      _sendRealTimeMessage(roomId, currentUserId, attachmentUrl, contentType);

      // Create a temporary message ID with timestamp for easier matching later
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempId = 'temp_$timestamp';

      // Create a temporary message
      final currentUser = _getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Create a temporary message for immediate display
      types.Message tempMessage;
      if (contentType.startsWith('image/')) {
        tempMessage = types.ImageMessage(
          id: tempId,
          author: currentUser,
          uri: attachmentUrl,
          name: _getFileNameFromUrl(attachmentUrl),
          size: 0, // Size unknown at this point
          createdAt: timestamp,
          status: types.Status.sent,
        );
      } else {
        tempMessage = types.TextMessage(
          id: tempId,
          author: currentUser,
          text: 'File: ${_getFileNameFromUrl(attachmentUrl)}',
          createdAt: timestamp,
          status: types.Status.sent,
          metadata: {
            'attachmentUrl': attachmentUrl,
            'contentType': contentType,
          },
        );
      }

      // Add the message to the local list immediately for a responsive UI
      AppLogger.i(
        'ChatProvider',
        'Adding temporary file message to UI: $tempId',
      );
      _addMessageToList(roomId, tempMessage);

      // Force UI update immediately
      notifyListeners();

      // Now send via API service for persistence
      AppLogger.i('ChatProvider', 'Sending file message via API service');
      final message = await _chatService.sendFileMessage(
        roomId: int.parse(roomId),
        senderId: currentUserId,
        attachmentUrl: attachmentUrl,
        contentType: contentType,
      );

      AppLogger.i(
        'ChatProvider',
        'File message sent successfully, replacing temp message',
      );
      // Replace the temporary message with the real one
      _replaceMessage(roomId, tempId, message);

      notifyListeners();
      return _convertTypesMessageToAppMessage(message);
    } catch (e) {
      AppLogger.e('ChatProvider', 'Error sending file message: $e');
      rethrow;
    }
  }

  // Helper method to extract filename from URL
  String _getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        return pathSegments.last;
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return 'File';
  }

  // Helper method to extract filename from URI (for image messages)
  String _getFileNameFromUri(String uri) {
    try {
      final parsedUri = Uri.parse(uri);
      final pathSegments = parsedUri.pathSegments;
      if (pathSegments.isNotEmpty) {
        return pathSegments.last;
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return 'image';
  }

  Future<void> markMessagesAsRead(String roomId) async {
    try {
      AppLogger.i('ChatProvider', 'Marking messages as read for room $roomId');

      // Clear unread count immediately for better UX
      _unreadMessageCounts[roomId] = 0;

      // Mark all messages from other users as read in local storage
      final messages = _messages[roomId] ?? [];
      final currentUserIdStr = _authProvider.user?.id.toString();

      for (int i = 0; i < messages.length; i++) {
        final message = messages[i];
        // Only mark messages from other users as read
        if (message.author.id != currentUserIdStr &&
            message.status != types.Status.seen) {
          // Update the message status to seen (read) using existing method
          _updateMessageStatus(roomId, message.id, types.Status.seen);
        }
      }

      // Notify listeners immediately to update UI
      notifyListeners();

      // Mark messages as read on the server (async, non-blocking)
      _chatService
          .markMessagesAsRead(roomId: int.parse(roomId), userId: currentUserId)
          .then((_) {
            AppLogger.i(
              'ChatProvider',
              'Successfully marked messages as read on server for room $roomId',
            );
          })
          .catchError((e) {
            AppLogger.e(
              'ChatProvider',
              'Error marking messages as read on server for room $roomId: $e',
            );
          });
    } catch (e) {
      AppLogger.e(
        'ChatProvider',
        'Error marking messages as read for room $roomId: $e',
      );
      // Don't rethrow to prevent UI issues, but log the error
    }
  }

  // Clear unread count for a specific room
  void clearUnreadCount(String roomId) {
    if (_unreadMessageCounts.containsKey(roomId) &&
        _unreadMessageCounts[roomId]! > 0) {
      _unreadMessageCounts[roomId] = 0;
      notifyListeners();
      AppLogger.i('ChatProvider', 'Cleared unread count for room $roomId');
    }
  }

  // Reset all unread counts
  void resetAllUnreadCounts() {
    _unreadMessageCounts.clear();
    // Use microtask to ensure we're not in a build cycle
    Future.microtask(() {
      notifyListeners();
    });
    AppLogger.i('ChatProvider', 'Reset all unread counts');
  }

  // Force refresh unread counts and notify listeners
  void refreshUnreadCounts() {
    AppLogger.i('ChatProvider', 'Force refreshing unread counts');
    notifyListeners();
  }

  // Get total unread count across all rooms
  int get totalUnreadCount {
    return _unreadMessageCounts.values.fold(0, (sum, count) => sum + count);
  }

  // Debug method to log current unread counts
  void debugLogUnreadCounts() {
    AppLogger.i('ChatProvider', 'Current unread counts:');
    for (final entry in _unreadMessageCounts.entries) {
      AppLogger.i('ChatProvider', '  Room ${entry.key}: ${entry.value}');
    }
    AppLogger.i('ChatProvider', 'Total unread count: $totalUnreadCount');
  }

  // Clear the currently selected room
  void clearSelectedRoom() {
    if (_selectedRoom != null) {
      AppLogger.i(
        'ChatProvider',
        'Clearing selected room: ${_selectedRoom!.id}',
      );
      _selectedRoom = null;
      notifyListeners();
    }
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  types.Room? get selectedRoom => _selectedRoom;
  List<UserModel> get users => _users;
  int getUnreadCount(String roomId) {
    // Debug log the request
    AppLogger.d('ChatProvider', 'Getting unread count for room: $roomId');
    AppLogger.d(
      'ChatProvider',
      'Available unread counts: $_unreadMessageCounts',
    );
    AppLogger.d('ChatProvider', 'Selected room: ${_selectedRoom?.id}');

    // If we have a stored count and the room is not currently selected, use it
    // This prevents recalculation issues when leaving rooms
    if (_unreadMessageCounts.containsKey(roomId)) {
      final storedCount = _unreadMessageCounts[roomId]!;

      // If this is the currently selected room, it should always be 0
      if (_selectedRoom?.id == roomId) {
        AppLogger.d('ChatProvider', 'Room $roomId is selected, returning 0');
        return 0;
      }

      // For non-selected rooms, use the stored count
      AppLogger.d(
        'ChatProvider',
        'Returning stored count for room $roomId: $storedCount',
      );
      return storedCount;
    }

    // Fallback to calculated count only if no stored count exists
    final calculatedCount = _calculateActualUnreadCount(roomId);
    return calculatedCount >= 0 ? calculatedCount : 0;
  }

  // Calculate actual unread count based on message statuses
  int _calculateActualUnreadCount(String roomId) {
    try {
      final messages = _messages[roomId] ?? [];

      if (messages.isEmpty) {
        return 0;
      }

      int unreadCount = 0;
      final currentUserId = _authProvider.user?.id.toString();

      for (final message in messages) {
        // Only count messages from other users
        if (message.author.id != currentUserId) {
          // Count messages that are not read by current user
          if (message.status != types.Status.seen) {
            unreadCount++;
          }
        }
      }

      AppLogger.d(
        'ChatProvider',
        'Calculated unread count for room $roomId: $unreadCount (from ${messages.length} messages)',
      );

      return unreadCount;
    } catch (e) {
      AppLogger.e(
        'ChatProvider',
        'Error calculating unread count for room $roomId: $e',
      );
      return -1; // Return -1 to indicate calculation failed
    }
  }

  // Recalculate and update unread count for a room
  void _recalculateUnreadCount(String roomId) {
    final calculatedCount = _calculateActualUnreadCount(roomId);
    if (calculatedCount >= 0) {
      final previousCount = _unreadMessageCounts[roomId] ?? 0;
      _unreadMessageCounts[roomId] = calculatedCount;

      if (previousCount != calculatedCount) {
        AppLogger.i(
          'ChatProvider',
          'Updated unread count for room $roomId: $previousCount -> $calculatedCount',
        );
      }
    }
  }

  // Constructor
  ChatProvider({
    required ApiChatService chatService,
    required WebSocketService webSocketService,
    required ApiAuthProvider authProvider,
  }) : _chatService = chatService,
       _webSocketService = webSocketService,
       _authProvider = authProvider {
    _init();
  }

  // Initialize the provider
  Future<void> _init() async {
    await _loadRooms();
    await _loadUsers();
    await _webSocketService.connect();

    // Subscribe to real-time unread message updates
    _subscribeToUnreadUpdates();

    // Subscribe to rich unread message notifications
    _subscribeToUnreadNotifications();
  }

  // Set up notification callback (called from main app)
  void setNotificationCallback(Function(UnreadMessageNotification) callback) {
    _onNotificationReceived = callback;
  }

  // Subscribe to rich unread message notifications
  void _subscribeToUnreadNotifications() {
    try {
      AppLogger.i(
        'ChatProvider',
        'Setting up unread notification subscription...',
      );
      _webSocketService.subscribeToUnreadNotifications(
        onNotificationReceived: (notification) {
          AppLogger.i(
            'ChatProvider',
            'Received rich notification: ${notification.senderUsername} in ${notification.chatRoomName}',
          );

          // Forward to notification provider if callback is set
          if (_onNotificationReceived != null) {
            AppLogger.i('ChatProvider', 'Forwarding notification to provider');
            _onNotificationReceived!(notification);
          } else {
            AppLogger.w(
              'ChatProvider',
              'No notification callback set, notification will be ignored',
            );
          }
        },
      );
      AppLogger.i('ChatProvider', 'Unread notification subscription completed');
    } catch (e) {
      AppLogger.e(
        'ChatProvider',
        'Error subscribing to unread notifications: $e',
      );
    }
  }

  // Load all users
  Future<void> _loadUsers() async {
    _isLoading = true;
    notifyListeners();

    try {
      _users = await _chatService.getAllUsers();
      AppLogger.i('ChatProvider', 'Loaded ${_users.length} users from API');
      _error = null;
    } catch (e) {
      AppLogger.e('ChatProvider', 'Error loading users: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reload users (for refreshing the list)
  Future<void> reloadUsers() async {
    await _loadUsers();
  }

  // Subscribe to real-time unread message updates
  void _subscribeToUnreadUpdates() {
    try {
      AppLogger.i('ChatProvider', 'Subscribing to real-time unread updates');

      // Subscribe to unread count updates
      _webSocketService.subscribeToUnreadUpdates(
        onUnreadUpdate: (unreadData) {
          _handleUnreadUpdate(unreadData);
        },
      );

      // Request initial unread counts
      _requestInitialUnreadCounts();

      AppLogger.i('ChatProvider', 'Successfully subscribed to unread updates');
    } catch (e) {
      AppLogger.e('ChatProvider', 'Error subscribing to unread updates: $e');
    }
  }

  // Handle real-time unread count updates
  void _handleUnreadUpdate(Map<String, dynamic> unreadData) {
    try {
      final chatRoomId = unreadData['chatRoomId']?.toString();
      final unreadCount = unreadData['unreadCount'] as int? ?? 0;
      final updateType = unreadData['updateType'] as String?;
      final totalUnreadCount = unreadData['totalUnreadCount'] as int? ?? 0;

      AppLogger.i(
        'ChatProvider',
        'Received real-time unread update: $unreadData',
      );

      if (chatRoomId != null) {
        // Update the unread count for the specific room
        final previousCount = _unreadMessageCounts[chatRoomId] ?? 0;
        _unreadMessageCounts[chatRoomId] = unreadCount;

        AppLogger.i(
          'ChatProvider',
          'Real-time unread update: Room $chatRoomId: $previousCount -> $unreadCount (Type: $updateType)',
        );

        // Update room metadata if available
        if (unreadData.containsKey('latestMessageContent')) {
          _updateRoomLatestMessage(chatRoomId, unreadData);
        }

        // Notify listeners to update UI
        AppLogger.i('ChatProvider', 'Notifying listeners after unread update');
        notifyListeners();

        // Debug log current state after update
        debugLogUnreadCounts();

        // Log total unread count for debugging
        AppLogger.d(
          'ChatProvider',
          'Total unread count across all rooms: $totalUnreadCount',
        );
      } else {
        AppLogger.w(
          'ChatProvider',
          'Received unread update with null chatRoomId',
        );
      }
    } catch (e) {
      AppLogger.e('ChatProvider', 'Error handling unread update: $e');
    }
  }

  // Update room's latest message information
  void _updateRoomLatestMessage(String roomId, Map<String, dynamic> data) {
    try {
      final roomIndex = _rooms.indexWhere((room) => room.id == roomId);
      if (roomIndex != -1) {
        final room = _rooms[roomIndex];
        final updatedMetadata = Map<String, dynamic>.from(room.metadata ?? {});

        // Update latest message information
        if (data.containsKey('latestMessageContent')) {
          updatedMetadata['lastMessage'] = data['latestMessageContent'];
        }
        if (data.containsKey('timestamp')) {
          updatedMetadata['lastMessageTime'] = data['timestamp'];
        }
        if (data.containsKey('latestMessageSender')) {
          updatedMetadata['lastMessageSender'] = data['latestMessageSender'];
        }

        // Update unread count in metadata
        updatedMetadata['unreadCount'] = data['unreadCount'] ?? 0;

        // Create updated room
        final updatedRoom = types.Room(
          id: room.id,
          type: room.type,
          users: room.users,
          name: room.name,
          imageUrl: room.imageUrl,
          createdAt: room.createdAt,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
          metadata: updatedMetadata,
        );

        // Replace the room in the list
        _rooms[roomIndex] = updatedRoom;

        AppLogger.d('ChatProvider', 'Updated latest message for room $roomId');
      }
    } catch (e) {
      AppLogger.e('ChatProvider', 'Error updating room latest message: $e');
    }
  }

  // Request initial unread counts from server
  void _requestInitialUnreadCounts() {
    try {
      AppLogger.i('ChatProvider', 'Requesting initial unread counts');
      _webSocketService.requestUnreadCounts();
    } catch (e) {
      AppLogger.e('ChatProvider', 'Error requesting initial unread counts: $e');
    }
  }

  // Mark entire room as read via WebSocket
  Future<void> markRoomAsRead(String roomId) async {
    try {
      AppLogger.i('ChatProvider', 'Marking room $roomId as read via WebSocket');

      // Clear unread count immediately for better UX
      _unreadMessageCounts[roomId] = 0;
      notifyListeners();

      // Send mark as read request via WebSocket
      final success = await _webSocketService.markRoomAsRead(int.parse(roomId));

      if (success) {
        AppLogger.i('ChatProvider', 'Successfully marked room $roomId as read');
      } else {
        AppLogger.w(
          'ChatProvider',
          'Failed to mark room $roomId as read via WebSocket',
        );
        // Fallback to REST API
        await markMessagesAsRead(roomId);
      }
    } catch (e) {
      AppLogger.e('ChatProvider', 'Error marking room as read: $e');
      // Fallback to REST API
      await markMessagesAsRead(roomId);
    }
  }

  @override
  void dispose() {
    // Disconnect WebSocket
    _webSocketService.disconnect();
    super.dispose();
  }

  // Load all chat rooms
  Future<void> _loadRooms() async {
    try {
      _rooms = await _chatService.getChatRooms();

      // Sync unread counts from server data
      _syncUnreadCountsFromServer();

      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  // Sync unread counts from server metadata
  void _syncUnreadCountsFromServer() {
    for (final room in _rooms) {
      final serverUnreadCount = room.metadata?['unreadCount'] as int? ?? 0;
      if (serverUnreadCount > 0) {
        _unreadMessageCounts[room.id] = serverUnreadCount;
        AppLogger.i(
          'ChatProvider',
          'Synced unread count for room ${room.id}: $serverUnreadCount',
        );
      }
    }
  }

  // Sync unread counts from ChatRoomModel data (for ChatBloc integration)
  void syncUnreadCountsFromChatRooms(List<dynamic> chatRooms) {
    try {
      for (final room in chatRooms) {
        String roomId;
        int unreadCount = 0;

        // Handle both ChatRoomModel and other room types
        if (room is Map<String, dynamic>) {
          roomId = room['id']?.toString() ?? '';
          unreadCount = room['unreadCount'] as int? ?? 0;
        } else {
          // Use reflection or dynamic access for other types
          try {
            roomId = (room as dynamic).id?.toString() ?? '';
            unreadCount = (room as dynamic).unreadCount as int? ?? 0;
          } catch (e) {
            AppLogger.w(
              'ChatProvider',
              'Could not extract room data from $room: $e',
            );
            continue;
          }
        }

        if (roomId.isNotEmpty) {
          final previousCount = _unreadMessageCounts[roomId] ?? 0;
          _unreadMessageCounts[roomId] = unreadCount;

          if (previousCount != unreadCount) {
            AppLogger.i(
              'ChatProvider',
              'Synced unread count for room $roomId: $previousCount -> $unreadCount',
            );
          }
        }
      }

      // Notify listeners to update UI
      notifyListeners();

      // Debug log current state
      debugLogUnreadCounts();
    } catch (e) {
      AppLogger.e(
        'ChatProvider',
        'Error syncing unread counts from chat rooms: $e',
      );
    }
  }

  // Select a room and load its messages
  Future<void> selectRoom(types.Room room) async {
    try {
      AppLogger.i('ChatProvider', 'Selecting room with ID: ${room.id}');

      // Unsubscribe from previous room if any
      if (_selectedRoom != null && _selectedRoom!.id != room.id) {
        AppLogger.i(
          'ChatProvider',
          'Unsubscribing from previous room: ${_selectedRoom!.id}',
        );
        unsubscribeFromRoom(_selectedRoom!.id);
      }

      _selectedRoom = room;

      // Make sure the room exists in our list
      final existingRoom = _rooms.firstWhere(
        (r) => r.id == room.id,
        orElse: () {
          AppLogger.w(
            'ChatProvider',
            'Room ${room.id} not found in rooms list, adding it',
          );
          // Add the room to our list if it's not there
          _rooms = [..._rooms, room];
          return room;
        },
      );

      // Clear unread count immediately when entering a room
      _unreadMessageCounts[existingRoom.id] = 0;

      // Load messages for this room
      await _loadMessages(existingRoom.id);

      // Subscribe to real-time messages for this room
      _subscribeToRoomMessages(existingRoom.id);

      // Mark messages as read when selecting a room (async, non-blocking)
      markMessagesAsRead(existingRoom.id);

      notifyListeners();
      AppLogger.i(
        'ChatProvider',
        'Room selection completed for room ${existingRoom.id}',
      );
    } catch (e) {
      AppLogger.e('ChatProvider', 'Error in selectRoom: $e');
      rethrow;
    }
  }

  // Load messages for a specific room
  Future<void> _loadMessages(String roomId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final messages = await _chatService.getMessages(
        roomId: int.parse(roomId),
      );

      // Store messages with newest at the end (oldest first)
      // This ensures messages appear in chronological order in the chat UI
      // The API might return messages in reverse order (newest first), so we need to reverse them
      _messages[roomId] = List.from(messages.reversed);

      // Recalculate unread count based on actual message statuses
      _recalculateUnreadCount(roomId);

      AppLogger.i(
        'ChatProvider',
        'Loaded ${messages.length} messages for room $roomId',
      );
      _error = null;
    } catch (e) {
      AppLogger.e('ChatProvider', 'Error loading messages: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Subscribe to real-time messages for a room
  void _subscribeToRoomMessages(String roomId) {
    try {
      AppLogger.i(
        'ChatProvider',
        'Subscribing to room messages for room $roomId',
      );

      // First, ensure we're connected to the WebSocket
      if (!_webSocketService.isConnected) {
        AppLogger.i(
          'ChatProvider',
          'WebSocket not connected, connecting now...',
        );
        _webSocketService
            .connect()
            .then((_) {
              AppLogger.i(
                'ChatProvider',
                'WebSocket connected, now subscribing to room messages',
              );
              // Subscribe after connection is established
              _subscribeToWebSocketMessages(roomId);
            })
            .catchError((e) {
              AppLogger.e('ChatProvider', 'Error connecting to WebSocket: $e');
            });
        return;
      }

      // If already connected, subscribe immediately
      _subscribeToWebSocketMessages(roomId);
    } catch (e) {
      AppLogger.e('ChatProvider', 'Error subscribing to room messages: $e');
    }
  }

  // Helper method to subscribe to WebSocket messages
  void _subscribeToWebSocketMessages(String roomId) {
    try {
      // Check if already subscribed to prevent duplicates
      if (_activeSubscriptions.contains(roomId)) {
        AppLogger.w(
          'ChatProvider',
          'Already subscribed to room $roomId, skipping duplicate subscription',
        );
        return;
      }

      // Mark as subscribed
      _activeSubscriptions.add(roomId);
      AppLogger.i(
        'ChatProvider',
        'Marked room $roomId as subscribed. Active subscriptions: $_activeSubscriptions',
      );

      // Subscribe to new messages via WebSocket
      _webSocketService.subscribeToMessages(
        roomId: int.parse(roomId),
        onMessageReceived: (message) {
          AppLogger.i(
            'ChatProvider',
            'Received WebSocket message for room $roomId: ${message.id}',
          );

          // Check if this is a message we sent (already in our list with a temp ID)
          // We need to find if there's a temporary message with the same content and timestamp
          bool isExistingMessage = false;

          if (_messages.containsKey(roomId) && _messages[roomId]!.isNotEmpty) {
            // For text messages, check content and approximate timestamp
            if (message is types.TextMessage) {
              AppLogger.d(
                'ChatProvider',
                'Processing incoming text message: ${message.id}, text: "${message.text}", author: ${message.author.id}',
              );

              for (var existingMsg in _messages[roomId]!) {
                if (existingMsg is types.TextMessage &&
                    existingMsg.id.startsWith('temp_')) {
                  AppLogger.d(
                    'ChatProvider',
                    'Found temp text message: ${existingMsg.id}, text: "${existingMsg.text}", author: ${existingMsg.author.id}',
                  );

                  // Check if this is our own message by comparing text content and author
                  if (existingMsg.text == message.text &&
                      existingMsg.author.id == message.author.id) {
                    // This is likely our own message that was just confirmed by the server
                    // Replace the temporary message with the confirmed one
                    AppLogger.i(
                      'ChatProvider',
                      'Replacing temp message ${existingMsg.id} with confirmed message ${message.id}',
                    );
                    _replaceMessage(roomId, existingMsg.id, message);
                    isExistingMessage = true;
                    break;
                  }
                }
              }
            }
            // Similar check for image messages
            else if (message is types.ImageMessage) {
              AppLogger.d(
                'ChatProvider',
                'Processing incoming image message: ${message.id}, URI: ${message.uri}',
              );

              for (var existingMsg in _messages[roomId]!) {
                if (existingMsg is types.ImageMessage &&
                    existingMsg.id.startsWith('temp_')) {
                  AppLogger.d(
                    'ChatProvider',
                    'Found temp image message: ${existingMsg.id}, URI: ${existingMsg.uri}',
                  );

                  // Better matching: check if the URIs are related or if this is the most recent temp message
                  bool shouldReplace = false;

                  // Check if the URIs match (for cases where the server returns the same URL)
                  if (message.uri == existingMsg.uri) {
                    shouldReplace = true;
                    AppLogger.d(
                      'ChatProvider',
                      'URI match found, replacing temp message',
                    );
                  }
                  // Check if the incoming message URI contains the filename from temp message
                  else if (message.uri.contains(
                    _getFileNameFromUri(existingMsg.uri),
                  )) {
                    shouldReplace = true;
                    AppLogger.d(
                      'ChatProvider',
                      'Filename match found, replacing temp message',
                    );
                  }
                  // If no specific match, replace the oldest temp message (FIFO)
                  else {
                    // Find the oldest temp message
                    var oldestTempMsg = existingMsg;
                    final oldestCreatedAt = oldestTempMsg.createdAt ?? 0;

                    for (var tempMsg in _messages[roomId]!) {
                      if (tempMsg is types.ImageMessage &&
                          tempMsg.id.startsWith('temp_')) {
                        final tempCreatedAt = tempMsg.createdAt ?? 0;
                        if (tempCreatedAt < oldestCreatedAt) {
                          oldestTempMsg = tempMsg;
                        }
                      }
                    }
                    if (existingMsg == oldestTempMsg) {
                      shouldReplace = true;
                      AppLogger.d(
                        'ChatProvider',
                        'Replacing oldest temp message',
                      );
                    }
                  }

                  if (shouldReplace) {
                    // Replace temp message with server message, ensuring URI is server URL
                    final updatedMessage =
                        message.uri.startsWith('http')
                            ? message
                            : message.copyWith(uri: existingMsg.uri);
                    _replaceMessage(roomId, existingMsg.id, updatedMessage);
                    isExistingMessage = true;
                    AppLogger.i(
                      'ChatProvider',
                      'Replaced temp message ${existingMsg.id} with server message ${message.id}',
                    );
                    break;
                  }
                }
              }
            }
            // Handle custom messages (videos, files, etc.)
            else if (message is types.CustomMessage) {
              AppLogger.d(
                'ChatProvider',
                'Processing incoming custom message: ${message.id}',
              );

              for (var existingMsg in _messages[roomId]!) {
                if (existingMsg is types.CustomMessage &&
                    existingMsg.id.startsWith('temp_')) {
                  // Replace the first temp custom message
                  _replaceMessage(roomId, existingMsg.id, message);
                  isExistingMessage = true;
                  AppLogger.i(
                    'ChatProvider',
                    'Replaced temp custom message ${existingMsg.id} with server message ${message.id}',
                  );
                  break;
                }
              }
            }
          }

          // If this is a new message (not one we sent), add it to the list
          if (!isExistingMessage) {
            // Check if this message is from the current user
            final currentUserId = _authProvider.user?.id.toString();
            final isFromCurrentUser = message.author.id == currentUserId;

            AppLogger.i(
              'ChatProvider',
              'Adding new message from WebSocket: ${message.id}, from current user: $isFromCurrentUser',
            );

            // For messages from other users, ensure they have a proper status
            if (message is types.TextMessage) {
              message = message.copyWith(status: types.Status.sent);
            } else if (message is types.ImageMessage) {
              message = message.copyWith(status: types.Status.sent);
            }

            _addMessageToList(roomId, message);

            // If this is not the currently selected room and not from current user, increment unread count
            if (_selectedRoom?.id != roomId && !isFromCurrentUser) {
              final previousCount = _unreadMessageCounts[roomId] ?? 0;
              _unreadMessageCounts[roomId] = previousCount + 1;
              AppLogger.i(
                'ChatProvider',
                'Incremented unread count for room $roomId: $previousCount -> ${_unreadMessageCounts[roomId]}',
              );
            } else {
              AppLogger.d(
                'ChatProvider',
                'Not incrementing unread count for room $roomId: selectedRoom=${_selectedRoom?.id}, isFromCurrentUser=$isFromCurrentUser',
              );
            }
          }

          // Always notify listeners to update the UI
          // Use microtask to ensure we're on the main thread
          Future.microtask(() {
            notifyListeners();

            // Log the current message count for debugging
            if (_messages.containsKey(roomId)) {
              AppLogger.i(
                'ChatProvider',
                'Room $roomId now has ${_messages[roomId]!.length} messages after WebSocket update',
              );
            }
          });
        },
      );

      // Notify the server that we've joined this room
      _webSocketService.joinChatRoom(int.parse(roomId)).then((success) {
        if (success) {
          AppLogger.i('ChatProvider', 'Joined chat room: $roomId');
        } else {
          AppLogger.w(
            'ChatProvider',
            'Failed to notify server about joining room $roomId',
          );
        }
      });

      AppLogger.i('ChatProvider', 'Subscribed to messages for room $roomId');
    } catch (e) {
      AppLogger.e('ChatProvider', 'Error subscribing to room messages: $e');
    }
  }

  // Unsubscribe from room messages when leaving a room
  void unsubscribeFromRoom(String roomId) {
    try {
      // Remove from active subscriptions
      _activeSubscriptions.remove(roomId);
      AppLogger.i(
        'ChatProvider',
        'Removed room $roomId from active subscriptions. Remaining: $_activeSubscriptions',
      );

      // Clear selected room if we're leaving the currently selected room
      if (_selectedRoom?.id == roomId) {
        _selectedRoom = null;
        AppLogger.i(
          'ChatProvider',
          'Cleared selected room $roomId when unsubscribing',
        );
      }

      // Ensure unread count is 0 when leaving a room (user has seen all messages)
      if (_unreadMessageCounts.containsKey(roomId)) {
        _unreadMessageCounts[roomId] = 0;
        AppLogger.i(
          'ChatProvider',
          'Cleared unread count for room $roomId when unsubscribing',
        );
      }

      // Notify the server that we're leaving this room
      _webSocketService.leaveChatRoom(int.parse(roomId)).then((success) {
        if (!success) {
          AppLogger.w(
            'ChatProvider',
            'Failed to notify server about leaving room $roomId',
          );
        }
      });

      AppLogger.i(
        'ChatProvider',
        'Unsubscribed from messages for room $roomId',
      );
    } catch (e) {
      AppLogger.e('ChatProvider', 'Error unsubscribing from room messages: $e');
    }
  }

  // Create a new room
  Future<String?> createRoom({
    required List<String> userIds,
    required String name,
    String? imageUrl,
    bool isGroup = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppLogger.i(
        'ChatProvider',
        'Creating room with name: $name, userIds: $userIds, isGroup: $isGroup',
      );

      // Convert string IDs to integers
      final participantIds = userIds.map((id) => int.parse(id)).toList();

      final room = await _chatService.createChatRoom(
        name: name,
        participantIds: participantIds,
        isPrivate: !isGroup,
      );

      AppLogger.i(
        'ChatProvider',
        'Room created successfully with ID: ${room.id}',
      );

      // Refresh rooms after creating a new one
      AppLogger.i('ChatProvider', 'Refreshing rooms list...');
      await _loadRooms();

      // Select the newly created room
      AppLogger.i('ChatProvider', 'Selecting newly created room...');
      try {
        await selectRoom(room);
        AppLogger.i('ChatProvider', 'Room selection successful');
      } catch (e) {
        AppLogger.e('ChatProvider', 'Error selecting room: $e');
      }

      AppLogger.i(
        'ChatProvider',
        'Room creation complete. Total rooms: ${_rooms.length}',
      );

      return room.id;
    } catch (e) {
      AppLogger.e('ChatProvider', 'Error creating room: $e');
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Added `refreshRooms` method to refresh chat rooms.

  Future<void> refreshRooms() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadRooms();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Store failed messages for retry
  final Map<String, List<Map<String, dynamic>>> _failedMessages = {};

  // Maximum character limit for messages
  final int maxMessageLength = 2000;

  // Maximum retry attempts for failed messages
  final int maxRetryAttempts = 3;

  // Send a text message
  Future<app_models.Message> sendTextMessage({
    required String roomId,
    required String text,
  }) async {
    try {
      // Create a temporary message ID with timestamp for easier matching later
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempId = 'temp_$timestamp';

      // Create a temporary message for optimistic UI update
      final currentUser = _getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final tempMessage = types.TextMessage(
        author: currentUser,
        createdAt: timestamp,
        id: tempId,
        text: text,
        status: types.Status.sending,
      );

      // Add temporary message to local list for immediate UI feedback
      _addMessageToList(roomId, tempMessage);
      notifyListeners();

      AppLogger.i(
        'ChatProvider',
        'Added temporary text message $tempId to room $roomId',
      );

      // ONLY send via WebSocket for real-time delivery
      // Remove duplicate REST API call to prevent backend receiving message twice
      _sendRealTimeMessage(roomId, currentUserId, text, 'TEXT');

      AppLogger.i(
        'ChatProvider',
        'Text message sent successfully via WebSocket only',
      );

      // Return a placeholder message since we're only using WebSocket
      // The real message will come back via WebSocket subscription
      return app_models.Message(
        id: 0, // Placeholder ID
        content: text,
        contentType: 'TEXT',
        senderId: currentUserId,
        roomId: int.parse(roomId),
        sentAt: DateTime.now(),
      );
    } catch (e) {
      AppLogger.e('ChatProvider', 'Error sending text message: $e');
      rethrow;
    }
  }

  // Get the current user as a types.User
  types.User? _getCurrentUser() {
    // Get the current user from the auth provider
    final currentUser = _authProvider.user;
    if (currentUser == null) {
      AppLogger.w('ChatProvider', 'No authenticated user found');
      return null;
    }

    // Convert UserModel to types.User
    return types.User(
      id: currentUser.id.toString(),
      firstName: currentUser.fullName.split(' ').first,
      lastName:
          currentUser.fullName.split(' ').length > 1
              ? currentUser.fullName.split(' ').skip(1).join(' ')
              : '',
      imageUrl: currentUser.profilePicture,
    );
  }

  // Add a message to the local list
  void _addMessageToList(String roomId, types.Message message) {
    // Initialize the messages list if it doesn't exist
    if (!_messages.containsKey(roomId)) {
      _messages[roomId] = [];
    }

    // Enhanced duplicate checking to prevent message duplication when reopening chat
    final existingIndex = _messages[roomId]!.indexWhere(
      (m) => _isMessageDuplicate(m, message),
    );
    if (existingIndex != -1) {
      AppLogger.i(
        'ChatProvider',
        'Message ${message.id} is a duplicate of existing message ${_messages[roomId]![existingIndex].id} in room $roomId, not adding',
      );
      return;
    }

    // Add the message to the end of the list (newest last)
    // This makes new messages appear at the bottom of the chat
    _messages[roomId] = [..._messages[roomId]!, message];

    AppLogger.i(
      'ChatProvider',
      'Added message ${message.id} (type: ${message.runtimeType}) to room $roomId, total messages: ${_messages[roomId]!.length}',
    );

    // Log message details for debugging
    if (message is types.ImageMessage) {
      AppLogger.d('ChatProvider', 'Image message URI: ${message.uri}');
    } else if (message is types.CustomMessage) {
      AppLogger.d(
        'ChatProvider',
        'Custom message metadata: ${message.metadata}',
      );
    }

    // Force UI update using microtask to ensure we're on the main thread
    Future.microtask(() {
      notifyListeners();
      AppLogger.i(
        'ChatProvider',
        'UI updated after adding message ${message.id}',
      );
    });
  }

  /// Check if two messages are duplicates based on multiple criteria
  bool _isMessageDuplicate(types.Message existing, types.Message incoming) {
    // First check: exact ID match
    if (existing.id == incoming.id) {
      return true;
    }

    // Skip duplicate checking for temporary messages
    if (existing.id.startsWith('temp_') || incoming.id.startsWith('temp_')) {
      return false;
    }

    // Second check: same author and very close timestamps (within 5 seconds)
    if (existing.author.id == incoming.author.id) {
      final existingTime = existing.createdAt ?? 0;
      final incomingTime = incoming.createdAt ?? 0;
      final timeDifference = (existingTime - incomingTime).abs();

      // If timestamps are very close (within 5 seconds)
      if (timeDifference <= 5000) {
        // For text messages, also check content
        if (existing is types.TextMessage && incoming is types.TextMessage) {
          if (existing.text == incoming.text) {
            AppLogger.d(
              'ChatProvider',
              'Found duplicate text message: existing=${existing.id}, incoming=${incoming.id}, text="${existing.text}"',
            );
            return true;
          }
        }
        // For image messages, check URI
        else if (existing is types.ImageMessage &&
            incoming is types.ImageMessage) {
          if (existing.uri == incoming.uri ||
              _getFileNameFromUri(existing.uri) ==
                  _getFileNameFromUri(incoming.uri)) {
            AppLogger.d(
              'ChatProvider',
              'Found duplicate image message: existing=${existing.id}, incoming=${incoming.id}, uri="${existing.uri}"',
            );
            return true;
          }
        }
        // For custom messages, check metadata
        else if (existing is types.CustomMessage &&
            incoming is types.CustomMessage) {
          final existingContent =
              existing.metadata?['content'] ??
              existing.metadata?['attachmentUrl'];
          final incomingContent =
              incoming.metadata?['content'] ??
              incoming.metadata?['attachmentUrl'];
          if (existingContent != null && existingContent == incomingContent) {
            AppLogger.d(
              'ChatProvider',
              'Found duplicate custom message: existing=${existing.id}, incoming=${incoming.id}',
            );
            return true;
          }
        }
      }
    }

    return false;
  }

  // Replace a temporary message with the actual message from the server
  void _replaceMessage(
    String roomId,
    String tempId,
    types.Message actualMessage,
  ) {
    if (!_messages.containsKey(roomId)) {
      AppLogger.w(
        'ChatProvider',
        'Cannot replace message: room $roomId not found in messages',
      );
      return;
    }

    final index = _messages[roomId]!.indexWhere((msg) => msg.id == tempId);
    if (index != -1) {
      AppLogger.i(
        'ChatProvider',
        'Replacing message $tempId with ${actualMessage.id} at index $index',
      );

      // Create a new list to ensure the UI updates
      final updatedMessages = List<types.Message>.from(_messages[roomId]!);

      // Copy over status from temp message if the actual message doesn't have one
      if (actualMessage is types.TextMessage &&
          updatedMessages[index] is types.TextMessage) {
        final tempMessage = updatedMessages[index] as types.TextMessage;
        if (tempMessage.status == types.Status.sending) {
          // Keep the sent status if the message was successfully sent
          actualMessage = actualMessage.copyWith(status: types.Status.sent);
        } else if (tempMessage.status == types.Status.sent) {
          // Preserve the sent status from the temp message
          actualMessage = actualMessage.copyWith(status: types.Status.sent);
        }
      } else if (actualMessage is types.ImageMessage &&
          updatedMessages[index] is types.ImageMessage) {
        final tempMessage = updatedMessages[index] as types.ImageMessage;
        if (tempMessage.status == types.Status.sending) {
          // Keep the sent status if the message was successfully sent
          actualMessage = actualMessage.copyWith(status: types.Status.sent);
        } else if (tempMessage.status == types.Status.sent) {
          // Preserve the sent status from the temp message
          actualMessage = actualMessage.copyWith(status: types.Status.sent);
        }
      }

      // Replace the message
      updatedMessages[index] = actualMessage;
      _messages[roomId] = updatedMessages;

      // Log the updated message list for debugging
      AppLogger.i(
        'ChatProvider',
        'Updated message list for room $roomId, now has ${updatedMessages.length} messages',
      );

      // Force UI update using microtask to ensure we're on the main thread
      Future.microtask(() {
        notifyListeners();
        AppLogger.i(
          'ChatProvider',
          'UI updated after replacing message $tempId with ${actualMessage.id}',
        );
      });
    } else {
      AppLogger.w(
        'ChatProvider',
        'Message with ID $tempId not found in room $roomId',
      );

      // If we can't find the temporary message, just add the actual message
      // This ensures we don't miss any messages
      _addMessageToList(roomId, actualMessage);
    }
  }

  // Update the status of a message
  void _updateMessageStatus(
    String roomId,
    String messageId,
    types.Status status,
  ) {
    if (!_messages.containsKey(roomId)) return;

    final index = _messages[roomId]!.indexWhere((msg) => msg.id == messageId);
    if (index != -1) {
      final message = _messages[roomId]![index];

      if (message is types.TextMessage) {
        final updatedMessage = message.copyWith(status: status);
        final updatedMessages = List<types.Message>.from(_messages[roomId]!);
        updatedMessages[index] = updatedMessage;
        _messages[roomId] = updatedMessages;

        // Force UI update using microtask to ensure we're on the main thread
        Future.microtask(() {
          notifyListeners();
          AppLogger.i(
            'ChatProvider',
            'UI updated after changing text message ${message.id} status to $status',
          );
        });
      } else if (message is types.ImageMessage) {
        final updatedMessage = message.copyWith(status: status);
        final updatedMessages = List<types.Message>.from(_messages[roomId]!);
        updatedMessages[index] = updatedMessage;
        _messages[roomId] = updatedMessages;

        // Force UI update using microtask to ensure we're on the main thread
        Future.microtask(() {
          notifyListeners();
          AppLogger.i(
            'ChatProvider',
            'UI updated after changing image message ${message.id} status to $status',
          );
        });
      }
    }
  }

  // Store a failed message for retry
  void _storeFailedMessage(String roomId, Map<String, dynamic> messageData) {
    if (!_failedMessages.containsKey(roomId)) {
      _failedMessages[roomId] = [];
    }

    _failedMessages[roomId]!.add(messageData);
  }

  // Check if there are failed messages for a room
  bool hasFailedMessages(String roomId) {
    return _failedMessages.containsKey(roomId) &&
        _failedMessages[roomId]!.isNotEmpty;
  }

  // Retry sending failed messages
  Future<void> retryFailedMessages(String roomId) async {
    if (!_failedMessages.containsKey(roomId) ||
        _failedMessages[roomId]!.isEmpty) {
      return;
    }

    final failedMessagesForRoom = List<Map<String, dynamic>>.from(
      _failedMessages[roomId]!,
    );
    _failedMessages[roomId] = [];

    for (final messageData in failedMessagesForRoom) {
      final retryCount = messageData['retryCount'] as int;

      if (retryCount >= maxRetryAttempts) {
        // Max retry attempts reached, give up
        continue;
      }

      // Update retry count
      messageData['retryCount'] = retryCount + 1;

      final tempId = messageData['tempId'] as String;

      // Update message status to sending
      _updateMessageStatus(roomId, tempId, types.Status.sending);

      try {
        if (messageData['type'] == 'TEXT') {
          final sentMessage = await _chatService.sendTextMessage(
            roomId: int.parse(roomId),
            content: messageData['content'],
          );

          // Replace the temporary message with the actual message
          _replaceMessage(roomId, tempId, sentMessage);
        } else if (messageData['type'] == 'IMAGE') {
          final sentMessage = await _chatService.sendImageMessage(
            roomId: int.parse(roomId),
            imageUrl: messageData['content'],
          );

          // Replace the temporary message with the actual message
          _replaceMessage(roomId, tempId, sentMessage);
        }
      } catch (e) {
        AppLogger.e('ChatProvider', 'Error retrying message: $e');

        // Store the failed message for retry again
        _storeFailedMessage(roomId, messageData);

        // Update the message status to show it failed
        _updateMessageStatus(roomId, tempId, types.Status.error);
      }
    }

    notifyListeners();
  }

  // Send an image message
  Future<void> sendImageMessage({
    required String roomId,
    required File imageFile,
  }) async {
    try {
      // Validate file exists
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      // Validate file size (max 5MB)
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('Image file is too large (max 5MB)');
      }

      // Read image file as bytes
      final List<int> imageBytes = await imageFile.readAsBytes();

      // Validate image data
      if (imageBytes.isEmpty) {
        throw Exception('Image file is empty');
      }

      // Get file name and extension
      final String fileName = imageFile.path.split('/').last;
      final String fileExtension = fileName.split('.').last.toLowerCase();

      // Validate file extension
      if (!['jpg', 'jpeg', 'png'].contains(fileExtension)) {
        throw Exception('Unsupported image format. Please use JPG or PNG');
      }

      final String mimeType = 'image/$fileExtension';

      // Create a temporary message ID with timestamp for easier matching later
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempId = 'temp_$timestamp';

      // Create a temporary message
      final currentUser = _getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Convert to base64 for sending over WebSocket and for preview
      // Use a try-catch to handle encoding errors
      String base64Image;
      try {
        base64Image = base64Encode(imageBytes);

        // Validate base64 data
        if (base64Image.isEmpty) {
          throw Exception('Failed to encode image data');
        }
      } catch (e) {
        throw Exception('Failed to encode image: $e');
      }

      // Create a temporary image message
      // Always set status to 'sent' for current user's messages to ensure blue color
      final tempMessage = types.ImageMessage(
        id: tempId,
        author: currentUser,
        uri:
            imageFile
                .path, // Use local file path instead of base64 data to avoid memory issues
        name: fileName,
        size: imageBytes.length,
        createdAt: timestamp,
        status:
            types
                .Status
                .sent, // Use 'sent' instead of 'sending' to ensure blue color
      );

      // Add the message to the local list immediately
      _addMessageToList(roomId, tempMessage);

      // Force UI update immediately after adding the message
      notifyListeners();

      // Set loading state after adding the message to the UI
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Prepare the message payload with metadata
      // Only include essential data to reduce payload size
      final Map<String, dynamic> imagePayload = {
        'data': base64Image,
        'fileName': fileName,
        'mimeType': mimeType,
        'size': imageBytes.length,
      };

      // Convert the payload to JSON string
      final String imagePayloadJson = jsonEncode(imagePayload);

      // Send image via WebSocket
      AppLogger.i('ChatProvider', 'Sending image via WebSocket with metadata');

      bool success = await _webSocketService.sendMessageWithRetry(
        roomId: int.parse(roomId),
        content: imagePayloadJson, // Send the JSON with image data and metadata
        contentType: 'IMAGE',
        maxRetries: 3, // Increased retries since we're only using WebSocket
      );

      if (success) {
        AppLogger.i('ChatProvider', 'Image sent successfully via WebSocket');
        // Update message status to indicate it was sent
        _updateMessageStatus(roomId, tempId, types.Status.sent);

        // The server will broadcast the message back to all clients including us
        // The message will be received in the WebSocket subscription and will replace
        // our temporary message with the actual one from the server

        // Clear any error
        _error = null;
      } else {
        // WebSocket send failed
        AppLogger.e(
          'ChatProvider',
          'Failed to send image via WebSocket after multiple attempts',
        );

        throw Exception(
          'Failed to send image via WebSocket after multiple attempts',
        );
      }
    } catch (e) {
      _error = e.toString();
      AppLogger.e('ChatProvider', 'Error sending image message: $e');

      // We can't access tempId here since it's defined in the try block
      // Instead, we'll just notify listeners about the error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Convert flutter_chat_types Message to our app's Message model
  app_models.Message _convertTypesMessageToAppMessage(types.Message message) {
    // Extract common fields
    int? senderId = int.tryParse(message.author.id);
    String? senderName = message.author.firstName;

    // Default to current user if we can't parse the ID
    senderId ??= _authProvider.user?.id ?? 0;

    String? content;
    String? attachmentUrl;
    String? contentType;

    if (message is types.TextMessage) {
      content = message.text;
      contentType = 'TEXT';

      // Extract attachment info from metadata if it exists
      if (message.metadata != null) {
        attachmentUrl = message.metadata!['attachmentUrl'];
        contentType = message.metadata!['contentType'] ?? contentType;
      }
    } else if (message is types.ImageMessage) {
      content =
          message.uri; // Store image path in content for consistent handling
      attachmentUrl = message.uri;
      contentType = 'image/jpeg'; // Assume JPEG for simplicity
    } else if (message is types.CustomMessage && message.metadata != null) {
      // Handle custom message types from the backend
      contentType = message.metadata!['contentType'];
      attachmentUrl =
          message.metadata!['attachmentUrl'] ?? message.metadata!['uri'];

      // For image files in content field
      if (contentType?.startsWith('image/') == true) {
        content = attachmentUrl ?? message.metadata!['uri'];
        // Normalize the URL if it's a relative path
        if (content != null && !content.startsWith('http')) {
          content = UrlUtils.normalizeImageUrl(content);
        }
      }
      // For video files in content field
      else if (contentType?.startsWith('video/') == true) {
        content = attachmentUrl ?? message.metadata!['uri'];
        // Normalize the URL if it's a relative path
        if (content != null && !content.startsWith('http')) {
          content = UrlUtils.normalizeImageUrl(
            content,
          ); // Use same normalization for videos
        }
      }
      // For other custom message types, use the content from metadata
      else {
        content = message.metadata!['content'] ?? attachmentUrl;
      }
    }

    // Create our app's Message model
    return app_models.Message(
      id: int.tryParse(message.id),
      roomId: int.tryParse(message.roomId ?? "0"),
      senderId: senderId,
      senderName: senderName,
      content: content,
      attachmentUrl: attachmentUrl,
      contentType: contentType,
      sentAt:
          message.createdAt != null
              ? DateTime.fromMillisecondsSinceEpoch(message.createdAt!)
              : DateTime.now(),
      isRead: false, // Default to unread for new messages
    );
  }

  // Added `addParticipant` method to add a user to a chat room.

  Future<bool> addParticipant({
    required int roomId,
    required int userId,
  }) async {
    try {
      await _chatService.addParticipantToRoom(roomId: roomId, userId: userId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _sendRealTimeMessage(
    String roomId,
    int senderId,
    String content,
    String contentType,
  ) {
    try {
      _webSocketService.sendMessage(
        roomId: int.parse(roomId),
        content: content,
        contentType: contentType,
      );
    } catch (e) {
      AppLogger.e('ChatProvider', 'Error sending real-time message: $e');
    }
  }
}
