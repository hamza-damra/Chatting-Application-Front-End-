import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/logger.dart';
import 'notification_service.dart';
import 'background_websocket_service.dart';
import 'spring_boot_push_manager.dart';
import 'notification_permission_handler.dart';
import 'enhanced_notification_service.dart';

/// Manages background notifications and app lifecycle for the chat application
class BackgroundNotificationManager with WidgetsBindingObserver {
  static BackgroundNotificationManager? _instance;
  static BackgroundNotificationManager get instance {
    _instance ??= BackgroundNotificationManager._internal();
    return _instance!;
  }

  BackgroundNotificationManager._internal();

  bool _isInitialized = false;
  bool _isInBackground = false;
  String? _currentUserId;
  String? _authToken;
  String? _activeRoomId;

  /// Initialize the background notification manager
  static Future<void> initialize({String? userId, String? authToken}) async {
    final manager = BackgroundNotificationManager.instance;
    await manager._initialize(userId: userId, authToken: authToken);
  }

  Future<void> _initialize({String? userId, String? authToken}) async {
    if (_isInitialized) return;

    try {
      AppLogger.i(
        'BackgroundNotificationManager',
        'Initializing background notification manager...',
      );

      _currentUserId = userId;
      _authToken = authToken;

      // Add this as an observer for app lifecycle changes
      WidgetsBinding.instance.addObserver(this);

      // Request notification permissions
      await _requestNotificationPermissions();

      // Initialize notification service if not already done
      if (!NotificationService.isInitialized) {
        await NotificationService.initialize();
      }

      // Initialize enhanced notification service
      await EnhancedNotificationService.instance.initialize();

      // Initialize background services if user is authenticated
      if (userId != null && authToken != null) {
        _currentUserId = userId;
        _authToken = authToken;
        await _initializeBackgroundServices(userId, authToken);
      }

      _isInitialized = true;
      AppLogger.i(
        'BackgroundNotificationManager',
        'Background notification manager initialized successfully',
      );
    } catch (e) {
      AppLogger.e(
        'BackgroundNotificationManager',
        'Error initializing background notification manager: $e',
      );
    }
  }

  /// Initialize background services for authenticated user
  Future<void> _initializeBackgroundServices(
    String userId,
    String authToken,
  ) async {
    try {
      AppLogger.i(
        'BackgroundNotificationManager',
        'Initializing background services for user: $userId (Token length: ${authToken.length})',
      );

      // Initialize Spring Boot push manager
      await SpringBootPushManager.initialize(
        userId: userId,
        authToken: authToken,
        onDeviceRegistered: (deviceId) {
          AppLogger.i(
            'BackgroundNotificationManager',
            'Device registered for push notifications: $deviceId',
          );
        },
        onMessageReceived: (messageData) {
          AppLogger.i(
            'BackgroundNotificationManager',
            'Push notification received: $messageData',
          );
          _handleBackgroundMessage(messageData);
        },
      );

      // Initialize background WebSocket service
      await BackgroundWebSocketService.initialize(
        userId: userId,
        authToken: authToken,
        onMessageReceived: (messageData) {
          AppLogger.i(
            'BackgroundNotificationManager',
            'Background WebSocket message received: $messageData',
          );
          _handleBackgroundMessage(messageData);
        },
      );

      // Start background service
      await BackgroundWebSocketService.startService();

      AppLogger.i(
        'BackgroundNotificationManager',
        'Background services initialized successfully',
      );
    } catch (e) {
      AppLogger.e(
        'BackgroundNotificationManager',
        'Error initializing background services: $e',
      );
    }
  }

  /// Request notification permissions using the comprehensive permission handler
  Future<void> _requestNotificationPermissions() async {
    try {
      AppLogger.i(
        'BackgroundNotificationManager',
        'Requesting comprehensive notification permissions...',
      );

      // Check if permissions are already granted
      final alreadyGranted =
          await NotificationPermissionHandler.areAllPermissionsGranted();
      if (alreadyGranted) {
        AppLogger.i(
          'BackgroundNotificationManager',
          'All notification permissions already granted',
        );
        return;
      }

      AppLogger.w(
        'BackgroundNotificationManager',
        'Some permissions missing, will request when context is available',
      );
    } catch (e) {
      AppLogger.e(
        'BackgroundNotificationManager',
        'Error checking notification permissions: $e',
      );
    }
  }

  /// Request permissions with context (call this from UI)
  static Future<bool> requestPermissionsWithContext(
    BuildContext context,
  ) async {
    try {
      final instance = BackgroundNotificationManager.instance;
      AppLogger.i(
        'BackgroundNotificationManager',
        'Requesting permissions for user: ${instance._currentUserId} (Auth: ${instance._authToken != null ? "Present" : "Missing"})',
      );
      return await NotificationPermissionHandler.requestAllPermissions(context);
    } catch (e) {
      AppLogger.e(
        'BackgroundNotificationManager',
        'Error requesting permissions with context: $e',
      );
      return false;
    }
  }

  /// Handle background messages
  void _handleBackgroundMessage(Map<String, dynamic> messageData) {
    try {
      // Only show notifications if app is in background or user is not in the active room
      final shouldShowNotification = _shouldShowNotification(messageData);

      if (shouldShowNotification) {
        _showBackgroundNotification(messageData);
      } else {
        AppLogger.i(
          'BackgroundNotificationManager',
          'Skipping notification - user is in active room or app is in foreground',
        );
      }
    } catch (e) {
      AppLogger.e(
        'BackgroundNotificationManager',
        'Error handling background message: $e',
      );
    }
  }

  /// Determine if notification should be shown
  bool _shouldShowNotification(Map<String, dynamic> messageData) {
    // Always show if app is in background
    if (_isInBackground) {
      AppLogger.i(
        'BackgroundNotificationManager',
        'Showing notification - app is in background (User: $_currentUserId)',
      );
      return true;
    }

    // Show if user is not in the active room where the message was sent
    final messageRoomId = messageData['chatRoomId']?.toString();
    if (messageRoomId != null && messageRoomId != _activeRoomId) {
      AppLogger.i(
        'BackgroundNotificationManager',
        'Showing notification - user not in active room (User: $_currentUserId, Room: $messageRoomId)',
      );
      return true;
    }

    AppLogger.i(
      'BackgroundNotificationManager',
      'Skipping notification - user in active room (User: $_currentUserId, Room: $_activeRoomId)',
    );
    return false;
  }

  /// Show background notification
  Future<void> _showBackgroundNotification(
    Map<String, dynamic> messageData,
  ) async {
    try {
      final chatRoomName = messageData['chatRoomName']?.toString() ?? 'Chat';
      final senderName = messageData['senderName']?.toString() ?? 'Someone';
      final messageContent =
          messageData['messageContent']?.toString() ?? 'New message';

      await NotificationService.showTestNotification(
        id: DateTime.now().millisecondsSinceEpoch % 2147483647,
        title: chatRoomName,
        body: '$senderName: $messageContent',
        payload: jsonEncode(messageData),
      );

      AppLogger.i(
        'BackgroundNotificationManager',
        'Background notification shown for room: $chatRoomName',
      );
    } catch (e) {
      AppLogger.e(
        'BackgroundNotificationManager',
        'Error showing background notification: $e',
      );
    }
  }

  /// Update user authentication info
  Future<void> updateUserAuth({
    required String userId,
    required String authToken,
  }) async {
    _currentUserId = userId;
    _authToken = authToken;

    AppLogger.i(
      'BackgroundNotificationManager',
      'Updated user auth - User ID: $userId, Token length: ${authToken.length}',
    );

    if (_isInitialized) {
      await _initializeBackgroundServices(userId, authToken);
    }
  }

  /// Update active room
  void updateActiveRoom(String? roomId) {
    _activeRoomId = roomId;
    AppLogger.i(
      'BackgroundNotificationManager',
      'Active room updated: $roomId',
    );
  }

  /// App lifecycle observer methods
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _isInBackground = false;
        AppLogger.i('BackgroundNotificationManager', 'App resumed');
        break;
      case AppLifecycleState.paused:
        _isInBackground = true;
        AppLogger.i('BackgroundNotificationManager', 'App paused');
        break;
      case AppLifecycleState.detached:
        _isInBackground = true;
        AppLogger.i('BackgroundNotificationManager', 'App detached');
        break;
      case AppLifecycleState.inactive:
        AppLogger.i('BackgroundNotificationManager', 'App inactive');
        break;
      case AppLifecycleState.hidden:
        _isInBackground = true;
        AppLogger.i('BackgroundNotificationManager', 'App hidden');
        break;
    }
  }

  /// Cleanup
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isInitialized = false;
  }
}
