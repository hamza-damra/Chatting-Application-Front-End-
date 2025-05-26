import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';
import '../core/services/token_service.dart';
import 'connectivity_service.dart';

class ApiChatService {
  final TokenService _tokenService;
  final http.Client _httpClient;

  ApiChatService({required TokenService tokenService, http.Client? httpClient})
    : _tokenService = tokenService,
      _httpClient = httpClient ?? http.Client();

  // Get all chat rooms for current user
  Future<List<types.Room>> getChatRooms() async {
    try {
      AppLogger.i('ApiChatService', 'Starting to fetch chat rooms...');
      await _ensureValidToken();

      final url = '${ApiConfig.baseUrl}${ApiConfig.chatRoomsEndpoint}';
      final headers = ApiConfig.getAuthHeaders(_tokenService.accessToken!);

      AppLogger.i('ApiChatService', 'Making request to: $url');
      AppLogger.d('ApiChatService', 'Request headers: $headers');

      final response = await _httpClient.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        // Log the response for debugging
        AppLogger.i('ApiChatService', 'API Response: ${response.body}');

        final List<dynamic> data = jsonDecode(response.body);

        // Check if data is empty
        if (data.isEmpty) {
          AppLogger.w('ApiChatService', 'No chat rooms returned from API');
          return [];
        }

        // Log the first room data for debugging
        if (data.isNotEmpty) {
          AppLogger.i('ApiChatService', 'First room data: ${data[0]}');
        }

        return data.map((roomData) => _mapApiRoomToRoom(roomData)).toList();
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      AppLogger.e('ApiChatService', 'Error getting chat rooms: $e');
      ConnectivityService.handleConnectivityError(e.toString());
      rethrow;
    }
  }

  // Get all users for creating a group chat
  Future<List<UserModel>> getAllUsers() async {
    try {
      await _ensureValidToken();

      final response = await _httpClient.get(
        Uri.parse(ApiConfig.baseUrl + ApiConfig.usersEndpoint),
        headers: ApiConfig.getAuthHeaders(_tokenService.accessToken!),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((userData) => UserModel.fromMap(userData)).toList();
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      ConnectivityService.handleConnectivityError(e.toString());
      rethrow;
    }
  }

  // Get chat room by ID
  Future<types.Room> getChatRoomById(int roomId) async {
    try {
      await _ensureValidToken();

      final response = await _httpClient.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.chatRoomsEndpoint}/$roomId'),
        headers: ApiConfig.getAuthHeaders(_tokenService.accessToken!),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _mapApiRoomToRoom(data);
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Create a new chat room
  Future<types.Room> createChatRoom({
    required String name,
    required List<int> participantIds,
    bool isPrivate = false,
  }) async {
    try {
      AppLogger.i('ApiChatService', 'Creating chat room with name: $name');
      AppLogger.i('ApiChatService', 'Participants: $participantIds');
      AppLogger.i('ApiChatService', 'Is Private: $isPrivate');

      await _ensureValidToken();

      final response = await _httpClient.post(
        Uri.parse(ApiConfig.baseUrl + ApiConfig.chatRoomsEndpoint),
        headers: ApiConfig.getAuthHeaders(_tokenService.accessToken!),
        body: jsonEncode({
          'name': name,
          'isPrivate': isPrivate,
          'participantIds': participantIds,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        AppLogger.i('ApiChatService', 'Chat room created successfully: $data');
        return _mapApiRoomToRoom(data);
      } else {
        AppLogger.e(
          'ApiChatService',
          'API Error: ${response.statusCode} - ${response.body}',
        );
        throw _handleError(response);
      }
    } catch (e) {
      AppLogger.e('ApiChatService', 'Error creating chat room: $e');
      ConnectivityService.handleConnectivityError(e.toString());
      rethrow;
    }
  }

  // Update chat room
  Future<types.Room> updateChatRoom({
    required int roomId,
    required String name,
    required bool isPrivate,
  }) async {
    try {
      await _ensureValidToken();

      final response = await _httpClient.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.chatRoomsEndpoint}/$roomId'),
        headers: ApiConfig.getAuthHeaders(_tokenService.accessToken!),
        body: jsonEncode({'name': name, 'isPrivate': isPrivate}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _mapApiRoomToRoom(data);
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Add participant to chat room
  Future<void> addParticipant({
    required int roomId,
    required int userId,
  }) async {
    try {
      await _ensureValidToken();

      // Use the correct URL format with path parameters
      final response = await _httpClient.post(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.chatRoomsEndpoint}/$roomId/participants/$userId',
        ),
        headers: ApiConfig.getAuthHeaders(_tokenService.accessToken!),
      );

      if (response.statusCode != 200) {
        throw _handleError(response);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Remove participant from chat room
  Future<void> removeParticipant({
    required int roomId,
    required int userId,
  }) async {
    try {
      await _ensureValidToken();

      final response = await _httpClient.delete(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.chatRoomsEndpoint}/$roomId/participants/$userId',
        ),
        headers: ApiConfig.getAuthHeaders(_tokenService.accessToken!),
      );

      AppLogger.i(
        'ApiChatService',
        'Remove participant response: ${response.statusCode} - ${response.body}',
      );

      // Accept both 200 and 204 as success for DELETE operations
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw _handleError(response);
      }
    } catch (e) {
      AppLogger.e('ApiChatService', 'Error removing participant: $e');
      rethrow;
    }
  }

  // Get messages for a chat room
  Future<List<types.Message>> getMessages({
    required int roomId,
    int page = 0,
    int size = 20,
  }) async {
    try {
      await _ensureValidToken();

      final response = await _httpClient.get(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.messagesEndpoint}/chatroom/$roomId?page=$page&size=$size',
        ),
        headers: ApiConfig.getAuthHeaders(_tokenService.accessToken!),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> messages = data['content'];
        return messages
            .map((messageData) => _mapApiMessageToMessage(messageData))
            .toList();
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get messages for a room
  Future<List<types.Message>> getRoomMessages({required int roomId}) async {
    try {
      await _ensureValidToken();

      final response = await _httpClient.get(
        Uri.parse('${ApiConfig.baseUrl}/chat/rooms/$roomId/messages'),
        headers: ApiConfig.getAuthHeaders(_tokenService.accessToken!),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((messageData) => _mapApiMessageToMessage(messageData))
            .toList();
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      AppLogger.e('ApiChatService', 'Error getting messages: $e');
      rethrow;
    }
  }

  // Send a text message
  Future<types.Message> sendTextMessage({
    required int roomId,
    required String content,
  }) async {
    try {
      await _ensureValidToken();

      AppLogger.i('ApiChatService', 'Sending text message to room $roomId');

      final response = await _httpClient.post(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.messagesEndpoint}/chatroom/$roomId',
        ),
        headers: ApiConfig.getAuthHeaders(_tokenService.accessToken!),
        body: jsonEncode({'content': content, 'contentType': 'TEXT'}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        AppLogger.i(
          'ApiChatService',
          'Message sent successfully: ${response.body}',
        );
        return _mapApiMessageToMessage(data);
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      AppLogger.e('ApiChatService', 'Error sending text message: $e');
      rethrow;
    }
  }

  // Send a message
  Future<types.Message> sendMessage({
    required int roomId,
    required int senderId,
    required String content,
  }) async {
    try {
      AppLogger.i('ApiChatService', 'Sending message to room $roomId');
      AppLogger.i('ApiChatService', 'Sender ID: $senderId');
      AppLogger.i('ApiChatService', 'Content: $content');

      await _ensureValidToken();

      final response = await _httpClient.post(
        Uri.parse('${ApiConfig.baseUrl}/chat/rooms/$roomId/messages'),
        headers: ApiConfig.getAuthHeaders(_tokenService.accessToken!),
        body: jsonEncode({
          'senderId': senderId,
          'content': content,
          'contentType': 'text',
        }),
      );

      if (response.statusCode == 201) {
        return _mapApiMessageToMessage(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        AppLogger.e('ApiChatService', 'Room not found: $roomId');
        throw Exception('Room with ID $roomId does not exist.');
      } else {
        AppLogger.e(
          'ApiChatService',
          'API Error: ${response.statusCode} - ${response.body}',
        );
        throw _handleError(response);
      }
    } catch (e) {
      AppLogger.e('ApiChatService', 'Error sending message: $e');
      rethrow;
    }
  }

  // Send an image message
  Future<types.Message> sendImageMessage({
    required int roomId,
    required String imageUrl,
  }) async {
    try {
      await _ensureValidToken();

      AppLogger.i('ApiChatService', 'Sending image message to room $roomId');
      AppLogger.i('ApiChatService', 'Image URL: $imageUrl');

      final response = await _httpClient.post(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.messagesEndpoint}/chatroom/$roomId',
        ),
        headers: ApiConfig.getAuthHeaders(_tokenService.accessToken!),
        body: jsonEncode({'content': imageUrl, 'contentType': 'IMAGE'}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        AppLogger.i('ApiChatService', 'Image message sent successfully: $data');
        return _mapApiMessageToMessage(data);
      } else {
        AppLogger.e(
          'ApiChatService',
          'API Error: ${response.statusCode} - ${response.body}',
        );
        throw _handleError(response);
      }
    } catch (e) {
      AppLogger.e('ApiChatService', 'Error sending image message: $e');
      rethrow;
    }
  }

  // Send a file message
  Future<types.Message> sendFileMessage({
    required int roomId,
    required int senderId,
    required String attachmentUrl,
    required String contentType,
  }) async {
    try {
      await _ensureValidToken();

      AppLogger.i('ApiChatService', 'Sending file message to room $roomId');
      AppLogger.i('ApiChatService', 'Attachment URL: $attachmentUrl');
      AppLogger.i('ApiChatService', 'Content Type: $contentType');

      final response = await _httpClient.post(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.messagesEndpoint}/chatroom/$roomId',
        ),
        headers: ApiConfig.getAuthHeaders(_tokenService.accessToken!),
        body: jsonEncode({
          'content': attachmentUrl,
          'contentType': contentType,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        AppLogger.i(
          'ApiChatService',
          'File message sent successfully: ${response.body}',
        );
        return _mapApiMessageToMessage(data);
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      AppLogger.e('ApiChatService', 'Error sending file message: $e');
      rethrow;
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead({
    required int roomId,
    required int userId,
  }) async {
    try {
      await _ensureValidToken();

      final response = await _httpClient.post(
        Uri.parse('${ApiConfig.baseUrl}/chat/rooms/$roomId/read'),
        headers: ApiConfig.getAuthHeaders(_tokenService.accessToken!),
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode != 200) {
        throw _handleError(response);
      }
    } catch (e) {
      AppLogger.e('ApiChatService', 'Error marking messages as read: $e');
      rethrow;
    }
  }

  // Update message status
  Future<void> updateMessageStatus({
    required int messageId,
    required String status,
  }) async {
    try {
      await _ensureValidToken();

      final response = await _httpClient.put(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.messagesEndpoint}/$messageId/status',
        ),
        headers: ApiConfig.getAuthHeaders(_tokenService.accessToken!),
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode != 200) {
        throw _handleError(response);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Add participant to room
  Future<void> addParticipantToRoom({
    required int roomId,
    required int userId,
  }) async {
    try {
      await _ensureValidToken();

      final response = await _httpClient.post(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.chatRoomsEndpoint}/$roomId/participants',
        ),
        headers: ApiConfig.getAuthHeaders(_tokenService.accessToken!),
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode != 200) {
        throw _handleError(response);
      }
    } catch (e) {
      AppLogger.e('ApiChatService', 'Error adding participant: $e');
      rethrow;
    }
  }

  // Delete user from system
  Future<void> deleteUser({required int userId}) async {
    try {
      await _ensureValidToken();

      final response = await _httpClient.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usersEndpoint}/$userId'),
        headers: ApiConfig.getAuthHeaders(_tokenService.accessToken!),
      );

      AppLogger.i(
        'ApiChatService',
        'Delete user response: ${response.statusCode} - ${response.body}',
      );

      // Accept both 200 and 204 as success for DELETE operations
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw _handleError(response);
      }
    } catch (e) {
      AppLogger.e('ApiChatService', 'Error deleting user: $e');
      rethrow;
    }
  }

  // Map API room to flutter_chat_types Room
  types.Room _mapApiRoomToRoom(Map<String, dynamic> data) {
    try {
      AppLogger.i('ApiChatService', 'Mapping room data: $data');

      // Handle participants data which might be structured differently
      List<types.User> users = [];
      if (data.containsKey('participants')) {
        final List<dynamic> participants = data['participants'];
        users =
            participants.map((participant) {
              try {
                // Check if participant has a 'user' field or is the user object itself
                final Map<String, dynamic> userMap =
                    participant.containsKey('user')
                        ? participant['user']
                        : participant;

                final UserModel user = UserModel.fromMap(userMap);
                return types.User(
                  id: user.id.toString(),
                  firstName: user.fullName.split(' ').first,
                  lastName:
                      user.fullName.split(' ').length > 1
                          ? user.fullName.split(' ').last
                          : '',
                  imageUrl: user.profilePicture,
                );
              } catch (e) {
                AppLogger.e('ApiChatService', 'Error mapping participant: $e');
                // Return a placeholder user if mapping fails
                return types.User(
                  id: '0',
                  firstName: 'Unknown',
                  lastName: 'User',
                );
              }
            }).toList();
      } else {
        AppLogger.w('ApiChatService', 'No participants found in room data');
      }

      // Handle private/direct chat type
      bool isPrivate = false;
      if (data.containsKey('isPrivate')) {
        isPrivate = data['isPrivate'] ?? false;
      } else if (data.containsKey('private')) {
        isPrivate = data['private'] ?? false;
      }

      // Handle timestamps
      int createdAt = DateTime.now().millisecondsSinceEpoch;
      int updatedAt = DateTime.now().millisecondsSinceEpoch;

      if (data.containsKey('createdAt') && data['createdAt'] != null) {
        try {
          createdAt = DateTime.parse(data['createdAt']).millisecondsSinceEpoch;
        } catch (e) {
          AppLogger.e('ApiChatService', 'Error parsing createdAt: $e');
        }
      }

      if (data.containsKey('updatedAt') && data['updatedAt'] != null) {
        try {
          updatedAt = DateTime.parse(data['updatedAt']).millisecondsSinceEpoch;
        } catch (e) {
          AppLogger.e('ApiChatService', 'Error parsing updatedAt: $e');
        }
      }

      // Extract unread count if available
      final unreadCount = data['unreadCount'] ?? 0;

      return types.Room(
        id: data['id'].toString(),
        type: isPrivate ? types.RoomType.direct : types.RoomType.group,
        users: users,
        name: data['name'] ?? 'Unnamed Room',
        imageUrl: data['imageUrl'],
        createdAt: createdAt,
        updatedAt: updatedAt,
        metadata: {
          'unreadCount': unreadCount,
          'lastMessage': data['lastMessage'],
          'lastMessageTime': data['lastMessageTime'],
        },
      );
    } catch (e) {
      AppLogger.e('ApiChatService', 'Error in _mapApiRoomToRoom: $e');
      // Return a placeholder room if mapping fails
      return types.Room(
        id: '0',
        type: types.RoomType.group,
        users: [],
        name: 'Error Room',
      );
    }
  }

  // Map API message to flutter_chat_types Message
  types.Message _mapApiMessageToMessage(Map<String, dynamic> data) {
    try {
      AppLogger.i('ApiChatService', 'Mapping message data: $data');

      // Extract sender ID from the nested sender object
      int senderId;
      if (data.containsKey('sender') && data['sender'] != null) {
        // Get sender ID from the nested sender object
        senderId = data['sender']['id'] as int;
      } else if (data.containsKey('senderId') && data['senderId'] != null) {
        // Fallback to senderId if it exists
        senderId = data['senderId'] as int;
      } else {
        // Default to 0 if no sender information is available
        AppLogger.w(
          'ApiChatService',
          'No sender information found in message data',
        );
        senderId = 0;
      }

      final String contentType = data['contentType'] ?? 'TEXT';
      final String content = data['content'] ?? '';

      // Debug logging to trace the conversion issue
      AppLogger.i(
        'ApiChatService',
        'Mapping message data: id=${data['id']}, contentType=$contentType, content=${content.substring(0, content.length.clamp(0, 100))}...',
      );

      // Extract timestamp from sentAt or timestamp field
      int timestamp;
      if (data.containsKey('sentAt') && data['sentAt'] != null) {
        timestamp = DateTime.parse(data['sentAt']).millisecondsSinceEpoch;
      } else if (data.containsKey('timestamp') && data['timestamp'] != null) {
        timestamp = DateTime.parse(data['timestamp']).millisecondsSinceEpoch;
      } else {
        // Default to current time if no timestamp is available
        timestamp = DateTime.now().millisecondsSinceEpoch;
      }

      // Determine message status
      types.Status status;
      final String? statusStr = data['status'] as String?;
      switch (statusStr) {
        case 'SENT':
          status = types.Status.sent;
          break;
        case 'DELIVERED':
          status = types.Status.delivered;
          break;
        case 'READ':
          status = types.Status.seen;
          break;
        default:
          status = types.Status.sending;
      }

      // Handle text messages
      if (contentType == 'TEXT') {
        return types.TextMessage(
          id: data['id'].toString(),
          author: types.User(id: senderId.toString()),
          text: content,
          createdAt: timestamp,
          status: status,
        );
      }
      // Handle image messages (both exact match and MIME types)
      else if (contentType == 'IMAGE' || contentType.startsWith('image/')) {
        return types.ImageMessage(
          id: data['id'].toString(),
          author: types.User(id: senderId.toString()),
          uri: content,
          size: data['size'] ?? 0,
          name: data['name'] ?? 'Image',
          createdAt: timestamp,
          status: status,
        );
      }
      // Handle video messages
      else if (contentType == 'VIDEO' || contentType.startsWith('video/')) {
        return types.CustomMessage(
          id: data['id'].toString(),
          author: types.User(id: senderId.toString()),
          createdAt: timestamp,
          status: status,
          metadata: {
            'type': 'video',
            'uri': content,
            'contentType': contentType,
            'size': data['size'] ?? 0,
            'name': data['name'] ?? 'Video',
          },
        );
      }
      // Handle audio messages
      else if (contentType == 'AUDIO' || contentType.startsWith('audio/')) {
        return types.CustomMessage(
          id: data['id'].toString(),
          author: types.User(id: senderId.toString()),
          createdAt: timestamp,
          status: status,
          metadata: {
            'type': 'audio',
            'uri': content,
            'contentType': contentType,
            'size': data['size'] ?? 0,
            'name': data['name'] ?? 'Audio',
          },
        );
      }
      // Handle file messages
      else if (contentType == 'FILE' ||
          contentType.startsWith('application/') ||
          contentType.startsWith('text/') ||
          contentType.contains('document') ||
          contentType.contains('pdf')) {
        return types.FileMessage(
          id: data['id'].toString(),
          author: types.User(id: senderId.toString()),
          uri: content,
          size: data['size'] ?? 0,
          name: data['name'] ?? 'File',
          createdAt: timestamp,
          status: status,
        );
      }
      // Fallback for unknown types
      else {
        AppLogger.w(
          'ApiChatService',
          'Unknown content type: $contentType, falling back to text message',
        );
        return types.TextMessage(
          id: data['id'].toString(),
          author: types.User(id: senderId.toString()),
          text:
              content.isNotEmpty
                  ? content
                  : 'Unsupported message type: $contentType',
          createdAt: timestamp,
          status: status,
        );
      }
    } catch (e) {
      AppLogger.e('ApiChatService', 'Error mapping message: $e');

      // Return a fallback message in case of error
      return types.TextMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        author: types.User(id: '0'),
        text: 'Error processing message',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        status: types.Status.error,
      );
    }
  }

  // Ensure token is valid, refresh if needed
  Future<void> _ensureValidToken() async {
    if (!_tokenService.hasToken) {
      AppLogger.e('ApiChatService', 'No authentication token available');
      throw Exception('Not authenticated - please login again');
    }

    AppLogger.d('ApiChatService', 'Checking token validity...');

    if (_tokenService.isTokenExpired) {
      AppLogger.w('ApiChatService', 'Token expired, attempting refresh...');
      try {
        await _refreshToken();
        AppLogger.i('ApiChatService', 'Token refreshed successfully');
      } catch (e) {
        AppLogger.e('ApiChatService', 'Token refresh failed: $e');
        throw Exception('Authentication failed - please login again');
      }
    } else {
      AppLogger.d('ApiChatService', 'Token is valid');
    }
  }

  // Refresh token
  Future<void> _refreshToken() async {
    try {
      if (_tokenService.refreshToken == null) {
        throw Exception('No refresh token available');
      }

      final response = await _httpClient.post(
        Uri.parse(ApiConfig.baseUrl + ApiConfig.refreshTokenEndpoint),
        headers: ApiConfig.getContentTypeHeader(),
        body: jsonEncode({'refreshToken': _tokenService.refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Save new tokens
        await _tokenService.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          expiresIn: data['expiresIn'],
        );
      } else {
        // If refresh token is invalid, clear tokens and force re-login
        await _tokenService.clearTokens();
        throw _handleError(response);
      }
    } catch (e) {
      await _tokenService.clearTokens();
      rethrow;
    }
  }

  // Handle API errors
  Exception _handleError(http.Response response) {
    try {
      final data = jsonDecode(response.body);

      // Extract detailed error information
      final message = data['message'] ?? 'Unknown error';
      final path = data['path'] ?? '';
      final status = data['status'] ?? response.statusCode;

      // Create a more detailed error message
      return Exception(
        'API Error ($status): $message${path.isNotEmpty ? ' - Path: $path' : ''}',
      );
    } catch (e) {
      // If we can't parse the JSON, return the raw response
      return Exception(
        'Error ${response.statusCode}: ${response.reasonPhrase} - ${response.body}',
      );
    }
  }
}
