import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/unread_message_notification.dart';
import '../utils/logger.dart';
import 'navigation_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Check if the service is initialized
  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request notification permissions first (Android 13+)
      await _requestNotificationPermissions();

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

      final initialized = await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == true) {
        // Create notification channels
        await _createNotificationChannels();

        _initialized = true;
        AppLogger.i(
          'NotificationService',
          'Local notifications initialized successfully',
        );
      } else {
        AppLogger.w(
          'NotificationService',
          'Failed to initialize local notifications',
        );
      }

      // Request permissions for Android 13+
      await _requestPermissions();
    } catch (e) {
      AppLogger.e(
        'NotificationService',
        'Error initializing notifications: $e',
      );
    }
  }

  /// Request notification permissions (Android 13+)
  static Future<void> _requestNotificationPermissions() async {
    try {
      final status = await Permission.notification.status;

      if (status.isDenied) {
        AppLogger.i(
          'NotificationService',
          'Requesting notification permissions...',
        );
        final result = await Permission.notification.request();

        if (result.isGranted) {
          AppLogger.i(
            'NotificationService',
            'Notification permissions granted',
          );
        } else {
          AppLogger.w('NotificationService', 'Notification permissions denied');
        }
      } else if (status.isGranted) {
        AppLogger.i(
          'NotificationService',
          'Notification permissions already granted',
        );
      }
    } catch (e) {
      AppLogger.e(
        'NotificationService',
        'Error requesting notification permissions: $e',
      );
    }
  }

  /// Create notification channels
  static Future<void> _createNotificationChannels() async {
    try {
      const chatChannel = AndroidNotificationChannel(
        'chat_messages',
        'Chat Messages',
        description: 'Notifications for new chat messages',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('notification'),
        enableVibration: true,
        playSound: true,
      );

      const backgroundChannel = AndroidNotificationChannel(
        'chat_background_messages',
        'Background Chat Messages',
        description: 'Notifications for background chat messages',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('notification'),
        enableVibration: true,
        playSound: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(chatChannel);

      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(backgroundChannel);

      AppLogger.i('NotificationService', 'Notification channels created');
    } catch (e) {
      AppLogger.e(
        'NotificationService',
        'Error creating notification channels: $e',
      );
    }
  }

  static Future<void> _requestPermissions() async {
    try {
      final androidPlugin =
          _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        AppLogger.i(
          'NotificationService',
          'Android notification permission granted: $granted',
        );
      }
    } catch (e) {
      AppLogger.e(
        'NotificationService',
        'Error requesting notification permissions: $e',
      );
    }
  }

  static Future<void> showUnreadMessageNotification(
    UnreadMessageNotification notification,
  ) async {
    if (!_initialized) {
      AppLogger.w(
        'NotificationService',
        'Notifications not initialized, skipping notification',
      );
      return;
    }

    try {
      final androidDetails = AndroidNotificationDetails(
        'unread_messages',
        'Unread Messages',
        channelDescription: 'Notifications for unread chat messages',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        when: notification.sentAt.millisecondsSinceEpoch,
        category: AndroidNotificationCategory.message,
        groupKey: 'chat_messages',
        setAsGroupSummary: false,
        autoCancel: true,
        ongoing: false,
        silent: false,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'chat_message',
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final title = _buildNotificationTitle(notification);
      final body = _buildNotificationBody(notification);

      await _notifications.show(
        notification.messageId,
        title,
        body,
        details,
        payload: jsonEncode({
          'roomId': notification.chatRoomId,
          'messageId': notification.messageId,
          'type': 'unread_message',
        }),
      );

      AppLogger.i(
        'NotificationService',
        'Showed notification for message ${notification.messageId} in room ${notification.chatRoomName}',
      );
    } catch (e) {
      AppLogger.e('NotificationService', 'Error showing notification: $e');
    }
  }

  static String _buildNotificationTitle(
    UnreadMessageNotification notification,
  ) {
    if (notification.isPrivateChat) {
      final senderName =
          notification.senderFullName ?? notification.senderUsername;
      return 'New message from $senderName';
    } else {
      return 'New message in ${notification.chatRoomName}';
    }
  }

  static String _buildNotificationBody(UnreadMessageNotification notification) {
    final senderName =
        notification.senderFullName ?? notification.senderUsername;

    if (notification.contentPreview != null &&
        notification.contentPreview!.isNotEmpty) {
      if (notification.isPrivateChat) {
        return notification.contentPreview!;
      } else {
        return '$senderName: ${notification.contentPreview!}';
      }
    }

    // Fallback based on content type
    switch (notification.contentType.toLowerCase()) {
      case 'image/jpeg':
      case 'image/png':
      case 'image/gif':
        return notification.isPrivateChat
            ? '📷 Photo'
            : '$senderName sent a photo';
      case 'video/mp4':
      case 'video/mpeg':
        return notification.isPrivateChat
            ? '🎥 Video'
            : '$senderName sent a video';
      case 'application/pdf':
        return notification.isPrivateChat
            ? '📄 Document'
            : '$senderName sent a document';
      default:
        return notification.isPrivateChat
            ? 'New message'
            : '$senderName sent a message';
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    try {
      if (response.payload != null) {
        final payload = jsonDecode(response.payload!);
        final roomId = payload['roomId'] as int?;
        final messageId = payload['messageId'] as int?;

        AppLogger.i(
          'NotificationService',
          'Notification tapped: roomId=$roomId, messageId=$messageId',
        );

        // Navigate to the specific chat room
        if (roomId != null) {
          NavigationService.navigateToChatRoom(roomId);
          AppLogger.i(
            'NotificationService',
            'Navigating to chat room $roomId from notification',
          );
        } else {
          AppLogger.w(
            'NotificationService',
            'Cannot navigate: roomId is null in notification payload',
          );
        }
      }
    } catch (e) {
      AppLogger.e('NotificationService', 'Error handling notification tap: $e');
    }
  }

  static Future<void> cancelNotification(int notificationId) async {
    try {
      await _notifications.cancel(notificationId);
      AppLogger.d(
        'NotificationService',
        'Cancelled notification $notificationId',
      );
    } catch (e) {
      AppLogger.e('NotificationService', 'Error cancelling notification: $e');
    }
  }

  static Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      AppLogger.i('NotificationService', 'Cancelled all notifications');
    } catch (e) {
      AppLogger.e(
        'NotificationService',
        'Error cancelling all notifications: $e',
      );
    }
  }

  static Future<void> cancelNotificationsForRoom(int roomId) async {
    try {
      // Unfortunately, flutter_local_notifications doesn't support cancelling by group
      // We would need to track notification IDs per room to implement this properly
      AppLogger.d(
        'NotificationService',
        'Cancel notifications for room $roomId requested',
      );
    } catch (e) {
      AppLogger.e(
        'NotificationService',
        'Error cancelling room notifications: $e',
      );
    }
  }

  /// Show a simple test notification (for debugging purposes)
  static Future<void> showTestNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      AppLogger.w(
        'NotificationService',
        'Notifications not initialized, skipping test notification',
      );
      return;
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'chat_messages',
        'Chat Messages',
        channelDescription: 'Test notifications',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
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

      await _notifications.show(id, title, body, details, payload: payload);

      AppLogger.i(
        'NotificationService',
        'Showed test notification: $title - $body',
      );
    } catch (e) {
      AppLogger.e('NotificationService', 'Error showing test notification: $e');
    }
  }
}
