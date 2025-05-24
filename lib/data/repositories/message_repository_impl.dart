import 'dart:async';
import 'package:dio/dio.dart';
import '../../core/services/api_service.dart';
import '../../core/services/websocket_service.dart';
import '../../domain/models/message_model.dart';
import '../../domain/models/message_status_model.dart';
import '../../domain/repositories/message_repository.dart';
import '../../utils/logger.dart';

class MessageRepositoryImpl implements MessageRepository {
  final ApiService _apiService;
  final WebSocketService _webSocketService;

  // Stream controllers to broadcast messages and status updates
  final _messageStreamController = StreamController<MessageModel>.broadcast();
  final _statusStreamController =
      StreamController<MessageStatusModel>.broadcast();

  // Reconnection variables
  bool _isReconnecting = false;
  Timer? _reconnectionTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _baseReconnectDelay = Duration(seconds: 2);

  MessageRepositoryImpl(this._apiService, this._webSocketService) {
    // Listen to WebSocket events and forward them to our streams
    _webSocketService.messageStream.listen((message) {
      _messageStreamController.add(message);
    });

    _webSocketService.statusStream.listen((status) {
      _statusStreamController.add(status);
    });

    // Set up connection status listener
    _webSocketService.connectionStatusStream.listen((isConnected) {
      if (!isConnected && !_isReconnecting) {
        _scheduleReconnect();
      } else if (isConnected) {
        // Reset reconnection attempts when successfully connected
        _reconnectAttempts = 0;
        _cancelReconnect();
      }
    });

    // Connect to WebSocket
    _initWebSocketConnection();
  }

  Future<void> _initWebSocketConnection() async {
    try {
      await _webSocketService.connect();
    } catch (e) {
      AppLogger.e('MessageRepositoryImpl', 'Error connecting to WebSocket: $e');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_isReconnecting || _reconnectAttempts >= _maxReconnectAttempts) {
      return;
    }

    _isReconnecting = true;
    _reconnectAttempts++;

    // Use exponential backoff
    final delay = _baseReconnectDelay * (_reconnectAttempts * 2);

    AppLogger.i(
      'MessageRepositoryImpl',
      'Scheduling WebSocket reconnection attempt $_reconnectAttempts in ${delay.inSeconds} seconds',
    );

    _reconnectionTimer = Timer(delay, () async {
      try {
        AppLogger.i(
          'MessageRepositoryImpl',
          'Attempting to reconnect to WebSocket...',
        );
        await _webSocketService.connect();
        _isReconnecting = false;
      } catch (e) {
        AppLogger.e('MessageRepositoryImpl', 'Reconnection attempt failed: $e');
        _isReconnecting = false;

        if (_reconnectAttempts < _maxReconnectAttempts) {
          _scheduleReconnect();
        } else {
          AppLogger.e(
            'MessageRepositoryImpl',
            'Max reconnection attempts reached, giving up for now',
          );
        }
      }
    });
  }

  void _cancelReconnect() {
    _isReconnecting = false;
    _reconnectionTimer?.cancel();
    _reconnectionTimer = null;
  }

  @override
  Future<List<MessageModel>> getChatRoomMessages(
    String chatRoomId, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      // Try alternative endpoint format first
      try {
        final response = await _apiService.get(
          '/api/messages/chatroom/$chatRoomId',
          queryParameters: {'page': page, 'size': size},
        );

        final List<dynamic> messagesJson = response.data;
        return messagesJson.map((json) => MessageModel.fromJson(json)).toList();
      } catch (e) {
        AppLogger.w(
          'MessageRepositoryImpl',
          'Failed with first endpoint format, trying fallback: $e',
        );
      }

      // Fallback to original endpoint
      final response = await _apiService.get(
        '/api/messages',
        queryParameters: {'chatRoomId': chatRoomId, 'page': page, 'size': size},
      );

      final List<dynamic> messagesJson = response.data;
      return messagesJson.map((json) => MessageModel.fromJson(json)).toList();
    } catch (e) {
      AppLogger.e(
        'MessageRepositoryImpl',
        'Error getting chat room messages: $e',
      );
      throw _handleError(e);
    }
  }

  @override
  Future<MessageModel> sendMessage(
    String chatRoomId,
    String content,
    MessageContentType contentType,
  ) async {
    try {
      // Check WebSocket connection and try to reconnect if needed
      if (!_webSocketService.isConnected) {
        AppLogger.w(
          'MessageRepositoryImpl',
          'WebSocket not connected, attempting to reconnect before sending message',
        );
        try {
          await _webSocketService.connect();
        } catch (e) {
          AppLogger.e(
            'MessageRepositoryImpl',
            'Failed to reconnect WebSocket: $e',
          );
          // Continue with API request even if WebSocket is unavailable
        }
      }

      // Try to send via WebSocket for real-time delivery
      try {
        _webSocketService.sendMessage({
          'type': 'MESSAGE',
          'content': content,
          'contentType': contentType.toString().split('.').last.toUpperCase(),
          'chatRoomId': chatRoomId,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        AppLogger.e(
          'MessageRepositoryImpl',
          'Error sending message via WebSocket: $e',
        );
        // Continue with API request even if WebSocket message fails
      }

      // Also save to API for persistence (multiple endpoint formats)
      try {
        // First try the primary endpoint
        final response = await _apiService.post(
          '/api/messages',
          data: {
            'chatRoomId': chatRoomId,
            'content': content,
            'contentType': contentType.toString().split('.').last.toUpperCase(),
          },
        );
        return MessageModel.fromJson(response.data);
      } catch (e) {
        AppLogger.w(
          'MessageRepositoryImpl',
          'Failed with first endpoint format, trying fallback: $e',
        );

        // Try alternative endpoint
        final response = await _apiService.post(
          '/api/chatrooms/$chatRoomId/messages',
          data: {
            'content': content,
            'contentType': contentType.toString().split('.').last.toUpperCase(),
          },
        );
        return MessageModel.fromJson(response.data);
      }
    } catch (e) {
      AppLogger.e('MessageRepositoryImpl', 'Error sending message: $e');
      throw _handleError(e);
    }
  }

  @override
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _apiService.put(
        '/api/messages/$messageId/status',
        data: {'status': 'READ'},
      );

      // Also send via WebSocket for real-time status update
      // We need to get the message first to create a proper status update
      try {
        final response = await _apiService.get('/api/messages/$messageId');
        final message = MessageModel.fromJson(response.data);

        // Create a status update
        final statusUpdate = MessageStatusModel(
          message: message,
          status: MessageStatus.read,
          timestamp: DateTime.now(),
        );

        // Add to stream
        _statusStreamController.add(statusUpdate);
      } catch (e) {
        AppLogger.w(
          'MessageRepositoryImpl',
          'Failed to get message details for status update: $e',
        );
        // We still mark the message as read even if we can't update the stream
      }
    } catch (e) {
      AppLogger.e('MessageRepositoryImpl', 'Error marking message as read: $e');
      throw _handleError(e);
    }
  }

  @override
  Future<void> markAllMessagesAsRead(String chatRoomId) async {
    try {
      // Try multiple endpoint formats
      try {
        await _apiService.put(
          '/api/messages/status',
          data: {'chatRoomId': chatRoomId, 'status': 'READ'},
        );
        return;
      } catch (e) {
        AppLogger.w(
          'MessageRepositoryImpl',
          'Failed with first endpoint format, trying fallback: $e',
        );
      }

      // Try alternative endpoint
      await _apiService.put('/api/chatrooms/$chatRoomId/messages/read');
    } catch (e) {
      AppLogger.e(
        'MessageRepositoryImpl',
        'Error marking all messages as read: $e',
      );
      throw _handleError(e);
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      await _apiService.delete('/api/messages/$messageId');
    } catch (e) {
      AppLogger.e('MessageRepositoryImpl', 'Error deleting message: $e');
      throw _handleError(e);
    }
  }

  @override
  Stream<MessageModel> getMessageStream() {
    return _messageStreamController.stream;
  }

  @override
  Stream<MessageStatusModel> getMessageStatusStream() {
    return _statusStreamController.stream;
  }

  @override
  Future<void> sendTypingIndicator(String chatRoomId, bool isTyping) async {
    try {
      // Check WebSocket connection before sending
      if (!_webSocketService.isConnected) {
        try {
          await _webSocketService.connect();
        } catch (e) {
          AppLogger.e(
            'MessageRepositoryImpl',
            'Failed to reconnect for typing indicator: $e',
          );
          return; // Silently fail as typing indicators are not critical
        }
      }

      _webSocketService.sendTypingIndicator(
        chatRoomId: chatRoomId,
        isTyping: isTyping,
      );
    } catch (e) {
      AppLogger.e(
        'MessageRepositoryImpl',
        'Error sending typing indicator: $e',
      );
      // Don't throw typing indicator errors as they're not critical
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        final statusCode = error.response!.statusCode;
        final data = error.response!.data;

        if (statusCode == 404) {
          return Exception('Message or chat room not found');
        } else if (statusCode == 400) {
          return Exception(
            'Bad request: ${data['message'] ?? 'Unknown error'}',
          );
        } else if (statusCode == 403) {
          return Exception(
            'Access denied: You do not have permission to perform this action',
          );
        } else if (statusCode! >= 500) {
          return Exception(
            'Server error: ${data['message'] ?? 'Unknown error'}',
          );
        }

        return Exception(
          'HTTP error $statusCode: ${data['message'] ?? 'Unknown error'}',
        );
      }

      return Exception('Network error: ${error.message}');
    }

    return Exception('Unexpected error: ${error.toString()}');
  }

  // Dispose of resources
  void dispose() {
    _cancelReconnect();
    _messageStreamController.close();
    _statusStreamController.close();
  }
}
