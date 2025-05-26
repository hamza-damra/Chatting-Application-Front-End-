import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import '../core/config/api_config.dart';
import '../utils/logger.dart';
import 'background_websocket_service.dart';

class SpringBootPushManager {
  static bool _initialized = false;
  static String? _currentUserId;
  static String? _deviceId;
  static String? _authToken;

  /// Initialize push notification manager with Spring Boot backend
  static Future<void> initialize({
    required String userId,
    required String authToken,
    Function(String)? onDeviceRegistered,
    Function(Map<String, dynamic>)? onMessageReceived,
  }) async {
    if (_initialized) return;

    try {
      AppLogger.i(
        'SpringBootPushManager',
        'Initializing Spring Boot push notifications...',
      );

      _currentUserId = userId;
      _authToken = authToken;

      // Generate unique device ID
      await _generateDeviceId();

      // Register device with Spring Boot backend
      await _registerDeviceWithBackend(userId, authToken);

      // Initialize background WebSocket service
      await BackgroundWebSocketService.initialize(
        userId: userId,
        authToken: authToken,
        onMessageReceived: onMessageReceived,
      );

      // Start background service
      await BackgroundWebSocketService.startService();

      _initialized = true;
      AppLogger.i(
        'SpringBootPushManager',
        'Spring Boot push notifications initialized successfully',
      );

      if (onDeviceRegistered != null && _deviceId != null) {
        onDeviceRegistered(_deviceId!);
      }
    } catch (e) {
      AppLogger.e(
        'SpringBootPushManager',
        'Error initializing push notifications: $e',
      );
    }
  }

  /// Generate unique device ID
  static Future<void> _generateDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceId =
            '${androidInfo.brand}_${androidInfo.model}_${androidInfo.id}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceId =
            '${iosInfo.name}_${iosInfo.model}_${iosInfo.identifierForVendor}';
      } else {
        _deviceId = 'unknown_device_${DateTime.now().millisecondsSinceEpoch}';
      }

      AppLogger.i('SpringBootPushManager', 'Generated device ID: $_deviceId');
    } catch (e) {
      AppLogger.e('SpringBootPushManager', 'Error generating device ID: $e');
      _deviceId = 'fallback_device_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Register device with Spring Boot backend
  static Future<void> _registerDeviceWithBackend(
    String userId,
    String authToken,
  ) async {
    try {
      AppLogger.i(
        'SpringBootPushManager',
        'Registering device with Spring Boot backend...',
      );

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/register-device'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'userId': userId,
          'deviceId': _deviceId,
          'platform': Platform.operatingSystem,
          'deviceInfo': {
            'platform': Platform.operatingSystem,
            'version': Platform.operatingSystemVersion,
            'isPhysicalDevice': !kIsWeb,
          },
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        AppLogger.i(
          'SpringBootPushManager',
          'Device registered successfully with Spring Boot backend',
        );
      } else {
        AppLogger.w(
          'SpringBootPushManager',
          'Failed to register device: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      AppLogger.e('SpringBootPushManager', 'Error registering device: $e');
    }
  }

  /// Update user status (online/offline) for smart notifications
  static Future<void> updateUserStatus({
    required bool isOnline,
    String? activeRoomId,
  }) async {
    try {
      AppLogger.i(
        'SpringBootPushManager',
        'Updating user status: online=$isOnline, activeRoom=$activeRoomId',
      );

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/user-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({
          'userId': _currentUserId,
          'deviceId': _deviceId,
          'isOnline': isOnline,
          'activeRoomId': activeRoomId,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        AppLogger.i(
          'SpringBootPushManager',
          'User status updated successfully',
        );

        // Update background service with active room
        await BackgroundWebSocketService.updateActiveRoom(activeRoomId);
      } else {
        AppLogger.w(
          'SpringBootPushManager',
          'Failed to update user status: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      AppLogger.e('SpringBootPushManager', 'Error updating user status: $e');
    }
  }

  /// Send notification via Spring Boot backend
  static Future<bool> sendNotification({
    required String targetUserId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      AppLogger.i(
        'SpringBootPushManager',
        'Sending notification to user: $targetUserId',
      );

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({
          'targetUserId': targetUserId,
          'title': title,
          'body': body,
          'data': data,
          'senderId': _currentUserId,
          'senderDeviceId': _deviceId,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        AppLogger.i('SpringBootPushManager', 'Notification sent successfully');
        return true;
      } else {
        AppLogger.w(
          'SpringBootPushManager',
          'Failed to send notification: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      AppLogger.e('SpringBootPushManager', 'Error sending notification: $e');
      return false;
    }
  }

  /// Send chat message notification
  static Future<bool> sendChatMessageNotification({
    required String targetUserId,
    required String chatRoomId,
    required String chatRoomName,
    required String senderName,
    required String messageContent,
    required String messageId,
  }) async {
    return await sendNotification(
      targetUserId: targetUserId,
      title: chatRoomName,
      body: '$senderName: $messageContent',
      data: {
        'type': 'chat_message',
        'chatRoomId': chatRoomId,
        'chatRoomName': chatRoomName,
        'senderId': _currentUserId,
        'senderName': senderName,
        'messageId': messageId,
        'messageContent': messageContent,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Clear all notifications for a specific chat room
  static Future<void> clearChatRoomNotifications(String chatRoomId) async {
    try {
      AppLogger.i(
        'SpringBootPushManager',
        'Clearing notifications for chat room: $chatRoomId',
      );

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/clear'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({
          'userId': _currentUserId,
          'deviceId': _deviceId,
          'chatRoomId': chatRoomId,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        AppLogger.i(
          'SpringBootPushManager',
          'Chat room notifications cleared successfully',
        );
      } else {
        AppLogger.w(
          'SpringBootPushManager',
          'Failed to clear chat room notifications: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      AppLogger.e(
        'SpringBootPushManager',
        'Error clearing chat room notifications: $e',
      );
    }
  }

  /// Update authentication token
  static Future<void> updateAuthToken(String newToken) async {
    try {
      _authToken = newToken;
      await BackgroundWebSocketService.updateAuthToken(newToken);
      AppLogger.i('SpringBootPushManager', 'Auth token updated');
    } catch (e) {
      AppLogger.e('SpringBootPushManager', 'Error updating auth token: $e');
    }
  }

  /// Get current device ID
  static String? get deviceId => _deviceId;

  /// Get current user ID
  static String? get currentUserId => _currentUserId;

  /// Check if push notifications are initialized
  static bool get isInitialized => _initialized;

  /// Cleanup when user logs out
  static Future<void> cleanup() async {
    try {
      AppLogger.i('SpringBootPushManager', 'Cleaning up push notifications...');

      if (_currentUserId != null) {
        // Update user status to offline
        await updateUserStatus(isOnline: false);
      }

      // Stop background service
      await BackgroundWebSocketService.cleanup();

      _initialized = false;
      _currentUserId = null;
      _deviceId = null;
      _authToken = null;

      AppLogger.i(
        'SpringBootPushManager',
        'Push notifications cleaned up successfully',
      );
    } catch (e) {
      AppLogger.e(
        'SpringBootPushManager',
        'Error cleaning up push notifications: $e',
      );
    }
  }
}
