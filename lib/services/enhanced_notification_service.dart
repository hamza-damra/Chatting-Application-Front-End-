import 'dart:async';
import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../config/api_config.dart';
import '../core/services/token_service.dart';
import '../core/di/service_locator.dart';
import '../utils/logger.dart';

/// Enhanced notification service that properly integrates with the backend notification system
class EnhancedNotificationService {
  static EnhancedNotificationService? _instance;
  static EnhancedNotificationService get instance {
    _instance ??= EnhancedNotificationService._internal();
    return _instance!;
  }

  EnhancedNotificationService._internal();

  late final TokenService _tokenService;
  StompClient? _stompClient;
  bool _isConnected = false;
  bool _isInitialized = false;

  // Stream controllers for different notification types
  final StreamController<Map<String, dynamic>> _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<List<Map<String, dynamic>>>
  _unreadNotificationsController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<int> _unreadCountController =
      StreamController<int>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  // Getters for streams
  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController.stream;
  Stream<List<Map<String, dynamic>>> get unreadNotificationsStream =>
      _unreadNotificationsController.stream;
  Stream<int> get unreadCountStream => _unreadCountController.stream;
  Stream<String> get errorStream => _errorController.stream;

  bool get isConnected => _isConnected;
  bool get isInitialized => _isInitialized;

  /// Initialize the enhanced notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      AppLogger.i(
        'EnhancedNotificationService',
        'Initializing enhanced notification service...',
      );

      // Get TokenService from service locator
      _tokenService = serviceLocator<TokenService>();
      await _tokenService.init();

      if (_tokenService.accessToken != null) {
        await _connectToWebSocket();
      }

      _isInitialized = true;
      AppLogger.i(
        'EnhancedNotificationService',
        'Enhanced notification service initialized successfully',
      );
    } catch (e) {
      AppLogger.e(
        'EnhancedNotificationService',
        'Error initializing service: $e',
      );
      rethrow;
    }
  }

  /// Connect to WebSocket with proper notification endpoints
  Future<void> _connectToWebSocket() async {
    if (_stompClient != null) {
      await disconnect();
    }

    try {
      final wsUrl = ApiConfig.webSocketEndpoint;
      AppLogger.i(
        'EnhancedNotificationService',
        'Connecting to WebSocket at $wsUrl...',
      );

      _stompClient = StompClient(
        config: StompConfig(
          url: wsUrl,
          onConnect: _onConnect,
          onDisconnect: _onDisconnect,
          onWebSocketError: _onWebSocketError,
          onStompError: _onStompError,
          stompConnectHeaders: {
            'Authorization': 'Bearer ${_tokenService.accessToken}',
            'accept-version': '1.2',
            'heart-beat': '10000,10000',
          },
          webSocketConnectHeaders: {
            'Authorization': 'Bearer ${_tokenService.accessToken}',
          },
          reconnectDelay: const Duration(seconds: 5),
          connectionTimeout: const Duration(seconds: 10),
        ),
      );

      _stompClient!.activate();
    } catch (e) {
      AppLogger.e(
        'EnhancedNotificationService',
        'Error connecting to WebSocket: $e',
      );
      rethrow;
    }
  }

  /// Handle WebSocket connection
  void _onConnect(StompFrame frame) {
    AppLogger.i(
      'EnhancedNotificationService',
      'Connected to notification WebSocket',
    );
    _isConnected = true;
    _subscribeToNotificationEndpoints();
  }

  /// Subscribe to all notification endpoints from backend documentation
  void _subscribeToNotificationEndpoints() {
    try {
      AppLogger.i(
        'EnhancedNotificationService',
        'Subscribing to notification endpoints...',
      );

      // Subscribe to real-time notifications
      _stompClient!.subscribe(
        destination: ApiConfig.stompNotificationsEndpoint,
        callback: (frame) {
          AppLogger.i(
            'EnhancedNotificationService',
            'Received notification: ${frame.body}',
          );
          _handleNotification(frame.body);
        },
        headers: {'Authorization': 'Bearer ${_tokenService.accessToken}'},
      );

      // Subscribe to unread notifications list
      _stompClient!.subscribe(
        destination: ApiConfig.stompUnreadNotificationsEndpoint,
        callback: (frame) {
          AppLogger.i(
            'EnhancedNotificationService',
            'Received unread notifications: ${frame.body}',
          );
          _handleUnreadNotifications(frame.body);
        },
        headers: {'Authorization': 'Bearer ${_tokenService.accessToken}'},
      );

      // Subscribe to unread count updates
      _stompClient!.subscribe(
        destination: ApiConfig.stompUnreadCountEndpoint,
        callback: (frame) {
          AppLogger.i(
            'EnhancedNotificationService',
            'Received unread count: ${frame.body}',
          );
          _handleUnreadCount(frame.body);
        },
        headers: {'Authorization': 'Bearer ${_tokenService.accessToken}'},
      );

      // Subscribe to error notifications
      _stompClient!.subscribe(
        destination: ApiConfig.stompNotificationErrorEndpoint,
        callback: (frame) {
          AppLogger.w(
            'EnhancedNotificationService',
            'Received error: ${frame.body}',
          );
          _handleError(frame.body);
        },
        headers: {'Authorization': 'Bearer ${_tokenService.accessToken}'},
      );

      // Subscribe to read-all confirmations
      _stompClient!.subscribe(
        destination: ApiConfig.stompReadAllConfirmationEndpoint,
        callback: (frame) {
          AppLogger.i(
            'EnhancedNotificationService',
            'Received read-all confirmation: ${frame.body}',
          );
          _handleReadAllConfirmation(frame.body);
        },
        headers: {'Authorization': 'Bearer ${_tokenService.accessToken}'},
      );

      // Also subscribe to legacy endpoints for backward compatibility
      _subscribeToLegacyEndpoints();

      // Request initial unread count and notifications
      _requestInitialData();

      AppLogger.i(
        'EnhancedNotificationService',
        'Successfully subscribed to all notification endpoints',
      );
    } catch (e) {
      AppLogger.e(
        'EnhancedNotificationService',
        'Error subscribing to notification endpoints: $e',
      );
    }
  }

  /// Subscribe to legacy endpoints for backward compatibility
  void _subscribeToLegacyEndpoints() {
    try {
      // Legacy unread messages endpoint
      _stompClient!.subscribe(
        destination: ApiConfig.stompUnreadMessagesEndpoint,
        callback: (frame) {
          AppLogger.i(
            'EnhancedNotificationService',
            'Received legacy unread message: ${frame.body}',
          );
          _handleLegacyUnreadMessage(frame.body);
        },
        headers: {'Authorization': 'Bearer ${_tokenService.accessToken}'},
      );

      // Legacy user status topic
      _stompClient!.subscribe(
        destination: ApiConfig.stompUserStatusTopic,
        callback: (frame) {
          AppLogger.i(
            'EnhancedNotificationService',
            'Received legacy user status: ${frame.body}',
          );
          _handleLegacyUserStatus(frame.body);
        },
        headers: {'Authorization': 'Bearer ${_tokenService.accessToken}'},
      );

      // Legacy unread topic
      _stompClient!.subscribe(
        destination: ApiConfig.stompUnreadTopic,
        callback: (frame) {
          AppLogger.i(
            'EnhancedNotificationService',
            'Received legacy unread: ${frame.body}',
          );
          _handleLegacyUnread(frame.body);
        },
        headers: {'Authorization': 'Bearer ${_tokenService.accessToken}'},
      );
    } catch (e) {
      AppLogger.e(
        'EnhancedNotificationService',
        'Error subscribing to legacy endpoints: $e',
      );
    }
  }

  /// Request initial data after connection
  void _requestInitialData() {
    try {
      // Request initial unread count
      _stompClient!.send(
        destination: ApiConfig.stompGetUnreadNotificationCountEndpoint,
        headers: {'Authorization': 'Bearer ${_tokenService.accessToken}'},
      );

      // Request initial unread notifications
      _stompClient!.send(
        destination: ApiConfig.stompGetUnreadNotificationsEndpoint,
        headers: {'Authorization': 'Bearer ${_tokenService.accessToken}'},
      );

      AppLogger.i(
        'EnhancedNotificationService',
        'Requested initial notification data',
      );
    } catch (e) {
      AppLogger.e(
        'EnhancedNotificationService',
        'Error requesting initial data: $e',
      );
    }
  }

  /// Handle incoming notification
  void _handleNotification(String? body) {
    if (body == null) return;

    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      _notificationController.add(data);

      // Also trigger unread count update
      _requestUnreadCount();
    } catch (e) {
      AppLogger.e(
        'EnhancedNotificationService',
        'Error handling notification: $e',
      );
    }
  }

  /// Handle unread notifications list
  void _handleUnreadNotifications(String? body) {
    if (body == null) return;

    try {
      final data = jsonDecode(body);
      if (data is List) {
        _unreadNotificationsController.add(
          List<Map<String, dynamic>>.from(data),
        );
      }
    } catch (e) {
      AppLogger.e(
        'EnhancedNotificationService',
        'Error handling unread notifications: $e',
      );
    }
  }

  /// Handle unread count update
  void _handleUnreadCount(String? body) {
    if (body == null) return;

    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final count = data['unreadCount'] as int? ?? 0;
      _unreadCountController.add(count);
    } catch (e) {
      AppLogger.e(
        'EnhancedNotificationService',
        'Error handling unread count: $e',
      );
    }
  }

  /// Handle error messages
  void _handleError(String? body) {
    if (body == null) return;

    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final error = data['message'] as String? ?? 'Unknown error';
      _errorController.add(error);
    } catch (e) {
      AppLogger.e(
        'EnhancedNotificationService',
        'Error handling error message: $e',
      );
    }
  }

  /// Handle read-all confirmation
  void _handleReadAllConfirmation(String? body) {
    if (body == null) return;

    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      AppLogger.i(
        'EnhancedNotificationService',
        'Read-all confirmation: $data',
      );

      // Update unread count to 0
      _unreadCountController.add(0);

      // Clear unread notifications list
      _unreadNotificationsController.add([]);
    } catch (e) {
      AppLogger.e(
        'EnhancedNotificationService',
        'Error handling read-all confirmation: $e',
      );
    }
  }

  /// Handle legacy unread message
  void _handleLegacyUnreadMessage(String? body) {
    if (body == null) return;

    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      // Convert legacy format to new notification format
      _notificationController.add(data);
    } catch (e) {
      AppLogger.e(
        'EnhancedNotificationService',
        'Error handling legacy unread message: $e',
      );
    }
  }

  /// Handle legacy user status
  void _handleLegacyUserStatus(String? body) {
    if (body == null) return;

    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      // Handle legacy user status updates
      AppLogger.i(
        'EnhancedNotificationService',
        'Legacy user status update: $data',
      );
    } catch (e) {
      AppLogger.e(
        'EnhancedNotificationService',
        'Error handling legacy user status: $e',
      );
    }
  }

  /// Handle legacy unread
  void _handleLegacyUnread(String? body) {
    if (body == null) return;

    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      // Handle legacy unread updates
      if (data.containsKey('unreadCount')) {
        _unreadCountController.add(data['unreadCount'] as int);
      }
    } catch (e) {
      AppLogger.e(
        'EnhancedNotificationService',
        'Error handling legacy unread: $e',
      );
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(int notificationId) async {
    if (!_isConnected || _stompClient == null) {
      AppLogger.w(
        'EnhancedNotificationService',
        'Cannot mark as read: not connected',
      );
      return;
    }

    try {
      _stompClient!.send(
        destination: ApiConfig.stompMarkNotificationAsReadEndpoint,
        body: jsonEncode({'notificationId': notificationId}),
        headers: {
          'Authorization': 'Bearer ${_tokenService.accessToken}',
          'content-type': 'application/json',
        },
      );

      AppLogger.i(
        'EnhancedNotificationService',
        'Marked notification $notificationId as read',
      );
    } catch (e) {
      AppLogger.e(
        'EnhancedNotificationService',
        'Error marking notification as read: $e',
      );
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (!_isConnected || _stompClient == null) {
      AppLogger.w(
        'EnhancedNotificationService',
        'Cannot mark all as read: not connected',
      );
      return;
    }

    try {
      _stompClient!.send(
        destination: ApiConfig.stompMarkAllNotificationsAsReadEndpoint,
        headers: {'Authorization': 'Bearer ${_tokenService.accessToken}'},
      );

      AppLogger.i(
        'EnhancedNotificationService',
        'Marked all notifications as read',
      );
    } catch (e) {
      AppLogger.e(
        'EnhancedNotificationService',
        'Error marking all notifications as read: $e',
      );
    }
  }

  /// Request current unread count
  Future<void> _requestUnreadCount() async {
    if (!_isConnected || _stompClient == null) return;

    try {
      _stompClient!.send(
        destination: ApiConfig.stompGetUnreadNotificationCountEndpoint,
        headers: {'Authorization': 'Bearer ${_tokenService.accessToken}'},
      );
    } catch (e) {
      AppLogger.e(
        'EnhancedNotificationService',
        'Error requesting unread count: $e',
      );
    }
  }

  /// Handle WebSocket disconnection
  void _onDisconnect(StompFrame frame) {
    AppLogger.w(
      'EnhancedNotificationService',
      'Disconnected from notification WebSocket',
    );
    _isConnected = false;
  }

  /// Handle WebSocket errors
  void _onWebSocketError(dynamic error) {
    AppLogger.e('EnhancedNotificationService', 'WebSocket error: $error');
    _isConnected = false;
  }

  /// Handle STOMP errors
  void _onStompError(StompFrame frame) {
    AppLogger.e('EnhancedNotificationService', 'STOMP error: ${frame.body}');
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    try {
      if (_stompClient != null) {
        _stompClient!.deactivate();
        _stompClient = null;
      }
      _isConnected = false;
      AppLogger.i(
        'EnhancedNotificationService',
        'Disconnected from notification WebSocket',
      );
    } catch (e) {
      AppLogger.e('EnhancedNotificationService', 'Error disconnecting: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _notificationController.close();
    _unreadNotificationsController.close();
    _unreadCountController.close();
    _errorController.close();
    _isInitialized = false;
  }
}
