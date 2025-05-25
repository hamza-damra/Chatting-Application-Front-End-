import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/unread_message_notification.dart';
import '../utils/logger.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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
        _initialized = true;
        AppLogger.i('NotificationService', 'Local notifications initialized successfully');
      } else {
        AppLogger.w('NotificationService', 'Failed to initialize local notifications');
      }

      // Request permissions for Android 13+
      await _requestPermissions();
    } catch (e) {
      AppLogger.e('NotificationService', 'Error initializing notifications: $e');
    }
  }

  static Future<void> _requestPermissions() async {
    try {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        AppLogger.i('NotificationService', 'Android notification permission granted: $granted');
      }
    } catch (e) {
      AppLogger.e('NotificationService', 'Error requesting notification permissions: $e');
    }
  }

  static Future<void> showUnreadMessageNotification(
    UnreadMessageNotification notification,
  ) async {
    if (!_initialized) {
      AppLogger.w('NotificationService', 'Notifications not initialized, skipping notification');
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

  static String _buildNotificationTitle(UnreadMessageNotification notification) {
    if (notification.isPrivateChat) {
      final senderName = notification.senderFullName ?? notification.senderUsername;
      return 'New message from $senderName';
    } else {
      return 'New message in ${notification.chatRoomName}';
    }
  }

  static String _buildNotificationBody(UnreadMessageNotification notification) {
    final senderName = notification.senderFullName ?? notification.senderUsername;
    
    if (notification.contentPreview != null && notification.contentPreview!.isNotEmpty) {
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
        return notification.isPrivateChat ? '📷 Photo' : '$senderName sent a photo';
      case 'video/mp4':
      case 'video/mpeg':
        return notification.isPrivateChat ? '🎥 Video' : '$senderName sent a video';
      case 'application/pdf':
        return notification.isPrivateChat ? '📄 Document' : '$senderName sent a document';
      default:
        return notification.isPrivateChat ? 'New message' : '$senderName sent a message';
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

        // TODO: Navigate to the specific chat room
        // This will be implemented when integrating with navigation
      }
    } catch (e) {
      AppLogger.e('NotificationService', 'Error handling notification tap: $e');
    }
  }

  static Future<void> cancelNotification(int notificationId) async {
    try {
      await _notifications.cancel(notificationId);
      AppLogger.d('NotificationService', 'Cancelled notification $notificationId');
    } catch (e) {
      AppLogger.e('NotificationService', 'Error cancelling notification: $e');
    }
  }

  static Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      AppLogger.i('NotificationService', 'Cancelled all notifications');
    } catch (e) {
      AppLogger.e('NotificationService', 'Error cancelling all notifications: $e');
    }
  }

  static Future<void> cancelNotificationsForRoom(int roomId) async {
    try {
      // Unfortunately, flutter_local_notifications doesn't support cancelling by group
      // We would need to track notification IDs per room to implement this properly
      AppLogger.d('NotificationService', 'Cancel notifications for room $roomId requested');
    } catch (e) {
      AppLogger.e('NotificationService', 'Error cancelling room notifications: $e');
    }
  }
}
