import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/logger.dart';

/// Handles all notification-related permissions for the chat application
class NotificationPermissionHandler {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Request all necessary notification permissions
  static Future<bool> requestAllPermissions(BuildContext context) async {
    try {
      AppLogger.i(
        'NotificationPermissionHandler',
        'Requesting notification permissions...',
      );

      // Request basic notification permission
      final notificationGranted = await _requestNotificationPermission();
      
      // Request battery optimization exemption (Android)
      final batteryOptimizationGranted = await _requestBatteryOptimizationExemption(context);
      
      // Request system alert window permission (Android)
      final systemAlertGranted = await _requestSystemAlertWindowPermission();

      final allGranted = notificationGranted && batteryOptimizationGranted && systemAlertGranted;

      AppLogger.i(
        'NotificationPermissionHandler',
        'Permission results - Notification: $notificationGranted, '
        'Battery: $batteryOptimizationGranted, SystemAlert: $systemAlertGranted',
      );

      return allGranted;
    } catch (e) {
      AppLogger.e(
        'NotificationPermissionHandler',
        'Error requesting permissions: $e',
      );
      return false;
    }
  }

  /// Request notification permission
  static Future<bool> _requestNotificationPermission() async {
    try {
      // For Android 13+ (API 33+), request POST_NOTIFICATIONS permission
      if (Platform.isAndroid) {
        final status = await Permission.notification.request();
        
        if (status.isGranted) {
          AppLogger.i(
            'NotificationPermissionHandler',
            'Notification permission granted',
          );
          return true;
        } else if (status.isDenied) {
          AppLogger.w(
            'NotificationPermissionHandler',
            'Notification permission denied',
          );
          return false;
        } else if (status.isPermanentlyDenied) {
          AppLogger.w(
            'NotificationPermissionHandler',
            'Notification permission permanently denied',
          );
          return false;
        }
      }

      // For iOS, request through flutter_local_notifications
      if (Platform.isIOS) {
        final iosPlugin = _notifications
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        
        if (iosPlugin != null) {
          final granted = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          
          AppLogger.i(
            'NotificationPermissionHandler',
            'iOS notification permission granted: $granted',
          );
          return granted ?? false;
        }
      }

      return true;
    } catch (e) {
      AppLogger.e(
        'NotificationPermissionHandler',
        'Error requesting notification permission: $e',
      );
      return false;
    }
  }

  /// Request battery optimization exemption (Android only)
  static Future<bool> _requestBatteryOptimizationExemption(BuildContext context) async {
    if (!Platform.isAndroid) return true;

    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      
      if (status.isGranted) {
        AppLogger.i(
          'NotificationPermissionHandler',
          'Battery optimization exemption already granted',
        );
        return true;
      }

      // Show explanation dialog
      final shouldRequest = await _showBatteryOptimizationDialog(context);
      if (!shouldRequest) return false;

      final requestStatus = await Permission.ignoreBatteryOptimizations.request();
      
      if (requestStatus.isGranted) {
        AppLogger.i(
          'NotificationPermissionHandler',
          'Battery optimization exemption granted',
        );
        return true;
      } else {
        AppLogger.w(
          'NotificationPermissionHandler',
          'Battery optimization exemption denied',
        );
        return false;
      }
    } catch (e) {
      AppLogger.e(
        'NotificationPermissionHandler',
        'Error requesting battery optimization exemption: $e',
      );
      return false;
    }
  }

  /// Request system alert window permission (Android only)
  static Future<bool> _requestSystemAlertWindowPermission() async {
    if (!Platform.isAndroid) return true;

    try {
      final status = await Permission.systemAlertWindow.status;
      
      if (status.isGranted) {
        AppLogger.i(
          'NotificationPermissionHandler',
          'System alert window permission already granted',
        );
        return true;
      }

      final requestStatus = await Permission.systemAlertWindow.request();
      
      if (requestStatus.isGranted) {
        AppLogger.i(
          'NotificationPermissionHandler',
          'System alert window permission granted',
        );
        return true;
      } else {
        AppLogger.w(
          'NotificationPermissionHandler',
          'System alert window permission denied',
        );
        return false;
      }
    } catch (e) {
      AppLogger.e(
        'NotificationPermissionHandler',
        'Error requesting system alert window permission: $e',
      );
      return false;
    }
  }

  /// Show battery optimization explanation dialog
  static Future<bool> _showBatteryOptimizationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Battery Optimization'),
          content: const Text(
            'To receive notifications when the app is in the background, '
            'please disable battery optimization for this app. This ensures '
            'the app can continue running in the background to receive messages.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Allow'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  /// Check if all required permissions are granted
  static Future<bool> areAllPermissionsGranted() async {
    try {
      // Check notification permission
      final notificationStatus = await Permission.notification.status;
      final notificationGranted = notificationStatus.isGranted;

      // Check battery optimization (Android only)
      bool batteryOptimizationGranted = true;
      if (Platform.isAndroid) {
        final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
        batteryOptimizationGranted = batteryStatus.isGranted;
      }

      // Check system alert window (Android only)
      bool systemAlertGranted = true;
      if (Platform.isAndroid) {
        final systemAlertStatus = await Permission.systemAlertWindow.status;
        systemAlertGranted = systemAlertStatus.isGranted;
      }

      final allGranted = notificationGranted && batteryOptimizationGranted && systemAlertGranted;

      AppLogger.i(
        'NotificationPermissionHandler',
        'Permission check - Notification: $notificationGranted, '
        'Battery: $batteryOptimizationGranted, SystemAlert: $systemAlertGranted',
      );

      return allGranted;
    } catch (e) {
      AppLogger.e(
        'NotificationPermissionHandler',
        'Error checking permissions: $e',
      );
      return false;
    }
  }

  /// Open app settings for manual permission configuration
  static Future<void> openAppSettings() async {
    try {
      await openAppSettings();
      AppLogger.i(
        'NotificationPermissionHandler',
        'Opened app settings for manual permission configuration',
      );
    } catch (e) {
      AppLogger.e(
        'NotificationPermissionHandler',
        'Error opening app settings: $e',
      );
    }
  }
}
