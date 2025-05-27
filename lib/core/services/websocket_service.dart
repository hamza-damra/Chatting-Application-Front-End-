import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../config/api_config.dart';
import 'package:vector/core/services/token_service.dart';
import '../../domain/models/message_model.dart';
import '../../domain/models/message_status_model.dart';
import '../../utils/logger.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final TokenService _tokenService;
  final _rawMessageController =
      StreamController<Map<String, dynamic>>.broadcast();
  bool _isConnected = false;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  // Stream controllers for messages and status updates
  final _messageStreamController = StreamController<MessageModel>.broadcast();
  final _statusStreamController =
      StreamController<MessageStatusModel>.broadcast();
  final _typingStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();

  // Getters for streams
  Stream<MessageModel> get messageStream => _messageStreamController.stream;
  Stream<MessageStatusModel> get statusStream => _statusStreamController.stream;
  Stream<Map<String, dynamic>> get typingStream =>
      _typingStreamController.stream;
  Stream<Map<String, dynamic>> get rawMessageStream =>
      _rawMessageController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  bool get isConnected => _isConnected;

  WebSocketService(this._tokenService);

  Future<void> connect() async {
    if (_isConnected) return;

    try {
      final token = await _tokenService.getAccessToken();
      if (token == null) {
        AppLogger.e('WebSocketService', 'No access token available');
        _updateConnectionStatus(false);
        return;
      }

      // Get WebSocket URL and ensure it has the right protocol
      String wsUrl = ApiConfig.webSocketEndpoint;
      if (wsUrl.startsWith('http://')) {
        wsUrl = wsUrl.replaceFirst('http://', 'ws://');
      } else if (wsUrl.startsWith('https://')) {
        wsUrl = wsUrl.replaceFirst('https://', 'wss://');
      }

      final uri = Uri.parse('$wsUrl?token=$token');
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (message) {
          try {
            final data = json.decode(message);
            _rawMessageController.add(data);
            _handleMessage(data);
          } catch (e) {
            AppLogger.e('WebSocketService', 'Error parsing message: $e');
          }
        },
        onError: (error) {
          AppLogger.e('WebSocketService', 'WebSocket error: $error');
          _handleDisconnect();
        },
        onDone: () {
          AppLogger.w('WebSocketService', 'WebSocket connection closed');
          _handleDisconnect();
        },
      );

      _isConnected = true;
      _updateConnectionStatus(true);
      _startPingTimer();
      AppLogger.i('WebSocketService', 'WebSocket connected successfully');
    } catch (e) {
      AppLogger.e('WebSocketService', 'Error connecting to WebSocket: $e');
      _handleDisconnect();
    }
  }

  void _updateConnectionStatus(bool connected) {
    if (_isConnected != connected) {
      _isConnected = connected;
      _connectionStatusController.add(connected);
    }
  }

  void _handleDisconnect() {
    _updateConnectionStatus(false);
    _stopPingTimer();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected) {
        AppLogger.i('WebSocketService', 'Attempting to reconnect...');
        connect();
      }
    });
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected) {
        sendMessage({'type': 'ping'});
      }
    });
  }

  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void sendMessage(Map<String, dynamic> message) {
    if (!_isConnected) {
      AppLogger.w(
        'WebSocketService',
        'Cannot send message: WebSocket not connected',
      );
      return;
    }

    try {
      _channel?.sink.add(json.encode(message));
    } catch (e) {
      AppLogger.e('WebSocketService', 'Error sending message: $e');
    }
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _stopPingTimer();
    await _channel?.sink.close(status.goingAway);
    _channel = null;
    _updateConnectionStatus(false);
  }

  // Handle incoming messages
  void _handleMessage(Map<String, dynamic> data) {
    final type = data['type'];

    if (type == 'MESSAGE') {
      // Handle new message
      final message = MessageModel.fromJson(data);
      _messageStreamController.add(message);
    } else if (type == 'STATUS') {
      // Handle status update
      final status = MessageStatusModel.fromJson(data);
      _statusStreamController.add(status);
    } else if (type == 'TYPING') {
      // Handle typing indicator
      _typingStreamController.add({
        'userId': data['userId'],
        'userName': data['userName'],
        'chatRoomId': data['chatRoomId'],
        'isTyping': data['isTyping'],
      });
    }
  }

  // Subscribe to messages
  void subscribeToMessages(Function(MessageModel) onMessage) {
    messageStream.listen(onMessage);
  }

  // Subscribe to status updates
  void subscribeToStatusUpdates(Function(MessageStatusModel) onStatus) {
    statusStream.listen(onStatus);
  }

  // Subscribe to typing indicators
  void subscribeToTypingIndicators(Function(Map<String, dynamic>) onTyping) {
    typingStream.listen(onTyping);
  }

  // Send a typing indicator
  void sendTypingIndicator({
    required String chatRoomId,
    required bool isTyping,
  }) {
    if (!_isConnected || _channel == null) {
      AppLogger.w(
        'WebSocketService',
        'Cannot send typing indicator: Not connected',
      );
      return;
    }

    try {
      final message = {
        'type': 'TYPING',
        'chatRoomId': chatRoomId,
        'isTyping': isTyping,
        'timestamp': DateTime.now().toIso8601String(),
      };

      _channel!.sink.add(jsonEncode(message));
      AppLogger.i(
        'WebSocketService',
        'Sent typing indicator: ${isTyping ? 'started' : 'stopped'} for room $chatRoomId',
      );
    } catch (e) {
      AppLogger.e('WebSocketService', 'Error sending typing indicator: $e');
    }
  }

  // Dispose resources
  void dispose() {
    disconnect();
    _rawMessageController.close();
    _messageStreamController.close();
    _statusStreamController.close();
    _typingStreamController.close();
    _connectionStatusController.close();
  }
}
