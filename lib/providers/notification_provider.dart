import 'package:flutter/foundation.dart';
import '../models/unread_message_notification.dart';
import '../services/notification_service.dart';
import '../utils/logger.dart';

class NotificationProvider extends ChangeNotifier {
  final List<UnreadMessageNotification> _notifications = [];
  final Map<int, List<UnreadMessageNotification>> _notificationsByRoom = {};

  List<UnreadMessageNotification> get notifications =>
      List.unmodifiable(_notifications);

  List<UnreadMessageNotification> getNotificationsForRoom(int roomId) {
    return List.unmodifiable(_notificationsByRoom[roomId] ?? []);
  }

  int get totalNotificationCount => _notifications.length;

  int getNotificationCountForRoom(int roomId) {
    return _notificationsByRoom[roomId]?.length ?? 0;
  }

  void addNotification(UnreadMessageNotification notification) {
    try {
      // Add to main list (newest first)
      _notifications.insert(0, notification);

      // Add to room-specific list
      if (!_notificationsByRoom.containsKey(notification.chatRoomId)) {
        _notificationsByRoom[notification.chatRoomId] = [];
      }
      _notificationsByRoom[notification.chatRoomId]!.insert(0, notification);

      // Limit the number of stored notifications to prevent memory issues
      _limitNotifications();

      AppLogger.i(
        'NotificationProvider',
        'Added notification: ${notification.senderUsername} in ${notification.chatRoomName}',
      );

      // Notify listeners first
      notifyListeners();

      // Show local notification
      NotificationService.showUnreadMessageNotification(notification);
    } catch (e) {
      AppLogger.e('NotificationProvider', 'Error adding notification: $e');
    }
  }

  void clearNotificationsForRoom(int roomId) {
    try {
      // Remove from room-specific list
      final roomNotifications = _notificationsByRoom[roomId] ?? [];
      _notificationsByRoom.remove(roomId);

      // Remove from main list
      _notifications.removeWhere((n) => n.chatRoomId == roomId);

      if (roomNotifications.isNotEmpty) {
        AppLogger.i(
          'NotificationProvider',
          'Cleared ${roomNotifications.length} notifications for room $roomId',
        );
        notifyListeners();

        // Cancel local notifications for this room
        NotificationService.cancelNotificationsForRoom(roomId);
      }
    } catch (e) {
      AppLogger.e(
        'NotificationProvider',
        'Error clearing room notifications: $e',
      );
    }
  }

  void clearAllNotifications() {
    try {
      final count = _notifications.length;
      _notifications.clear();
      _notificationsByRoom.clear();

      if (count > 0) {
        AppLogger.i('NotificationProvider', 'Cleared all $count notifications');
        notifyListeners();

        // Cancel all local notifications
        NotificationService.cancelAllNotifications();
      }
    } catch (e) {
      AppLogger.e(
        'NotificationProvider',
        'Error clearing all notifications: $e',
      );
    }
  }

  void removeNotification(int messageId) {
    try {
      final notification = _notifications.firstWhere(
        (n) => n.messageId == messageId,
        orElse: () => throw StateError('Notification not found'),
      );

      // Remove from main list
      _notifications.removeWhere((n) => n.messageId == messageId);

      // Remove from room-specific list
      _notificationsByRoom[notification.chatRoomId]?.removeWhere(
        (n) => n.messageId == messageId,
      );

      // Clean up empty room lists
      if (_notificationsByRoom[notification.chatRoomId]?.isEmpty == true) {
        _notificationsByRoom.remove(notification.chatRoomId);
      }

      AppLogger.d(
        'NotificationProvider',
        'Removed notification for message $messageId',
      );
      notifyListeners();

      // Cancel the specific local notification
      NotificationService.cancelNotification(messageId);
    } catch (e) {
      AppLogger.e('NotificationProvider', 'Error removing notification: $e');
    }
  }

  void markNotificationAsRead(int messageId) {
    // For now, just remove the notification when marked as read
    removeNotification(messageId);
  }

  void _limitNotifications() {
    const maxNotifications = 100;
    const maxPerRoom = 20;

    // Limit total notifications
    if (_notifications.length > maxNotifications) {
      final excess = _notifications.length - maxNotifications;
      final removedNotifications = _notifications.sublist(maxNotifications);
      _notifications.removeRange(maxNotifications, _notifications.length);

      // Also remove from room-specific lists
      for (final notification in removedNotifications) {
        _notificationsByRoom[notification.chatRoomId]?.removeWhere(
          (n) => n.messageId == notification.messageId,
        );
      }

      AppLogger.d('NotificationProvider', 'Removed $excess old notifications');
    }

    // Limit per-room notifications
    for (final roomId in _notificationsByRoom.keys.toList()) {
      final roomNotifications = _notificationsByRoom[roomId]!;
      if (roomNotifications.length > maxPerRoom) {
        final excess = roomNotifications.length - maxPerRoom;
        roomNotifications.removeRange(maxPerRoom, roomNotifications.length);
        AppLogger.d(
          'NotificationProvider',
          'Removed $excess old notifications for room $roomId',
        );
      }
    }
  }

  // Get the latest notification for a room (for UI display)
  UnreadMessageNotification? getLatestNotificationForRoom(int roomId) {
    final roomNotifications = _notificationsByRoom[roomId];
    return roomNotifications?.isNotEmpty == true
        ? roomNotifications!.first
        : null;
  }

  // Check if there are any notifications from a specific sender
  bool hasNotificationsFromSender(int senderId) {
    return _notifications.any((n) => n.senderId == senderId);
  }

  // Get notifications by type
  List<UnreadMessageNotification> getNotificationsByType(
    NotificationType type,
  ) {
    return _notifications.where((n) => n.notificationType == type).toList();
  }

  // Get total unread count across all rooms (from notifications)
  int get totalUnreadCount {
    if (_notifications.isEmpty) return 0;

    // Use the totalUnreadCount from the most recent notification
    // as it represents the current state from the server
    return _notifications.first.totalUnreadCount;
  }
}
