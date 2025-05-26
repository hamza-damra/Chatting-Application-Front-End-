import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../config/api_config.dart';
import '../utils/logger.dart';

class BackgroundWebSocketService {
  static const String _portName = 'background_websocket_port';
  static const String _notificationChannelId = 'chat_background_messages';
  static const String _notificationChannelName = 'Background Chat Messages';

  static FlutterBackgroundService? _backgroundService;
  static FlutterLocalNotificationsPlugin? _localNotifications;
  static bool _initialized = false;
  static String? _authToken;
  static ReceivePort? _receivePort;

  /// Initialize background WebSocket service
  static Future<void> initialize({
    required String userId,
    required String authToken,
    Function(Map<String, dynamic>)? onMessageReceived,
  }) async {
    if (_initialized) return;

    try {
      AppLogger.i(
        'BackgroundWebSocketService',
        'Initializing background service...',
      );

      _authToken = authToken;

      // Initialize background service
      await _initializeBackgroundService();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Set up communication port
      await _setupCommunicationPort(onMessageReceived);

      _initialized = true;
      AppLogger.i(
        'BackgroundWebSocketService',
        'Background service initialized successfully',
      );
    } catch (e) {
      AppLogger.e(
        'BackgroundWebSocketService',
        'Error initializing background service: $e',
      );
    }
  }

  /// Initialize Flutter Background Service
  static Future<void> _initializeBackgroundService() async {
    try {
      _backgroundService = FlutterBackgroundService();

      await _backgroundService!.configure(
        iosConfiguration: IosConfiguration(
          autoStart: true,
          onForeground: _onStart,
          onBackground: _onIosBackground,
        ),
        androidConfiguration: AndroidConfiguration(
          onStart: _onStart,
          autoStart: true,
          isForegroundMode: false,
          autoStartOnBoot: true,
          notificationChannelId: _notificationChannelId,
          initialNotificationTitle: 'Chat Background Service',
          initialNotificationContent: 'Monitoring for new messages...',
          foregroundServiceNotificationId: 888,
        ),
      );

      AppLogger.i(
        'BackgroundWebSocketService',
        'Background service configured',
      );
    } catch (e) {
      AppLogger.e(
        'BackgroundWebSocketService',
        'Error configuring background service: $e',
      );
    }
  }

  /// Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    try {
      _localNotifications = FlutterLocalNotificationsPlugin();

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications!.initialize(settings);

      // Create notification channel
      await _createNotificationChannel();

      AppLogger.i(
        'BackgroundWebSocketService',
        'Local notifications initialized',
      );
    } catch (e) {
      AppLogger.e(
        'BackgroundWebSocketService',
        'Error initializing local notifications: $e',
      );
    }
  }

  /// Create notification channel for Android
  static Future<void> _createNotificationChannel() async {
    try {
      const channel = AndroidNotificationChannel(
        _notificationChannelId,
        _notificationChannelName,
        description: 'Notifications for background chat messages',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('notification'),
      );

      await _localNotifications!
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      AppLogger.i('BackgroundWebSocketService', 'Notification channel created');
    } catch (e) {
      AppLogger.e(
        'BackgroundWebSocketService',
        'Error creating notification channel: $e',
      );
    }
  }

  /// Set up communication port between main isolate and background service
  static Future<void> _setupCommunicationPort(
    Function(Map<String, dynamic>)? onMessageReceived,
  ) async {
    try {
      _receivePort = ReceivePort();
      IsolateNameServer.registerPortWithName(_receivePort!.sendPort, _portName);

      _receivePort!.listen((data) {
        if (data is Map<String, dynamic>) {
          AppLogger.i(
            'BackgroundWebSocketService',
            'Received message from background: $data',
          );
          if (onMessageReceived != null) {
            onMessageReceived(data);
          }
        }
      });

      AppLogger.i('BackgroundWebSocketService', 'Communication port set up');
    } catch (e) {
      AppLogger.e(
        'BackgroundWebSocketService',
        'Error setting up communication port: $e',
      );
    }
  }

  /// Start background service
  static Future<void> startService() async {
    try {
      if (_backgroundService != null) {
        await _backgroundService!.startService();
        AppLogger.i('BackgroundWebSocketService', 'Background service started');
      }
    } catch (e) {
      AppLogger.e(
        'BackgroundWebSocketService',
        'Error starting background service: $e',
      );
    }
  }

  /// Stop background service
  static Future<void> stopService() async {
    try {
      if (_backgroundService != null) {
        _backgroundService!.invoke('stop');
        AppLogger.i('BackgroundWebSocketService', 'Background service stopped');
      }
    } catch (e) {
      AppLogger.e(
        'BackgroundWebSocketService',
        'Error stopping background service: $e',
      );
    }
  }

  /// Update user authentication token
  static Future<void> updateAuthToken(String newToken) async {
    try {
      _authToken = newToken;
      if (_backgroundService != null) {
        _backgroundService!.invoke('updateToken', {'token': newToken});
        AppLogger.i(
          'BackgroundWebSocketService',
          'Auth token updated in background service',
        );
      }
    } catch (e) {
      AppLogger.e(
        'BackgroundWebSocketService',
        'Error updating auth token: $e',
      );
    }
  }

  /// Update active room (to prevent notifications for current room)
  static Future<void> updateActiveRoom(String? roomId) async {
    try {
      if (_backgroundService != null) {
        _backgroundService!.invoke('updateActiveRoom', {'roomId': roomId});
        AppLogger.i(
          'BackgroundWebSocketService',
          'Active room updated: $roomId',
        );
      }
    } catch (e) {
      AppLogger.e(
        'BackgroundWebSocketService',
        'Error updating active room: $e',
      );
    }
  }

  /// Check if the service is initialized
  static bool get isInitialized => _initialized;

  /// Test method to show a notification (for debugging)
  static Future<void> showTestNotification(Map<String, dynamic> data) async {
    try {
      await _showBackgroundNotification(data);
      AppLogger.i('BackgroundWebSocketService', 'Test notification shown');
    } catch (e) {
      AppLogger.e(
        'BackgroundWebSocketService',
        'Error showing test notification: $e',
      );
      rethrow;
    }
  }

  /// Cleanup when user logs out
  static Future<void> cleanup() async {
    try {
      await stopService();
      _receivePort?.close();
      IsolateNameServer.removePortNameMapping(_portName);
      _initialized = false;
      _authToken = null;
      AppLogger.i(
        'BackgroundWebSocketService',
        'Background service cleaned up',
      );
    } catch (e) {
      AppLogger.e(
        'BackgroundWebSocketService',
        'Error cleaning up background service: $e',
      );
    }
  }

  /// Background service entry point
  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    AppLogger.i('BackgroundWebSocketService', 'Background service started');

    // Initialize background WebSocket connection
    await _initializeBackgroundWebSocket(service);

    // Listen for service commands
    service.on('stop').listen((event) {
      service.stopSelf();
    });

    service.on('updateToken').listen((event) {
      if (event != null && event['token'] != null) {
        _authToken = event['token'];
        AppLogger.i(
          'BackgroundWebSocketService',
          'Token updated in background',
        );
      }
    });

    service.on('updateActiveRoom').listen((event) {
      // Handle active room updates
      AppLogger.i(
        'BackgroundWebSocketService',
        'Active room updated in background',
      );
    });
  }

  /// iOS background handler
  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    AppLogger.i('BackgroundWebSocketService', 'iOS background mode activated');
    return true;
  }

  /// Initialize WebSocket connection in background
  static Future<void> _initializeBackgroundWebSocket(
    ServiceInstance service,
  ) async {
    try {
      if (_authToken == null) {
        AppLogger.e(
          'BackgroundWebSocketService',
          'No auth token available for background WebSocket',
        );
        return;
      }

      String wsUrl = ApiConfig.webSocketEndpoint;
      if (wsUrl.startsWith('http://')) {
        wsUrl = wsUrl.replaceFirst('http://', 'ws://');
      } else if (wsUrl.startsWith('https://')) {
        wsUrl = wsUrl.replaceFirst('https://', 'wss://');
      }

      late StompClient stompClient;

      stompClient = StompClient(
        config: StompConfig(
          url: wsUrl,
          onConnect: (frame) {
            AppLogger.i(
              'BackgroundWebSocketService',
              'Background WebSocket connected',
            );
            _subscribeToBackgroundNotifications(stompClient);
          },
          onDisconnect: (frame) {
            AppLogger.w(
              'BackgroundWebSocketService',
              'Background WebSocket disconnected',
            );
          },
          onWebSocketError: (error) {
            AppLogger.e(
              'BackgroundWebSocketService',
              'Background WebSocket error: $error',
            );
          },
          stompConnectHeaders: {
            'Authorization': 'Bearer $_authToken',
            'accept-version': '1.2',
          },
          reconnectDelay: const Duration(seconds: 10),
        ),
      );

      stompClient.activate();
      AppLogger.i(
        'BackgroundWebSocketService',
        'Background WebSocket client activated',
      );
    } catch (e) {
      AppLogger.e(
        'BackgroundWebSocketService',
        'Error initializing background WebSocket: $e',
      );
    }
  }

  /// Subscribe to background notifications
  static void _subscribeToBackgroundNotifications(StompClient stompClient) {
    try {
      // Subscribe to new notification endpoints from backend documentation
      stompClient.subscribe(
        destination: ApiConfig.stompNotificationsEndpoint,
        callback: (frame) {
          AppLogger.i(
            'BackgroundWebSocketService',
            'Received notification from ${ApiConfig.stompNotificationsEndpoint}: ${frame.body}',
          );
          _handleBackgroundNotification(frame.body);
        },
      );

      stompClient.subscribe(
        destination: ApiConfig.stompUnreadNotificationsEndpoint,
        callback: (frame) {
          AppLogger.i(
            'BackgroundWebSocketService',
            'Received unread notifications from ${ApiConfig.stompUnreadNotificationsEndpoint}: ${frame.body}',
          );
          _handleBackgroundUnreadNotifications(frame.body);
        },
      );

      stompClient.subscribe(
        destination: ApiConfig.stompUnreadCountEndpoint,
        callback: (frame) {
          AppLogger.i(
            'BackgroundWebSocketService',
            'Received unread count from ${ApiConfig.stompUnreadCountEndpoint}: ${frame.body}',
          );
          _handleBackgroundUnreadCount(frame.body);
        },
      );

      // Subscribe to legacy endpoints for backward compatibility
      stompClient.subscribe(
        destination: ApiConfig.stompUnreadTopic,
        callback: (frame) {
          AppLogger.i(
            'BackgroundWebSocketService',
            'Received legacy unread from ${ApiConfig.stompUnreadTopic}: ${frame.body}',
          );
          _handleBackgroundUnreadUpdate(frame.body);
        },
      );

      stompClient.subscribe(
        destination: ApiConfig.stompUnreadMessagesEndpoint,
        callback: (frame) {
          AppLogger.i(
            'BackgroundWebSocketService',
            'Received legacy unread message from ${ApiConfig.stompUnreadMessagesEndpoint}: ${frame.body}',
          );
          _handleBackgroundUnreadUpdate(frame.body);
        },
      );

      stompClient.subscribe(
        destination: ApiConfig.stompUserStatusTopic,
        callback: (frame) {
          AppLogger.i(
            'BackgroundWebSocketService',
            'Received legacy user status from ${ApiConfig.stompUserStatusTopic}: ${frame.body}',
          );
          _handleBackgroundUnreadUpdate(frame.body);
        },
      );

      AppLogger.i(
        'BackgroundWebSocketService',
        'Subscribed to all background notification endpoints',
      );
    } catch (e) {
      AppLogger.e(
        'BackgroundWebSocketService',
        'Error subscribing to background notifications: $e',
      );
    }
  }

  /// Handle background unread message updates
  static void _handleBackgroundUnreadUpdate(String? messageBody) async {
    try {
      if (messageBody == null || messageBody.isEmpty) {
        AppLogger.w(
          'BackgroundWebSocketService',
          'Received empty message body',
        );
        return;
      }

      AppLogger.i(
        'BackgroundWebSocketService',
        'Processing message body: $messageBody',
      );

      final data = jsonDecode(messageBody);
      AppLogger.i(
        'BackgroundWebSocketService',
        'Parsed notification data: $data',
      );

      // Validate required fields
      if (data is Map<String, dynamic>) {
        // Show local notification
        await _showBackgroundNotification(data);

        // Send to main isolate
        final sendPort = IsolateNameServer.lookupPortByName(_portName);
        if (sendPort != null) {
          sendPort.send(data);
          AppLogger.i(
            'BackgroundWebSocketService',
            'Sent notification to main isolate',
          );
        } else {
          AppLogger.w(
            'BackgroundWebSocketService',
            'Main isolate port not found',
          );
        }
      } else {
        AppLogger.w(
          'BackgroundWebSocketService',
          'Invalid notification data format: $data',
        );
      }
    } catch (e) {
      AppLogger.e(
        'BackgroundWebSocketService',
        'Error handling background unread update: $e',
      );
    }
  }

  /// Handle new notification format from backend
  static void _handleBackgroundNotification(String? body) {
    try {
      if (body == null || body.isEmpty) {
        AppLogger.w(
          'BackgroundWebSocketService',
          'Received empty notification body',
        );
        return;
      }

      AppLogger.i(
        'BackgroundWebSocketService',
        'Processing background notification: $body',
      );

      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        // Convert backend notification format to our internal format
        final notificationData = _convertBackendNotificationFormat(data);
        _showBackgroundNotification(notificationData);
        _sendToMainIsolate(notificationData);
      }
    } catch (e) {
      AppLogger.e(
        'BackgroundWebSocketService',
        'Error handling background notification: $e',
      );
    }
  }

  /// Handle unread notifications list from backend
  static void _handleBackgroundUnreadNotifications(String? body) {
    try {
      if (body == null || body.isEmpty) return;

      AppLogger.i(
        'BackgroundWebSocketService',
        'Processing unread notifications list: $body',
      );

      final data = jsonDecode(body);
      if (data is List && data.isNotEmpty) {
        // Process the most recent unread notification for background display
        final latestNotification = data.first as Map<String, dynamic>;
        final notificationData = _convertBackendNotificationFormat(
          latestNotification,
        );
        _showBackgroundNotification(notificationData);
        _sendToMainIsolate(notificationData);
      }
    } catch (e) {
      AppLogger.e(
        'BackgroundWebSocketService',
        'Error handling unread notifications: $e',
      );
    }
  }

  /// Handle unread count update from backend
  static void _handleBackgroundUnreadCount(String? body) {
    try {
      if (body == null || body.isEmpty) return;

      AppLogger.i(
        'BackgroundWebSocketService',
        'Processing unread count: $body',
      );

      final data = jsonDecode(body);
      if (data is Map<String, dynamic> && data.containsKey('unreadCount')) {
        final count = data['unreadCount'] as int;
        AppLogger.i(
          'BackgroundWebSocketService',
          'Updated unread count: $count',
        );

        // Send count update to main isolate
        _sendToMainIsolate({'type': 'unread_count', 'count': count});
      }
    } catch (e) {
      AppLogger.e(
        'BackgroundWebSocketService',
        'Error handling unread count: $e',
      );
    }
  }

  /// Convert backend notification format to internal format
  static Map<String, dynamic> _convertBackendNotificationFormat(
    Map<String, dynamic> backendData,
  ) {
    return {
      'chatRoomId': backendData['relatedChatRoomId']?.toString() ?? '',
      'chatRoomName': backendData['relatedChatRoomName'] ?? 'Chat',
      'senderName':
          backendData['triggeredByFullName'] ??
          backendData['triggeredByUsername'] ??
          'Someone',
      'messageContent':
          backendData['content'] ?? backendData['title'] ?? 'New message',
      'unreadCount': 1,
      'type': 'chat_message',
      'notificationId': backendData['id'],
      'notificationType': backendData['notificationType'],
      'priority': backendData['priority'],
      'timestamp': backendData['createdAt'] ?? DateTime.now().toIso8601String(),
    };
  }

  /// Send data to main isolate
  static void _sendToMainIsolate(Map<String, dynamic> data) {
    try {
      final sendPort = IsolateNameServer.lookupPortByName(_portName);
      if (sendPort != null) {
        sendPort.send(data);
        AppLogger.i('BackgroundWebSocketService', 'Sent data to main isolate');
      } else {
        AppLogger.w(
          'BackgroundWebSocketService',
          'Main isolate port not found',
        );
      }
    } catch (e) {
      AppLogger.e(
        'BackgroundWebSocketService',
        'Error sending to main isolate: $e',
      );
    }
  }

  /// Show notification for background message
  static Future<void> _showBackgroundNotification(
    Map<String, dynamic> data,
  ) async {
    try {
      // Extract notification data with fallbacks
      final chatRoomName =
          data['chatRoomName'] ??
          data['roomName'] ??
          data['title'] ??
          'New Message';
      final senderName =
          data['latestMessageSender'] ??
          data['senderName'] ??
          data['sender'] ??
          'Unknown';
      final messageContent =
          data['latestMessageContent'] ??
          data['messageContent'] ??
          data['content'] ??
          data['body'] ??
          'New message received';
      final unreadCount = data['unreadCount'] ?? 1;
      final chatRoomId = data['chatRoomId'] ?? data['roomId'] ?? 0;

      AppLogger.i(
        'BackgroundWebSocketService',
        'Showing notification: $chatRoomName - $senderName: $messageContent',
      );

      const androidDetails = AndroidNotificationDetails(
        _notificationChannelId,
        _notificationChannelName,
        channelDescription: 'Notifications for background chat messages',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
        autoCancel: true,
        ongoing: false,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Generate unique notification ID
      final notificationId = chatRoomId.hashCode.abs() % 2147483647;

      await _localNotifications?.show(
        notificationId,
        unreadCount > 1 ? '$chatRoomName ($unreadCount)' : chatRoomName,
        '$senderName: $messageContent',
        details,
        payload: jsonEncode({
          'chatRoomId': chatRoomId,
          'chatRoomName': chatRoomName,
          'senderName': senderName,
          'messageContent': messageContent,
          'unreadCount': unreadCount,
          'type': 'chat_message',
        }),
      );

      AppLogger.i(
        'BackgroundWebSocketService',
        'Background notification shown successfully (ID: $notificationId)',
      );
    } catch (e) {
      AppLogger.e(
        'BackgroundWebSocketService',
        'Error showing background notification: $e',
      );
    }
  }
}
