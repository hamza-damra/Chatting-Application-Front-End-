import 'package:flutter/material.dart';
import '../utils/error_handler.dart';
import '../utils/logger.dart';
import 'navigation_service.dart';

/// Global service for showing messages throughout the application
class GlobalMessageService {
  static final GlobalMessageService _instance = GlobalMessageService._internal();
  factory GlobalMessageService() => _instance;
  GlobalMessageService._internal();

  static GlobalMessageService get instance => _instance;

  /// Show a global error message
  static void showError(String error, {
    String? actionText,
    VoidCallback? onAction,
    bool useDialog = false,
  }) {
    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) {
      AppLogger.w('GlobalMessageService', 'No context available for showing error');
      return;
    }

    if (useDialog) {
      ErrorHandler.showErrorDialog(
        context,
        error,
        actionText: actionText,
        onAction: onAction,
      );
    } else {
      ErrorHandler.showErrorSnackBar(
        context,
        error,
        actionText: actionText,
        onAction: onAction,
      );
    }
  }

  /// Show a server connectivity error with retry option
  static void showServerConnectivityError({
    VoidCallback? onRetry,
    bool useDialog = true,
  }) {
    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) {
      AppLogger.w('GlobalMessageService', 'No context available for showing server error');
      return;
    }

    const error = 'Unable to connect to the server. Please check your internet connection and try again later.';
    
    if (useDialog) {
      ErrorHandler.showErrorDialog(
        context,
        error,
        title: 'Server Unavailable',
        actionText: onRetry != null ? 'Retry' : null,
        onAction: onRetry,
        barrierDismissible: false,
      );
    } else {
      ErrorHandler.showErrorSnackBar(
        context,
        error,
        actionText: onRetry != null ? 'Retry' : null,
        onAction: onRetry,
        duration: const Duration(seconds: 8),
      );
    }
  }

  /// Show a network connectivity error
  static void showNetworkError({
    VoidCallback? onRetry,
    bool useDialog = false,
  }) {
    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) {
      AppLogger.w('GlobalMessageService', 'No context available for showing network error');
      return;
    }

    const error = 'Network connection lost. Please check your internet connection and try again.';
    
    if (useDialog) {
      ErrorHandler.showErrorDialog(
        context,
        error,
        title: 'No Internet Connection',
        actionText: onRetry != null ? 'Retry' : null,
        onAction: onRetry,
      );
    } else {
      ErrorHandler.showErrorSnackBar(
        context,
        error,
        actionText: onRetry != null ? 'Retry' : null,
        onAction: onRetry,
        duration: const Duration(seconds: 6),
      );
    }
  }

  /// Show a success message
  static void showSuccess(String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) {
      AppLogger.w('GlobalMessageService', 'No context available for showing success');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50), // Green
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Show an info message
  static void showInfo(String message, {
    Duration duration = const Duration(seconds: 4),
    String? actionText,
    VoidCallback? onAction,
  }) {
    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) {
      AppLogger.w('GlobalMessageService', 'No context available for showing info');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.info,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2196F3), // Blue
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: actionText != null ? SnackBarAction(
          label: actionText,
          textColor: Colors.white,
          onPressed: onAction ?? () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ) : null,
      ),
    );
  }

  /// Show a warning message
  static void showWarning(String message, {
    Duration duration = const Duration(seconds: 5),
    String? actionText,
    VoidCallback? onAction,
  }) {
    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) {
      AppLogger.w('GlobalMessageService', 'No context available for showing warning');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.warning,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFF9800), // Orange
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: actionText != null ? SnackBarAction(
          label: actionText,
          textColor: Colors.white,
          onPressed: onAction ?? () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ) : null,
      ),
    );
  }

  /// Hide current message
  static void hideCurrentMessage() {
    final context = NavigationService.navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
  }

  /// Clear all messages
  static void clearAllMessages() {
    final context = NavigationService.navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).clearSnackBars();
    }
  }
}
