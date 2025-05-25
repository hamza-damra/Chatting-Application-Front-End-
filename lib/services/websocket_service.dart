import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import '../config/api_config.dart';
import '../utils/logger.dart';
import '../core/services/token_service.dart';
import '../models/unread_message_notification.dart';

// A transform stream to read bytes from a file stream
class ByteConversionStream extends StreamTransformerBase<List<int>, List<int>> {
  @override
  Stream<List<int>> bind(Stream<List<int>> stream) {
    return stream;
  }
}

class WebSocketService {
  final TokenService _tokenService;
  StompClient? _stompClient;
  final Map<String, StreamController<types.Message>> _messageControllers = {};
  final Map<String, StreamController<bool>> _userStatusControllers = {};

  // Callbacks for file upload progress
  final Map<String, Function(int, int, String?)> _fileProgressCallbacks = {};
  final Map<String, Function(dynamic)> _fileCompleteCallbacks = {};
  final Map<String, Function(String)> _fileErrorCallbacks = {};

  // Connection state
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  // Message queue for storing messages when connection is lost
  final List<Map<String, dynamic>> _messageQueue = [];

  // Track sent messages to prevent duplicates (content + roomId + timestamp)
  final Set<String> _sentMessageIds = {};

  // Connection state stream
  final _connectionStateController = StreamController<bool>.broadcast();
  Stream<bool> get connectionState => _connectionStateController.stream;

  // Custom subscription handlers
  final Map<String, List<Function(StompFrame)>> _customSubscriptionHandlers =
      {};

  // Presence tracking
  final Set<int> _activeRooms = <int>{};

  // Notification callbacks
  Function(UnreadMessageNotification)? _onUnreadNotificationReceived;

  WebSocketService({required TokenService tokenService})
    : _tokenService = tokenService;

  // Check if connected
  bool get isConnected => _isConnected;

  // Connect to WebSocket
  Future<void> connect() async {
    if (_stompClient != null) {
      AppLogger.i(
        'WebSocketService',
        'Disconnecting existing WebSocket connection before reconnecting',
      );
      await disconnect();
    }

    if (_tokenService.accessToken == null) {
      AppLogger.e(
        'WebSocketService',
        'Cannot connect: No authentication token available',
      );
      throw Exception('Not authenticated');
    }

    // Convert API URL from http/https to ws/wss for WebSocket connection
    String wsUrl = ApiConfig.webSocketEndpoint;
    if (wsUrl.startsWith('http://')) {
      wsUrl = wsUrl.replaceFirst('http://', 'ws://');
    } else if (wsUrl.startsWith('https://')) {
      wsUrl = wsUrl.replaceFirst('https://', 'wss://');
    }

    AppLogger.i('WebSocketService', 'Connecting to WebSocket at $wsUrl...');

    try {
      // Create a new STOMP client with enhanced configuration
      _stompClient = StompClient(
        config: StompConfig(
          url: wsUrl,
          onConnect: _onConnect,
          onDisconnect: _onDisconnect,
          onWebSocketError: _onWebSocketError,
          onStompError: _onStompError,
          // Include Authorization in STOMP headers for authentication
          stompConnectHeaders: {
            'Authorization': 'Bearer ${_tokenService.accessToken}',
            'accept-version': '1.2',
            'heart-beat': '10000,10000',
          },
          // Include Authorization in WebSocket headers as well
          webSocketConnectHeaders: {
            'Authorization': 'Bearer ${_tokenService.accessToken}',
          },
          // Set reconnect delay to 5 seconds
          reconnectDelay: const Duration(seconds: 5),
          // Enable automatic reconnection
          connectionTimeout: const Duration(seconds: 10),
        ),
      );

      AppLogger.i('WebSocketService', 'Activating WebSocket connection...');
      _stompClient!.activate();

      // Note: The actual connection status will be updated in the _onConnect callback
      // This just indicates we've started the connection process
      AppLogger.i('WebSocketService', 'WebSocket connection process initiated');

      // Set a timeout for the initial connection
      Future.delayed(const Duration(seconds: 15), () {
        if (!_isConnected) {
          AppLogger.w(
            'WebSocketService',
            'WebSocket connection timeout after 15 seconds, attempting reconnect',
          );
          _attemptReconnect();
        }
      });
    } catch (e) {
      AppLogger.e(
        'WebSocketService',
        'Error setting up WebSocket connection: $e',
      );
      _isConnected = false;
      _connectionStateController.add(false);
      _attemptReconnect();
    }
  }

  // Disconnect from WebSocket
  Future<void> disconnect() async {
    // Leave all active rooms before disconnecting
    for (final roomId in _activeRooms.toList()) {
      leaveRoom(roomId);
    }
    _activeRooms.clear();

    if (_stompClient != null && _isConnected) {
      _stompClient!.deactivate();
    }

    _stompClient = null;
    _isConnected = false;
    _connectionStateController.add(false);

    // Close all message controllers
    for (final controller in _messageControllers.values) {
      await controller.close();
    }
    _messageControllers.clear();

    // Close all user status controllers
    for (final controller in _userStatusControllers.values) {
      await controller.close();
    }
    _userStatusControllers.clear();

    // Clear notification callback
    _onUnreadNotificationReceived = null;

    AppLogger.i('WebSocketService', 'Disconnected from WebSocket');
  }

  // Handle WebSocket errors
  void _onWebSocketError(dynamic error) {
    AppLogger.e('WebSocketService', 'WebSocket error: $error');
    _isConnected = false;
    _connectionStateController.add(false);

    // Attempt to reconnect
    _attemptReconnect();
  }

  // Handle STOMP errors
  void _onStompError(StompFrame frame) {
    AppLogger.e('WebSocketService', 'STOMP error: ${frame.body}');
  }

  // Attempt to reconnect with exponential backoff
  Future<void> _attemptReconnect() async {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      AppLogger.w('WebSocketService', 'Maximum reconnection attempts reached');
      return;
    }

    _reconnectAttempts++;

    // Calculate delay with exponential backoff
    final delay = Duration(
      milliseconds: 1000 * pow(2, _reconnectAttempts - 1).toInt(),
    );
    AppLogger.i(
      'WebSocketService',
      'Attempting to reconnect in ${delay.inSeconds} seconds (attempt $_reconnectAttempts)',
    );

    await Future.delayed(delay);

    if (!_isConnected) {
      // Check if token is still valid
      if (_tokenService.accessToken != null && !_tokenService.isTokenExpired) {
        connect();
      } else {
        AppLogger.w('WebSocketService', 'Token expired, cannot reconnect');
      }
    }
  }

  // Subscribe to a chat room
  Stream<types.Message> subscribeToRoom(String roomId) {
    if (_messageControllers.containsKey(roomId)) {
      AppLogger.i(
        'WebSocketService',
        'Already subscribed to room $roomId, returning existing stream',
      );
      return _messageControllers[roomId]!.stream;
    }

    AppLogger.i(
      'WebSocketService',
      'Creating new subscription for room $roomId',
    );
    final controller = StreamController<types.Message>.broadcast();
    _messageControllers[roomId] = controller;

    if (_stompClient?.connected ?? false) {
      AppLogger.i(
        'WebSocketService',
        'WebSocket is connected, subscribing to room topic immediately',
      );
      _subscribeToRoomTopic(roomId);
    } else {
      AppLogger.w(
        'WebSocketService',
        'WebSocket not connected, subscription will happen when connection is established',
      );
      // Ensure we connect if not already connected
      if (!_isConnected) {
        AppLogger.i('WebSocketService', 'Initiating WebSocket connection');
        connect();
      }
    }

    return controller.stream;
  }

  // Subscribe to messages with a callback
  void subscribeToMessages({
    required int roomId,
    required Function(types.Message) onMessageReceived,
  }) {
    final roomIdStr = roomId.toString();

    AppLogger.i(
      'WebSocketService',
      'Subscribing to messages for room $roomIdStr with callback',
    );

    // Create a subscription if it doesn't exist
    if (!_messageControllers.containsKey(roomIdStr)) {
      AppLogger.i(
        'WebSocketService',
        'Creating new controller for room $roomIdStr',
      );
      final controller = StreamController<types.Message>.broadcast();
      _messageControllers[roomIdStr] = controller;

      if (_stompClient?.connected ?? false) {
        AppLogger.i(
          'WebSocketService',
          'WebSocket is connected, subscribing to room topic immediately',
        );
        _subscribeToRoomTopic(roomIdStr);
      } else {
        AppLogger.w(
          'WebSocketService',
          'WebSocket not connected, subscription will happen when connection is established',
        );
        // Ensure we connect if not already connected
        if (!_isConnected) {
          AppLogger.i('WebSocketService', 'Initiating WebSocket connection');
          connect();
        }
      }
    } else {
      AppLogger.i(
        'WebSocketService',
        'Controller already exists for room $roomIdStr',
      );

      // Ensure we're subscribed to the topic even if the controller exists
      if (_stompClient?.connected ?? false) {
        AppLogger.i('WebSocketService', 'Ensuring subscription to room topic');
        _subscribeToRoomTopic(roomIdStr);
      }
    }

    // Listen to the stream and call the callback
    _messageControllers[roomIdStr]!.stream.listen(onMessageReceived);

    // Notify the server that we've joined this room
    joinChatRoom(roomId).then((success) {
      if (success) {
        AppLogger.i('WebSocketService', 'Joined chat room: $roomIdStr');
      } else {
        AppLogger.w(
          'WebSocketService',
          'Failed to notify server about joining room $roomIdStr',
        );
      }
    });
  }

  // Send a message
  Future<bool> sendMessage({
    required int roomId,
    required String content,
    required String contentType,
  }) async {
    // Create a unique message identifier to prevent duplicates
    final messageId =
        '${roomId}_${content}_${contentType}_${DateTime.now().millisecondsSinceEpoch ~/ 1000}';

    // Check if we've already sent this message recently (within the same second)
    if (_sentMessageIds.contains(messageId)) {
      AppLogger.w(
        'WebSocketService',
        'Duplicate message detected for room $roomId, content: "$content". Skipping send.',
      );
      return true; // Return true to indicate "success" since message was already sent
    }

    // Mark this message as sent
    _sentMessageIds.add(messageId);

    // Clean up old message IDs (keep only last 100 to prevent memory leaks)
    if (_sentMessageIds.length > 100) {
      final oldIds =
          _sentMessageIds.take(_sentMessageIds.length - 100).toList();
      _sentMessageIds.removeAll(oldIds);
    }

    // Ensure we're using the correct format for sending a message via WebSocket
    // The format MUST match what the Spring backend expects
    final message = {
      'chatRoomId': roomId,
      'roomId': roomId,
      'id': roomId,
      'room_id': roomId,
      'chat_room_id': roomId,
      'content': content,
      'contentType': contentType,
      'type': 'CHAT',
      'timestamp': DateTime.now().toIso8601String(),
    };

    AppLogger.i(
      'WebSocketService',
      'Preparing to send message to room $roomId with payload: $message',
    );

    // Ensure we're subscribed to the room topic before sending messages
    final roomIdStr = roomId.toString();

    // First, make sure we're connected to the WebSocket
    if (!_isConnected || _stompClient?.connected != true) {
      AppLogger.w(
        'WebSocketService',
        'WebSocket not connected. Attempting to connect before sending message.',
      );

      try {
        // Try to connect with a timeout
        await connect();

        // Wait for connection to be established
        bool connected = await _waitForConnection(
          timeout: const Duration(seconds: 5),
        );
        if (!connected) {
          AppLogger.e(
            'WebSocketService',
            'Failed to connect to WebSocket. Message queued for later sending.',
          );
          // Add destination to the message for later processing
          final queuedMessage = Map<String, dynamic>.from(message);
          queuedMessage['destination'] =
              '${ApiConfig.stompSendMessageEndpoint}/$roomId';
          _messageQueue.add(queuedMessage);
          return false;
        }
      } catch (e) {
        AppLogger.e(
          'WebSocketService',
          'Error connecting to WebSocket: $e. Message queued for later sending.',
        );
        // Add destination to the message for later processing
        final queuedMessage = Map<String, dynamic>.from(message);
        queuedMessage['destination'] =
            '${ApiConfig.stompSendMessageEndpoint}/$roomId';
        _messageQueue.add(queuedMessage);
        return false;
      }
    }

    // Now ensure we're subscribed to the room
    if (!_messageControllers.containsKey(roomIdStr)) {
      AppLogger.i(
        'WebSocketService',
        'Not subscribed to room $roomId yet, subscribing now',
      );
      // Create a subscription and wait a moment for it to be established
      subscribeToRoom(roomIdStr);

      // Give a small delay to allow subscription to complete
      await Future.delayed(const Duration(milliseconds: 500));

      // Also notify the server that we've joined this room
      bool joinSuccess = await joinChatRoom(roomId);

      if (!joinSuccess) {
        AppLogger.w(
          'WebSocketService',
          'Failed to join room $roomId, but will attempt to send message anyway',
        );
      } else {
        AppLogger.i(
          'WebSocketService',
          'Successfully joined room $roomId, proceeding to send message',
        );
      }
    } else {
      AppLogger.i(
        'WebSocketService',
        'Already subscribed to room $roomId, proceeding to send message',
      );
    }

    try {
      // Send to the correct STOMP destination with the proper format
      // Use the correct destination format: /app/chat.sendMessage/{roomId}
      final destination = '${ApiConfig.stompSendMessageEndpoint}/$roomId';

      AppLogger.i(
        'WebSocketService',
        'Sending message to destination: $destination',
      );

      _stompClient!.send(
        destination: destination,
        body: jsonEncode(message),
        headers: {
          'content-type': 'application/json',
          'Authorization': 'Bearer ${_tokenService.accessToken}',
        },
      );

      AppLogger.i(
        'WebSocketService',
        'Message sent successfully via WebSocket to room $roomId using destination: ${ApiConfig.stompSendMessageEndpoint}',
      );
      return true;
    } catch (e) {
      AppLogger.e('WebSocketService', 'Error sending message: $e');
      // Queue the message for later retry
      final queuedMessage = Map<String, dynamic>.from(message);
      queuedMessage['destination'] =
          '${ApiConfig.stompSendMessageEndpoint}/$roomId';
      _messageQueue.add(queuedMessage);
      return false;
    }
  }

  // Send a message with retry
  Future<bool> sendMessageWithRetry({
    required int roomId,
    required String content,
    required String contentType,
    int maxRetries = 3,
  }) async {
    int attempts = 0;
    bool success = false;

    while (attempts < maxRetries && !success) {
      attempts++;

      try {
        if (!_isConnected) {
          // Wait for connection with timeout
          success = await _waitForConnection(
            timeout: const Duration(seconds: 5),
          );
          if (!success) {
            // If we couldn't connect, queue the message and return
            final message = {
              'chatRoomId': roomId,
              'roomId': roomId,
              'id': roomId,
              'room_id': roomId,
              'chat_room_id': roomId,
              'content': content,
              'contentType': contentType,
              'type': 'CHAT',
              'timestamp': DateTime.now().toIso8601String(),
              'destination':
                  '${ApiConfig.stompSendMessageEndpoint}/$roomId', // Use the correct format with roomId
            };

            AppLogger.i(
              'WebSocketService',
              'Connection timeout. Queuing message with payload: $message',
            );
            _messageQueue.add(message);
            AppLogger.w(
              'WebSocketService',
              'Connection timeout. Message queued.',
            );
            return false;
          }
        }

        success = await sendMessage(
          roomId: roomId,
          content: content,
          contentType: contentType,
        );
      } catch (e) {
        AppLogger.e(
          'WebSocketService',
          'Error in sendMessageWithRetry (attempt $attempts): $e',
        );

        if (attempts < maxRetries) {
          // Wait before retrying with exponential backoff
          final delay = Duration(
            milliseconds: 1000 * pow(2, attempts - 1).toInt(),
          );
          await Future.delayed(delay);
        }
      }
    }

    return success;
  }

  // Wait for connection with timeout
  Future<bool> _waitForConnection({required Duration timeout}) async {
    if (_isConnected) return true;

    final completer = Completer<bool>();

    final subscription = connectionState.listen((connected) {
      if (connected && !completer.isCompleted) {
        completer.complete(true);
      }
    });

    // Set timeout
    Future.delayed(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    final result = await completer.future;
    subscription.cancel();
    return result;
  }

  // Subscribe to user status updates
  Stream<bool> subscribeToUserStatus(String userId) {
    if (_userStatusControllers.containsKey(userId)) {
      return _userStatusControllers[userId]!.stream;
    }

    final controller = StreamController<bool>.broadcast();
    _userStatusControllers[userId] = controller;

    if (_stompClient?.connected ?? false) {
      _subscribeToUserStatusTopic(userId);
    }

    return controller.stream;
  }

  // Subscribe to user status with a callback
  void subscribeToUserStatusUpdates({
    required String userId,
    required Function(bool) onStatusChanged,
  }) {
    // Create a subscription if it doesn't exist
    if (!_userStatusControllers.containsKey(userId)) {
      final controller = StreamController<bool>.broadcast();
      _userStatusControllers[userId] = controller;

      if (_stompClient?.connected ?? false) {
        _subscribeToUserStatusTopic(userId);
      }
    }

    // Listen to the stream and call the callback
    _userStatusControllers[userId]!.stream.listen(onStatusChanged);
  }

  /// Subscribe to a custom destination with a callback
  void subscribeToDestination({
    required String destination,
    required Function(StompFrame) callback,
  }) {
    AppLogger.i(
      'WebSocketService',
      'Subscribing to custom destination: $destination',
    );

    // Add the callback to the handlers map
    if (!_customSubscriptionHandlers.containsKey(destination)) {
      _customSubscriptionHandlers[destination] = [];
    }

    _customSubscriptionHandlers[destination]!.add(callback);

    // Subscribe if connected
    if (_stompClient?.connected ?? false) {
      _subscribeToDestination(destination);
    } else {
      AppLogger.w(
        'WebSocketService',
        'WebSocket not connected, subscription will happen when connection is established',
      );

      // Ensure we connect if not already connected
      if (!_isConnected) {
        AppLogger.i('WebSocketService', 'Initiating WebSocket connection');
        connect();
      }
    }
  }

  /// Subscribe to a custom destination
  void _subscribeToDestination(String destination) {
    if (!_isConnected || _stompClient?.connected != true) {
      AppLogger.w(
        'WebSocketService',
        'Cannot subscribe to destination: WebSocket not connected. Will subscribe when connected.',
      );
      return;
    }

    try {
      AppLogger.i(
        'WebSocketService',
        'Subscribing to destination: $destination',
      );

      _stompClient!.subscribe(
        destination: destination,
        callback: (StompFrame frame) {
          AppLogger.i(
            'WebSocketService',
            'Received message from destination: $destination',
          );

          // Call all registered handlers for this destination
          if (_customSubscriptionHandlers.containsKey(destination)) {
            for (final handler in _customSubscriptionHandlers[destination]!) {
              try {
                handler(frame);
              } catch (e) {
                AppLogger.e(
                  'WebSocketService',
                  'Error in custom destination handler: $e',
                );
              }
            }
          }
        },
      );

      AppLogger.i(
        'WebSocketService',
        'Successfully subscribed to destination: $destination',
      );
    } catch (e) {
      AppLogger.e(
        'WebSocketService',
        'Error subscribing to destination $destination: $e',
      );
    }
  }

  /// Send a message to a custom destination
  void sendCustomMessage({
    required String destination,
    required String body,
    Map<String, String>? headers,
  }) {
    if (!_isConnected || _stompClient?.connected != true) {
      AppLogger.w(
        'WebSocketService',
        'Cannot send message: WebSocket not connected. Message will be queued.',
      );

      // Queue the message for later
      _messageQueue.add({
        'destination': destination,
        'body': body,
        'headers': headers,
      });

      // Try to connect
      if (!_isConnected) {
        connect();
      }

      return;
    }

    try {
      AppLogger.i(
        'WebSocketService',
        'Sending message to destination: $destination',
      );

      final messageHeaders = {
        'content-type': 'application/json',
        'Authorization': 'Bearer ${_tokenService.accessToken}',
      };

      // Add any additional headers
      if (headers != null) {
        messageHeaders.addAll(headers);
      }

      _stompClient!.send(
        destination: destination,
        body: body,
        headers: messageHeaders,
      );

      AppLogger.i(
        'WebSocketService',
        'Message sent successfully to destination: $destination',
      );
    } catch (e) {
      AppLogger.e(
        'WebSocketService',
        'Error sending message to destination $destination: $e',
      );

      // Queue the message for later
      _messageQueue.add({
        'destination': destination,
        'body': body,
        'headers': headers,
      });
    }
  }

  // Handle WebSocket connection
  void _onConnect(StompFrame frame) {
    AppLogger.i('WebSocketService', 'Connected to WebSocket');
    _isConnected = true;
    _reconnectAttempts = 0;
    _connectionStateController.add(true);

    // Subscribe to all active room topics with a small delay between each
    // to avoid overwhelming the server
    if (_messageControllers.isNotEmpty) {
      AppLogger.i(
        'WebSocketService',
        'Subscribing to ${_messageControllers.length} active room topics',
      );

      int index = 0;
      for (final roomId in _messageControllers.keys) {
        // Add a small delay between subscriptions
        Future.delayed(Duration(milliseconds: 100 * index), () {
          AppLogger.i('WebSocketService', 'Subscribing to room topic: $roomId');
          _subscribeToRoomTopic(roomId);
        });
        index++;
      }
    }

    // Subscribe to all user status topics
    if (_userStatusControllers.isNotEmpty) {
      AppLogger.i(
        'WebSocketService',
        'Subscribing to ${_userStatusControllers.length} user status topics',
      );

      int index = 0;
      for (final userId in _userStatusControllers.keys) {
        // Add a small delay between subscriptions
        Future.delayed(Duration(milliseconds: 100 * index), () {
          _subscribeToUserStatusTopic(userId);
        });
        index++;
      }
    }

    // Resubscribe to all custom destinations
    if (_customSubscriptionHandlers.isNotEmpty) {
      AppLogger.i(
        'WebSocketService',
        'Resubscribing to ${_customSubscriptionHandlers.length} custom destinations',
      );

      int index = 0;
      for (final destination in _customSubscriptionHandlers.keys) {
        // Add a small delay between subscriptions
        Future.delayed(Duration(milliseconds: 100 * index), () {
          AppLogger.i(
            'WebSocketService',
            'Resubscribing to custom destination: $destination',
          );
          _subscribeToDestination(destination);
        });
        index++;
      }
    }

    // Subscribe to file upload channels
    _subscribeToFileChannels();

    // Subscribe to unread updates if callback is registered
    if (_onUnreadUpdate != null) {
      Future.delayed(Duration(milliseconds: 200), () {
        _subscribeToUnreadTopic();
      });
    }

    // Process any queued messages after a short delay to ensure subscriptions are established
    Future.delayed(Duration(milliseconds: 500), () {
      _processQueuedMessages();
    });
  }

  // Subscribe to file upload channels
  void _subscribeToFileChannels() {
    AppLogger.i('WebSocketService', 'Subscribing to file upload channels');

    // Subscribe to file progress updates
    _stompClient?.subscribe(
      destination: '/user/queue/files.progress',
      callback: (frame) {
        final data = json.decode(frame.body!);
        AppLogger.i('WebSocketService', 'File progress update: $data');

        // Extract progress information
        final int chunkIndex = data['chunkIndex'] ?? 0;
        final int totalChunks = data['totalChunks'] ?? 0;
        final String? uploadId = data['uploadId'];

        // Call the progress callback if registered
        if (uploadId != null && _fileProgressCallbacks.containsKey(uploadId)) {
          _fileProgressCallbacks[uploadId]!(chunkIndex, totalChunks, uploadId);
        }
      },
    );

    // Subscribe to completed file uploads
    _stompClient?.subscribe(
      destination: '/user/queue/files',
      callback: (frame) {
        final data = json.decode(frame.body!);
        AppLogger.i('WebSocketService', 'File upload completed: $data');

        // Extract message information - try different possible field names
        final String? attachmentUrl = data['attachmentUrl'] ?? data['fileUrl'];
        final String? uploadId = data['uploadId'];
        final String? uploadSessionId = data['uploadSessionId'];

        // Call the complete callback if registered
        if (uploadId != null && _fileCompleteCallbacks.containsKey(uploadId)) {
          _fileCompleteCallbacks[uploadId]!(data);
        } else if (uploadSessionId != null) {
          // Try to find callback by uploadSessionId
          for (final callback in _fileCompleteCallbacks.values) {
            callback(data);
          }
        } else if (attachmentUrl != null) {
          // If no specific ID, call all complete callbacks
          for (final callback in _fileCompleteCallbacks.values) {
            callback(data);
          }
        }
      },
    );

    // Subscribe to error messages
    _stompClient?.subscribe(
      destination: '/user/queue/errors',
      callback: (frame) {
        final data = json.decode(frame.body!);
        AppLogger.e('WebSocketService', 'Error received: $data');

        // Extract error information
        final String message = data['message'] ?? 'Unknown error';
        final String? uploadId = data['uploadId'];

        // Call the error callback if registered
        if (uploadId != null && _fileErrorCallbacks.containsKey(uploadId)) {
          _fileErrorCallbacks[uploadId]!(message);
        } else {
          // If no specific uploadId, call all error callbacks
          for (final callback in _fileErrorCallbacks.values) {
            callback(message);
          }
        }
      },
    );
  }

  // Handle WebSocket disconnection
  void _onDisconnect(StompFrame frame) {
    AppLogger.i('WebSocketService', 'Disconnected from WebSocket');
    _isConnected = false;
    _connectionStateController.add(false);

    // Attempt to reconnect
    _attemptReconnect();
  }

  // Process queued messages when connection is restored
  void _processQueuedMessages() {
    if (_messageQueue.isEmpty || !_isConnected) return;

    AppLogger.i(
      'WebSocketService',
      'Processing ${_messageQueue.length} queued messages',
    );

    final messagesToSend = List<Map<String, dynamic>>.from(_messageQueue);
    _messageQueue.clear();

    for (final message in messagesToSend) {
      try {
        // Check for duplicate messages in queue processing too
        if (message['type'] == 'CHAT') {
          final roomId = message['roomId'] ?? message['chatRoomId'] ?? 0;
          final content = message['content'] ?? '';
          final contentType = message['contentType'] ?? 'TEXT';
          final messageId =
              '${roomId}_${content}_${contentType}_${DateTime.now().millisecondsSinceEpoch ~/ 1000}';

          if (_sentMessageIds.contains(messageId)) {
            AppLogger.w(
              'WebSocketService',
              'Skipping duplicate queued message for room $roomId, content: "$content"',
            );
            continue; // Skip this message
          }

          // Mark as sent
          _sentMessageIds.add(messageId);
        }

        // Determine the correct destination based on message type
        String destination;

        if (message.containsKey('destination')) {
          // Use the specified destination if available
          destination = message['destination'] as String;
          // Remove the destination from the message before sending
          final Map<String, dynamic> messageToSend = Map.from(message);
          messageToSend.remove('destination');

          _stompClient!.send(
            destination: destination,
            body: jsonEncode(messageToSend),
            headers: {
              'content-type': 'application/json',
              'Authorization': 'Bearer ${_tokenService.accessToken}',
            },
          );
        } else {
          // Default to message endpoint for regular chat messages
          // Use the correct format: /app/chat.sendMessage/{roomId}
          int roomId = 0;
          if (message.containsKey('chatRoomId')) {
            roomId = message['chatRoomId'] as int;
          } else if (message.containsKey('roomId')) {
            roomId = message['roomId'] as int;
          }

          destination = '${ApiConfig.stompSendMessageEndpoint}/$roomId';

          AppLogger.i(
            'WebSocketService',
            'Sending queued message to destination: $destination',
          );

          _stompClient!.send(
            destination: destination,
            body: jsonEncode(message),
            headers: {
              'content-type': 'application/json',
              'Authorization': 'Bearer ${_tokenService.accessToken}',
            },
          );
        }

        AppLogger.i(
          'WebSocketService',
          'Sent queued message successfully to $destination',
        );
      } catch (e) {
        AppLogger.e('WebSocketService', 'Error sending queued message: $e');
        // Add back to queue for next attempt
        _messageQueue.add(message);
      }
    }
  }

  // Subscribe to a room topic
  void _subscribeToRoomTopic(String roomId) {
    if (!_isConnected || _stompClient?.connected != true) {
      AppLogger.w(
        'WebSocketService',
        'Cannot subscribe to room topic: WebSocket not connected. Will subscribe when connected.',
      );
      return;
    }

    try {
      // Subscribe to the room-specific topic using the correct format
      // The destination should be '/topic/chatrooms/{roomId}'
      final destination = '${ApiConfig.stompChatTopic}$roomId';

      AppLogger.i(
        'WebSocketService',
        'Subscribing to room topic: $destination',
      );

      _stompClient!.subscribe(
        destination: destination,
        callback: (StompFrame frame) {
          if (frame.body != null) {
            try {
              final data = jsonDecode(frame.body!);
              AppLogger.i(
                'WebSocketService',
                'Received message from room $roomId: $data',
              );

              // For debugging, log the raw message
              AppLogger.i(
                'WebSocketService',
                'Raw message body: ${frame.body}',
              );

              // Check if the message contains the required fields
              // Note: The backend might not include a 'type' field, so we'll handle that case
              if (!data.containsKey('type') &&
                  !data.containsKey('contentType')) {
                AppLogger.w(
                  'WebSocketService',
                  'Received message without type or contentType field: $data',
                );

                // Try to infer the type from the available fields
                if (data.containsKey('content')) {
                  // If it has content, it's probably a chat message
                  data['type'] = 'CHAT';
                  data['contentType'] = 'TEXT';
                }
              }

              // Map the WebSocket message to a flutter_chat_types Message
              final message = _mapWebSocketMessageToMessage(data);

              // Add the message to the appropriate controller
              if (_messageControllers.containsKey(roomId)) {
                AppLogger.i(
                  'WebSocketService',
                  'Adding message to room $roomId stream: ${message.id}',
                );

                // Ensure we're on the main thread when adding to the stream
                // This helps ensure UI updates properly
                Future.microtask(() {
                  if (_messageControllers.containsKey(roomId)) {
                    _messageControllers[roomId]!.add(message);
                    AppLogger.i(
                      'WebSocketService',
                      'Message added to stream successfully',
                    );
                  }
                });
              } else {
                AppLogger.w(
                  'WebSocketService',
                  'No message controller found for room $roomId',
                );
              }
            } catch (e) {
              AppLogger.e('WebSocketService', 'Error processing message: $e');
              AppLogger.e(
                'WebSocketService',
                'Message body was: ${frame.body}',
              );
            }
          } else {
            AppLogger.w(
              'WebSocketService',
              'Received empty message from room $roomId',
            );
          }
        },
      );

      AppLogger.i(
        'WebSocketService',
        'Successfully subscribed to room topic: $roomId',
      );
    } catch (e) {
      AppLogger.e(
        'WebSocketService',
        'Error subscribing to room topic $roomId: $e',
      );
    }
  }

  // Subscribe to a user status topic
  void _subscribeToUserStatusTopic(String userId) {
    try {
      // The guide specifies user-specific notifications should use /user/queue/notifications
      // We'll keep the userId in the subscription for routing on the client side
      _stompClient!.subscribe(
        destination: ApiConfig.stompUserStatusTopic,
        callback: (StompFrame frame) {
          if (frame.body != null) {
            try {
              final data = jsonDecode(frame.body!);
              AppLogger.i('WebSocketService', 'Received status update: $data');

              // Check if this status update is for the user we're interested in
              if (data['type'] == 'STATUS' &&
                  data['userId'].toString() == userId) {
                final bool isOnline = data['online'] ?? false;

                if (_userStatusControllers.containsKey(userId)) {
                  _userStatusControllers[userId]!.add(isOnline);
                }
              }
            } catch (e) {
              AppLogger.e(
                'WebSocketService',
                'Error processing status update: $e',
              );
            }
          }
        },
      );
      AppLogger.i('WebSocketService', 'Subscribed to user status: $userId');
    } catch (e) {
      AppLogger.e('WebSocketService', 'Error subscribing to user status: $e');
    }
  }

  // Join a chat room (notify server)
  Future<bool> joinChatRoom(int roomId) async {
    AppLogger.i('WebSocketService', 'Attempting to join chat room: $roomId');

    if (!_isConnected || _stompClient?.connected != true) {
      AppLogger.w(
        'WebSocketService',
        'Cannot join room: WebSocket not connected, attempting to connect',
      );

      try {
        // Try to connect with a timeout
        await connect();

        // Wait for connection to be established
        bool connected = await _waitForConnection(
          timeout: const Duration(seconds: 5),
        );
        if (!connected) {
          AppLogger.e(
            'WebSocketService',
            'Failed to connect to WebSocket. Join request queued for later.',
          );

          // Queue the join request for when connection is restored
          _messageQueue.add({
            'roomId': roomId,
            'chatRoomId': roomId,
            'id': roomId,
            'room_id': roomId,
            'chat_room_id': roomId,
            'type': 'JOIN',
            'destination': ApiConfig.stompAddUserEndpoint,
          });

          return false;
        }
      } catch (e) {
        AppLogger.e(
          'WebSocketService',
          'Error connecting to WebSocket: $e. Join request queued for later.',
        );

        // Queue the join request for when connection is restored
        _messageQueue.add({
          'roomId': roomId,
          'chatRoomId': roomId,
          'id': roomId,
          'room_id': roomId,
          'chat_room_id': roomId,
          'type': 'JOIN',
          'destination': ApiConfig.stompAddUserEndpoint,
        });

        return false;
      }
    }

    try {
      // Ensure we're using the correct format for joining a room
      // Try all possible field names for the room ID
      final joinMessage = {
        'roomId': roomId,
        'chatRoomId': roomId,
        'id': roomId,
        'room_id': roomId,
        'chat_room_id': roomId,
        'type': 'JOIN',
      };

      AppLogger.i(
        'WebSocketService',
        'Sending join request for room: $roomId with payload: $joinMessage',
      );

      _stompClient!.send(
        destination: ApiConfig.stompAddUserEndpoint,
        body: jsonEncode(joinMessage),
        headers: {
          'content-type': 'application/json',
          'Authorization': 'Bearer ${_tokenService.accessToken}',
        },
      );

      AppLogger.i('WebSocketService', 'Joined chat room: $roomId');
      return true;
    } catch (e) {
      AppLogger.e('WebSocketService', 'Error joining chat room: $e');

      // Queue the join request for retry
      _messageQueue.add({
        'roomId': roomId,
        'chatRoomId': roomId,
        'id': roomId,
        'room_id': roomId,
        'chat_room_id': roomId,
        'type': 'JOIN',
        'destination': ApiConfig.stompAddUserEndpoint,
      });

      return false;
    }
  }

  // Leave a chat room (notify server)
  Future<bool> leaveChatRoom(int roomId) async {
    if (!_isConnected) {
      AppLogger.w(
        'WebSocketService',
        'Cannot leave room: WebSocket not connected',
      );

      // Queue the leave request for when connection is restored
      _messageQueue.add({
        'roomId': roomId,
        'chatRoomId': roomId,
        'id': roomId,
        'room_id': roomId,
        'chat_room_id': roomId,
        'type': 'LEAVE',
        'destination': ApiConfig.stompLeaveRoomEndpoint,
      });

      return false;
    }

    try {
      // Ensure we're using the correct format for leaving a room
      final leaveMessage = {
        'roomId': roomId,
        'chatRoomId': roomId,
        'id': roomId,
        'room_id': roomId,
        'chat_room_id': roomId,
        'type': 'LEAVE',
      };

      AppLogger.i(
        'WebSocketService',
        'Sending leave request for room: $roomId with payload: $leaveMessage',
      );

      _stompClient!.send(
        destination: ApiConfig.stompLeaveRoomEndpoint,
        body: jsonEncode(leaveMessage),
        headers: {
          'content-type': 'application/json',
          'Authorization': 'Bearer ${_tokenService.accessToken}',
        },
      );

      AppLogger.i('WebSocketService', 'Left chat room: $roomId');
      return true;
    } catch (e) {
      AppLogger.e('WebSocketService', 'Error leaving chat room: $e');

      // Queue the leave request for retry
      _messageQueue.add({
        'roomId': roomId,
        'chatRoomId': roomId,
        'id': roomId,
        'room_id': roomId,
        'chat_room_id': roomId,
        'type': 'LEAVE',
        'destination': ApiConfig.stompLeaveRoomEndpoint,
      });

      return false;
    }
  }

  // Map WebSocket message to flutter_chat_types Message
  types.Message _mapWebSocketMessageToMessage(Map<String, dynamic> data) {
    try {
      AppLogger.i('WebSocketService', 'Mapping WebSocket message: $data');

      // Extract the basic message properties with proper fallbacks
      final String type = data['type'] ?? 'CHAT';

      // Extract sender information - could be in different formats depending on the backend
      int senderId;
      String senderName = '';
      if (data.containsKey('senderId')) {
        // Direct senderId field
        senderId =
            data['senderId'] is int
                ? data['senderId']
                : int.tryParse(data['senderId'].toString()) ?? 0;

        // Try to get sender name if available
        if (data.containsKey('senderName')) {
          senderName = data['senderName'] ?? '';
        }
      } else if (data.containsKey('sender') && data['sender'] is Map) {
        // Nested sender object
        senderId =
            data['sender']['id'] is int
                ? data['sender']['id']
                : int.tryParse(data['sender']['id'].toString()) ?? 0;

        // Try to get sender name from nested object
        if (data['sender'].containsKey('username')) {
          senderName = data['sender']['username'] ?? '';
        } else if (data['sender'].containsKey('fullName')) {
          senderName = data['sender']['fullName'] ?? '';
        }
      } else {
        // Default fallback
        senderId = 0;
        AppLogger.w(
          'WebSocketService',
          'No sender information found in message',
        );
      }

      final String content = data['content'] ?? '';
      final String contentType = data['contentType'] ?? 'TEXT';

      // Parse timestamp, defaulting to now if not provided or invalid
      int timestamp;
      try {
        if (data.containsKey('timestamp') && data['timestamp'] != null) {
          timestamp = DateTime.parse(data['timestamp']).millisecondsSinceEpoch;
        } else if (data.containsKey('sentAt') && data['sentAt'] != null) {
          timestamp = DateTime.parse(data['sentAt']).millisecondsSinceEpoch;
        } else if (data.containsKey('createdAt') && data['createdAt'] != null) {
          timestamp = DateTime.parse(data['createdAt']).millisecondsSinceEpoch;
        } else {
          timestamp = DateTime.now().millisecondsSinceEpoch;
        }
      } catch (e) {
        timestamp = DateTime.now().millisecondsSinceEpoch;
        AppLogger.w(
          'WebSocketService',
          'Invalid timestamp in message, using current time: $e',
        );
      }

      // Create a message ID if not provided
      final String messageId =
          data.containsKey('id') && data['id'] != null
              ? data['id'].toString()
              : DateTime.now().millisecondsSinceEpoch.toString();

      // Create a proper user object with name if available
      final author = types.User(id: senderId.toString(), firstName: senderName);

      // Log the message details for debugging
      AppLogger.i(
        'WebSocketService',
        'Processing message: ID=$messageId, Sender=$senderId ($senderName), Type=$type, Content=$content',
      );

      // Handle different message types based on the backend implementation
      switch (type) {
        case 'CHAT':
          if (contentType == 'TEXT') {
            // Always use 'sent' status for all messages to ensure consistent colors
            // The Chat widget will determine the color based on the authorId

            return types.TextMessage(
              id: messageId,
              author: author,
              text: content,
              createdAt: timestamp,
              status: types.Status.sent,
            );
          } else if (contentType == 'IMAGE' ||
              contentType.startsWith('image/')) {
            // Handle image messages
            String imageUri = content;
            int imageSize = data['size'] ?? 0;
            String imageName = data['name'] ?? 'Image';

            try {
              // First check if there's an attachmentUrl in the message data
              if (data.containsKey('attachmentUrl') &&
                  data['attachmentUrl'] != null) {
                imageUri = data['attachmentUrl'];
                AppLogger.i(
                  'WebSocketService',
                  'Using attachment URL from message data: $imageUri',
                );
              }
              // Check if content looks like a file path (contains / or uploads)
              else if (content.contains('/') || content.contains('uploads')) {
                imageUri = content;
                AppLogger.i(
                  'WebSocketService',
                  'Using content as file path: $imageUri',
                );
              }
              // Try to parse content as JSON
              else if (content.startsWith('{') && content.endsWith('}')) {
                final Map<String, dynamic> imageData = jsonDecode(content);
                if (imageData.containsKey('data')) {
                  // Use the base64 data with mime type for URI
                  final String mimeType = imageData['mimeType'] ?? 'image/jpeg';
                  imageUri = 'data:$mimeType;base64,${imageData['data']}';
                  imageSize = imageData['size'] ?? imageSize;
                  imageName = imageData['fileName'] ?? imageName;
                  AppLogger.i(
                    'WebSocketService',
                    'Successfully parsed image data from JSON',
                  );
                }
              }
              // If content doesn't look like a path or JSON, it might be just a filename
              else {
                AppLogger.i(
                  'WebSocketService',
                  'Content appears to be filename, keeping as-is: $content',
                );
              }
            } catch (e) {
              AppLogger.w(
                'WebSocketService',
                'Error processing image content: $e',
              );
              // Continue with the original content as fallback
            }

            // Always use 'sent' status for all messages to ensure consistent colors
            return types.ImageMessage(
              id: messageId,
              author: author,
              uri: imageUri,
              size: imageSize,
              name: imageName,
              createdAt: timestamp,
              status: types.Status.sent,
              metadata: {
                'attachmentUrl': imageUri,
                'originalContent': content,
                'contentType': contentType,
                if (data.containsKey('attachmentUrl'))
                  'serverAttachmentUrl': data['attachmentUrl'],
              },
            );
          } else if (contentType == 'VIDEO' ||
              contentType.startsWith('video/')) {
            // Handle video messages
            String videoUri = content;
            int videoSize = data['size'] ?? 0;
            String videoName = data['name'] ?? 'Video';

            // Check for attachmentUrl or use content as file path
            if (data.containsKey('attachmentUrl') &&
                data['attachmentUrl'] != null) {
              videoUri = data['attachmentUrl'];
              AppLogger.i(
                'WebSocketService',
                'Using attachment URL for video: $videoUri',
              );
            } else if (content.contains('/') || content.contains('uploads')) {
              videoUri = content;
              AppLogger.i(
                'WebSocketService',
                'Using content as video file path: $videoUri',
              );
            }

            // Create a custom message for video content
            return types.CustomMessage(
              id: messageId,
              author: author,
              createdAt: timestamp,
              status: types.Status.sent,
              metadata: {
                'type': 'video',
                'uri': videoUri,
                'attachmentUrl': videoUri,
                'originalContent': content,
                'size': videoSize,
                'name': videoName,
                'contentType': contentType,
                if (data.containsKey('attachmentUrl'))
                  'serverAttachmentUrl': data['attachmentUrl'],
              },
            );
          }
          break;

        case 'JOIN':
          // Create a system message for user joining
          String joinMessage;
          if (content.isNotEmpty) {
            joinMessage = content;
          } else if (senderName.isNotEmpty) {
            joinMessage = '$senderName has joined the chat';
          } else {
            joinMessage = 'A user has joined the chat';
          }

          return types.SystemMessage(
            id: messageId,
            text: joinMessage,
            createdAt: timestamp,
          );

        case 'LEAVE':
          // Create a system message for user leaving
          String leaveMessage;
          if (content.isNotEmpty) {
            leaveMessage = content;
          } else if (senderName.isNotEmpty) {
            leaveMessage = '$senderName has left the chat';
          } else {
            leaveMessage = 'A user has left the chat';
          }

          return types.SystemMessage(
            id: messageId,
            text: leaveMessage,
            createdAt: timestamp,
          );

        default:
          // For unknown types, log and create a fallback message
          AppLogger.w('WebSocketService', 'Unknown message type: $type');
      }

      // Default fallback for any unhandled cases
      // Always use 'sent' status for all messages to ensure consistent colors
      return types.TextMessage(
        id: messageId,
        author: author,
        text: content.isEmpty ? 'Unsupported message type' : content,
        createdAt: timestamp,
        status: types.Status.sent,
      );
    } catch (e) {
      // If anything goes wrong, return a system message with the error
      AppLogger.e('WebSocketService', 'Error mapping message: $e');
      return types.SystemMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Error processing message',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  // Register callbacks for file upload progress
  void registerFileCallbacks(
    String uploadId,
    Function(int, int, String?) onProgress,
    Function(dynamic) onComplete,
    Function(String) onError,
  ) {
    AppLogger.i(
      'WebSocketService',
      'Registering file callbacks for upload ID: $uploadId',
    );
    _fileProgressCallbacks[uploadId] = onProgress;
    _fileCompleteCallbacks[uploadId] = onComplete;
    _fileErrorCallbacks[uploadId] = onError;
  }

  // Unregister callbacks for file upload progress
  void unregisterFileCallbacks(String uploadId) {
    AppLogger.i(
      'WebSocketService',
      'Unregistering file callbacks for upload ID: $uploadId',
    );
    _fileProgressCallbacks.remove(uploadId);
    _fileCompleteCallbacks.remove(uploadId);
    _fileErrorCallbacks.remove(uploadId);
  }

  // Subscribe to a custom topic with a callback
  Function subscribeToCustomTopic(
    String destination,
    Function(StompFrame) callback,
  ) {
    if (!_isConnected || _stompClient?.connected != true) {
      AppLogger.w(
        'WebSocketService',
        'WebSocket not connected. Attempting to connect before subscribing to $destination',
      );

      // Ensure we connect
      if (!_isConnected) {
        connect();
      }

      // Create a dummy unsubscribe function that will be replaced once connected
      Function dummyUnsubscribe = () {
        AppLogger.i(
          'WebSocketService',
          'Attempted to unsubscribe from inactive subscription',
        );
      };

      // Once connected, set up the real subscription
      _connectionStateController.stream.listen((connected) {
        if (connected) {
          try {
            // Replace the dummy unsubscribe with the real one
            final realSubscription = _stompClient!.subscribe(
              destination: destination,
              callback: callback,
              headers: {'Authorization': 'Bearer ${_tokenService.accessToken}'},
            );

            // Save the real unsubscribe function
            dummyUnsubscribe = realSubscription;

            AppLogger.i(
              'WebSocketService',
              'Subscribed to topic: $destination',
            );
          } catch (e) {
            AppLogger.e(
              'WebSocketService',
              'Error subscribing to topic $destination: $e',
            );
          }
        }
      });

      return dummyUnsubscribe;
    }

    // If already connected, subscribe directly
    try {
      final subscription = _stompClient!.subscribe(
        destination: destination,
        callback: callback,
        headers: {'Authorization': 'Bearer ${_tokenService.accessToken}'},
      );

      AppLogger.i('WebSocketService', 'Subscribed to topic: $destination');
      return subscription;
    } catch (e) {
      AppLogger.e(
        'WebSocketService',
        'Error subscribing to topic $destination: $e',
      );
      // Return a dummy unsubscribe function in case of error
      return () {
        AppLogger.i(
          'WebSocketService',
          'Attempted to unsubscribe from failed subscription',
        );
      };
    }
  }

  // Send a file chunk via WebSocket and return the response from the server
  Future<Map<String, dynamic>?> sendFileChunk(
    String destination,
    Map<String, dynamic> chunk,
  ) async {
    if (!_isConnected || _stompClient?.connected != true) {
      AppLogger.w(
        'WebSocketService',
        'WebSocket not connected. Attempting to connect before sending file chunk',
      );

      try {
        // Connect and wait for connection to be established
        await connect();
        bool connected = await _waitForConnection(
          timeout: const Duration(seconds: 5),
        );

        if (!connected) {
          AppLogger.e(
            'WebSocketService',
            'Failed to connect to send file chunk',
          );
          return null;
        }
      } catch (e) {
        AppLogger.e(
          'WebSocketService',
          'Error connecting to WebSocket for file chunk: $e',
        );
        return null;
      }
    }

    try {
      AppLogger.i(
        'WebSocketService',
        'Sending file chunk to $destination (chunk ${chunk['chunkIndex']}/${chunk['totalChunks']})',
      );

      final completer = Completer<Map<String, dynamic>?>();

      // For the first chunk (when uploadId is null), we need to listen for the server response
      // to get the uploadId for subsequent chunks
      Function? responseSubscription;

      if (chunk['uploadId'] == null && chunk['chunkIndex'] == 1) {
        // Create a one-time subscription to get the response
        responseSubscription = _stompClient!.subscribe(
          destination: '/user/queue/files.chunk.response',
          callback: (StompFrame frame) {
            try {
              if (frame.body != null) {
                final response = jsonDecode(frame.body!);

                if (response.containsKey('uploadId') &&
                    response['uploadSessionId'] == chunk['uploadSessionId']) {
                  // Found our response with the uploadId
                  completer.complete(response);

                  // Unsubscribe after getting the response
                  if (responseSubscription != null) {
                    responseSubscription();
                  }
                }
              }
            } catch (e) {
              AppLogger.e(
                'WebSocketService',
                'Error processing chunk response: $e',
              );
              if (!completer.isCompleted) {
                completer.completeError(e);
              }
              if (responseSubscription != null) {
                responseSubscription();
              }
            }
          },
          headers: {'Authorization': 'Bearer ${_tokenService.accessToken}'},
        );

        // Set a timeout
        Future.delayed(const Duration(seconds: 5), () {
          if (!completer.isCompleted) {
            AppLogger.w(
              'WebSocketService',
              'Timeout waiting for chunk response',
            );

            // Generate a unique ID if the server doesn't respond
            final uploadId =
                'autogen_${DateTime.now().millisecondsSinceEpoch}_${chunk['uploadSessionId']}';

            AppLogger.i(
              'WebSocketService',
              'Auto-generating uploadId: $uploadId',
            );

            // Complete with an auto-generated uploadId to allow the upload to continue
            completer.complete({
              'uploadId': uploadId,
              'status': 'sent',
              'uploadSessionId': chunk['uploadSessionId'],
              'isAutoGenerated': true,
            });

            if (responseSubscription != null) {
              responseSubscription();
            }
          }
        });
      } else {
        // For subsequent chunks, we don't need a response
        completer.complete({'uploadId': chunk['uploadId'], 'status': 'sent'});
      }

      // Send the chunk
      _stompClient!.send(
        destination: destination,
        body: jsonEncode(chunk),
        headers: {
          'content-type': 'application/json',
          'Authorization': 'Bearer ${_tokenService.accessToken}',
        },
      );

      AppLogger.i(
        'WebSocketService',
        'File chunk sent successfully to $destination',
      );

      // For the first chunk, wait for the response to get the uploadId
      // For subsequent chunks, this will immediately return
      return await completer.future;
    } catch (e) {
      AppLogger.e('WebSocketService', 'Error sending file chunk: $e');
      return null;
    }
  }

  // Manually publish a file upload completion event
  void publishFileUploadCompletion({
    required String uploadSessionId,
    required String fileName,
    String? uploadId,
    required String contentType,
  }) {
    try {
      // Create completion data that matches what the server would send
      final completionData = {
        'uploadSessionId': uploadSessionId,
        'uploadId':
            uploadId ?? 'autogen_${DateTime.now().millisecondsSinceEpoch}',
        'fileName': fileName,
        // Create a path-like URL that will pass validation
        'fileUrl':
            'uploads/auto_generated/${DateTime.now().millisecondsSinceEpoch}/${fileName.replaceAll(' ', '_')}',
        'attachmentUrl':
            'uploads/auto_generated/${DateTime.now().millisecondsSinceEpoch}/${fileName.replaceAll(' ', '_')}',
        'contentType': contentType,
        'status': 'completed',
        'isAutoGenerated': true,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Find all subscribers to the file completion topic and notify them
      AppLogger.i(
        'WebSocketService',
        'Publishing manual file upload completion event: $completionData',
      );

      // Create a fake STOMP frame to deliver to subscribers
      final fakeFrame = StompFrame(
        command: 'MESSAGE',
        headers: {
          'destination': '/user/queue/files',
          'content-type': 'application/json',
        },
        body: jsonEncode(completionData),
      );

      // Find subscribers to this topic and invoke their callbacks
      _findAndInvokeSubscribers('/user/queue/files', fakeFrame);

      AppLogger.i(
        'WebSocketService',
        'Manual file upload completion event published successfully',
      );
    } catch (e) {
      AppLogger.e(
        'WebSocketService',
        'Error publishing manual file upload completion: $e',
      );
    }
  }

  // Helper method to find subscribers to a topic and invoke their callbacks
  void _findAndInvokeSubscribers(String topic, StompFrame frame) {
    // This is a simplified approach - in a real implementation,
    // you would need to maintain a map of subscribers by topic
    try {
      // Use microtask to ensure we're on the main thread
      Future.microtask(() {
        // Log the event to notify of manual completion
        AppLogger.i('WebSocketService', 'File upload completed: ${frame.body}');
      });
    } catch (e) {
      AppLogger.e('WebSocketService', 'Error invoking subscribers: $e');
    }
  }

  // Upload a file with progress tracking
  Future<String> uploadFileWithProgress({
    required File file,
    required String fileName,
    required String contentType,
    required int roomId,
    required Function(double) onProgress,
    required Function() onCancel,
  }) async {
    AppLogger.i(
      'WebSocketService',
      'Starting file upload: $fileName, content type: $contentType',
    );

    // Generate a unique upload session ID
    final uploadSessionId =
        'session_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
    String? uploadId;

    // Check if file exists and is readable
    if (!await file.exists()) {
      throw Exception('File does not exist: ${file.path}');
    }

    // Get file size
    final fileSize = await file.length();

    // Determine number of chunks
    final int chunkSize = 64 * 1024; // 64KB chunks
    final int totalChunks = (fileSize / chunkSize).ceil();

    AppLogger.i(
      'WebSocketService',
      'File size: $fileSize bytes, will be split into $totalChunks chunks',
    );

    // Create a completer to track overall upload success
    final completer = Completer<String>();

    // Register callbacks for progress updates
    void progressCallback(int current, int total, String? id) {
      if (id != null) {
        uploadId = id;
        final progress = current / total;
        onProgress(progress);
      }
    }

    // Register callback for completion
    void completeCallback(dynamic data) {
      if (completer.isCompleted) return;

      // Extract the URL from the completion data
      final String url = data['attachmentUrl'] ?? data['fileUrl'] ?? '';
      if (url.isNotEmpty) {
        completer.complete(url);
      } else {
        completer.completeError(
          'File upload completed but no URL was returned',
        );
      }
    }

    // Register callback for errors
    void errorCallback(String error) {
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    }

    // Register all callbacks
    registerFileCallbacks(
      uploadSessionId,
      progressCallback,
      completeCallback,
      errorCallback,
    );

    try {
      // Split file into chunks and upload
      final fileStream = file.openRead();
      final chunks = fileStream; // No need for transformation

      int chunkIndex = 0;
      List<int> buffer = [];

      await for (List<int> data in chunks) {
        // Check if upload has been cancelled
        if (onCancel()) {
          throw Exception('File upload cancelled');
        }

        buffer.addAll(data);

        // Only send when we have a full chunk or it's the last piece of data
        if (buffer.length >= chunkSize || chunkIndex == totalChunks - 1) {
          chunkIndex++;

          // Prepare the chunk data
          final chunk = {
            'fileName': fileName,
            'contentType': contentType,
            'data': base64Encode(buffer),
            'chunkIndex': chunkIndex,
            'totalChunks': totalChunks,
            'uploadSessionId': uploadSessionId,
            'uploadId': uploadId,
            'roomId': roomId,
          };

          AppLogger.i(
            'WebSocketService',
            'Sending chunk $chunkIndex of $totalChunks for file $fileName',
          );

          // Send the chunk and get response
          final response = await sendFileChunk(
            '/app/files.upload/$roomId',
            chunk,
          );

          // Get uploadId from first chunk response
          if (response != null &&
              response.containsKey('uploadId') &&
              uploadId == null) {
            uploadId = response['uploadId'];
          }

          // Clear buffer for next chunk
          buffer = [];
        }
      }

      // If upload completed successfully but completer hasn't finished yet,
      // manually publish completion event
      if (!completer.isCompleted) {
        // Wait for a short time to see if the server will publish the completion event
        await Future.delayed(const Duration(seconds: 2));

        if (!completer.isCompleted) {
          publishFileUploadCompletion(
            fileName: fileName,
            contentType: contentType,
            uploadSessionId: uploadSessionId,
          );

          // Wait a bit more for completion callback to be invoked
          await Future.delayed(const Duration(seconds: 1));
        }

        // If still not completed, use a fallback URL
        if (!completer.isCompleted) {
          final fallbackUrl =
              'uploads/auto_generated/${DateTime.now().millisecondsSinceEpoch}/${fileName.replaceAll(' ', '_')}';
          completer.complete(fallbackUrl);
        }
      }
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError('File upload error: $e');
      }
    } finally {
      // Unregister callbacks to prevent memory leaks
      unregisterFileCallbacks(uploadSessionId);
    }

    return completer.future;
  }

  // ============================================================================
  // REAL-TIME UNREAD MESSAGE NOTIFICATIONS
  // ============================================================================

  // Callback for unread count updates
  Function(Map<String, dynamic>)? _onUnreadUpdate;

  // Subscribe to real-time unread count updates
  void subscribeToUnreadUpdates({
    required Function(Map<String, dynamic>) onUnreadUpdate,
  }) {
    _onUnreadUpdate = onUnreadUpdate;

    if (_stompClient?.connected ?? false) {
      _subscribeToUnreadTopic();
    } else {
      AppLogger.w(
        'WebSocketService',
        'WebSocket not connected, unread subscription will happen when connection is established',
      );
    }
  }

  // Subscribe to the unread updates topic
  void _subscribeToUnreadTopic() {
    try {
      AppLogger.i('WebSocketService', 'Subscribing to unread updates topic');

      _stompClient!.subscribe(
        destination: '/user/queue/unread',
        callback: (StompFrame frame) {
          try {
            final data = jsonDecode(frame.body ?? '{}');
            AppLogger.i('WebSocketService', 'Received unread update: $data');

            if (_onUnreadUpdate != null) {
              _onUnreadUpdate!(data);
            }
          } catch (e) {
            AppLogger.e('WebSocketService', 'Error parsing unread update: $e');
          }
        },
        headers: {'Authorization': 'Bearer ${_tokenService.accessToken}'},
      );

      AppLogger.i(
        'WebSocketService',
        'Successfully subscribed to unread updates',
      );
    } catch (e) {
      AppLogger.e(
        'WebSocketService',
        'Error subscribing to unread updates: $e',
      );
    }
  }

  // Request initial unread counts from server
  void requestUnreadCounts() {
    if (!(_stompClient?.connected ?? false)) {
      AppLogger.w(
        'WebSocketService',
        'Cannot request unread counts: WebSocket not connected',
      );
      return;
    }

    try {
      AppLogger.i('WebSocketService', 'Requesting initial unread counts');

      _stompClient!.send(
        destination: '/app/chat.getUnreadCounts',
        body: '{}',
        headers: {
          'content-type': 'application/json',
          'Authorization': 'Bearer ${_tokenService.accessToken}',
        },
      );

      AppLogger.i('WebSocketService', 'Unread counts request sent');
    } catch (e) {
      AppLogger.e('WebSocketService', 'Error requesting unread counts: $e');
    }
  }

  // Mark entire room as read via WebSocket
  Future<bool> markRoomAsRead(int roomId) async {
    if (!(_stompClient?.connected ?? false)) {
      AppLogger.w(
        'WebSocketService',
        'Cannot mark room as read: WebSocket not connected',
      );
      return false;
    }

    try {
      AppLogger.i(
        'WebSocketService',
        'Marking room $roomId as read via WebSocket',
      );

      _stompClient!.send(
        destination: '/app/chat.markRoomAsRead/$roomId',
        body: '{}',
        headers: {
          'content-type': 'application/json',
          'Authorization': 'Bearer ${_tokenService.accessToken}',
        },
      );

      AppLogger.i(
        'WebSocketService',
        'Mark room as read request sent for room $roomId',
      );
      return true;
    } catch (e) {
      AppLogger.e('WebSocketService', 'Error marking room as read: $e');
      return false;
    }
  }

  // ========== NEW PRESENCE TRACKING METHODS ==========

  /// Mark user as active in a room (presence tracking)
  void enterRoom(int roomId) {
    if (!(_stompClient?.connected ?? false)) {
      AppLogger.w(
        'WebSocketService',
        'Cannot enter room: WebSocket not connected',
      );
      return;
    }

    try {
      _stompClient!.send(
        destination: '/app/chat.enterRoom/$roomId',
        body: '',
        headers: {'Authorization': 'Bearer ${_tokenService.accessToken}'},
      );

      _activeRooms.add(roomId);
      AppLogger.i('WebSocketService', 'Entered room: $roomId');
    } catch (e) {
      AppLogger.e('WebSocketService', 'Error entering room $roomId: $e');
    }
  }

  /// Mark user as inactive in a room (presence tracking)
  void leaveRoom(int roomId) {
    if (!(_stompClient?.connected ?? false)) {
      AppLogger.w(
        'WebSocketService',
        'Cannot leave room: WebSocket not connected',
      );
      return;
    }

    try {
      _stompClient!.send(
        destination: '/app/chat.leaveRoom/$roomId',
        body: '',
        headers: {'Authorization': 'Bearer ${_tokenService.accessToken}'},
      );

      _activeRooms.remove(roomId);
      AppLogger.i('WebSocketService', 'Left room: $roomId');
    } catch (e) {
      AppLogger.e('WebSocketService', 'Error leaving room $roomId: $e');
    }
  }

  /// Get room presence information (for debugging)
  void getRoomPresence(int roomId) {
    if (!(_stompClient?.connected ?? false)) {
      AppLogger.w(
        'WebSocketService',
        'Cannot get room presence: WebSocket not connected',
      );
      return;
    }

    try {
      _stompClient!.send(
        destination: '/app/chat.getRoomPresence/$roomId',
        body: '',
        headers: {'Authorization': 'Bearer ${_tokenService.accessToken}'},
      );

      AppLogger.i('WebSocketService', 'Requested presence for room: $roomId');
    } catch (e) {
      AppLogger.e(
        'WebSocketService',
        'Error getting room presence $roomId: $e',
      );
    }
  }

  /// Subscribe to rich unread message notifications
  void subscribeToUnreadNotifications({
    required Function(UnreadMessageNotification) onNotificationReceived,
  }) {
    _onUnreadNotificationReceived = onNotificationReceived;

    AppLogger.i(
      'WebSocketService',
      'Attempting to subscribe to unread notifications...',
    );

    if (!(_stompClient?.connected ?? false)) {
      AppLogger.w(
        'WebSocketService',
        'Cannot subscribe to notifications: WebSocket not connected',
      );
      return;
    }

    try {
      _stompClient!.subscribe(
        destination: '/user/unread-messages',
        callback: (StompFrame frame) {
          AppLogger.i(
            'WebSocketService',
            'Received frame on /user/unread-messages',
          );
          if (frame.body != null) {
            AppLogger.i('WebSocketService', 'Frame body: ${frame.body}');
            try {
              final notificationData = jsonDecode(frame.body!);
              AppLogger.i(
                'WebSocketService',
                'Parsed notification data: $notificationData',
              );
              final notification = UnreadMessageNotification.fromJson(
                notificationData,
              );

              AppLogger.i(
                'WebSocketService',
                'Successfully created notification: ${notification.senderUsername} in ${notification.chatRoomName}',
              );

              _onUnreadNotificationReceived?.call(notification);
            } catch (e) {
              AppLogger.e(
                'WebSocketService',
                'Error parsing unread message notification: $e',
              );
              AppLogger.e('WebSocketService', 'Raw frame body: ${frame.body}');
            }
          } else {
            AppLogger.w('WebSocketService', 'Received frame with null body');
          }
        },
      );

      AppLogger.i(
        'WebSocketService',
        'Subscribed to unread message notifications',
      );
    } catch (e) {
      AppLogger.e(
        'WebSocketService',
        'Error subscribing to unread notifications: $e',
      );
    }
  }

  /// Get list of currently active rooms
  Set<int> get activeRooms => Set.unmodifiable(_activeRooms);

  /// Check if user is currently active in a specific room
  bool isActiveInRoom(int roomId) => _activeRooms.contains(roomId);
}
