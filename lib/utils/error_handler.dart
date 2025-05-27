import 'package:flutter/material.dart';
import 'logger.dart';

/// Error types for better categorization
enum ErrorType {
  network,
  server,
  authentication,
  authorization,
  validation,
  fileUpload,
  chatRoom,
  unknown,
}

/// Error severity levels
enum ErrorSeverity { info, warning, error, critical }

/// Utility class for handling and displaying user-friendly error messages
class ErrorHandler {
  /// Convert technical error messages to user-friendly messages
  static String getUserFriendlyMessage(String error) {
    // Server connectivity errors (highest priority)
    if (_isServerConnectivityError(error)) {
      return 'Unable to connect to the server. Please check your internet connection and try again later.';
    }

    // Network connectivity errors
    if (_isNetworkError(error)) {
      return 'Network connection lost. Please check your internet connection and try again.';
    }

    // Server errors
    if (_isServerError(error)) {
      return 'The server is currently experiencing issues. Please try again in a few moments.';
    }

    // Authentication errors
    if (_isAuthenticationError(error)) {
      return 'Your session has expired. Please log in again to continue.';
    }

    // Authorization errors
    if (_isAuthorizationError(error)) {
      return 'You don\'t have permission to perform this action.';
    }

    // File upload errors
    if (_isFileUploadError(error)) {
      return _getFileUploadErrorMessage(error);
    }

    // Chat room specific errors
    if (_isChatRoomError(error)) {
      return _getChatRoomErrorMessage(error);
    }

    // Timeout errors
    if (_isTimeoutError(error)) {
      return 'The request took too long to complete. Please check your connection and try again.';
    }

    // User errors
    if (error.contains('User not found')) {
      return 'User not found or no longer available.';
    }

    // Default: return a generic user-friendly message
    return 'Something went wrong. Please try again or contact support if the problem persists.';
  }

  /// Check if error is related to server connectivity
  static bool _isServerConnectivityError(String error) {
    final serverConnectivityKeywords = [
      'Connection refused',
      'Connection failed',
      'No route to host',
      'Host unreachable',
      'Server unavailable',
      'Service unavailable',
      'Connection reset',
      'Connection aborted',
      'Failed to connect',
      'Unable to connect',
      'Connection timeout',
      'No address associated with hostname',
      'Name or service not known',
      'Network is unreachable',
      'Connection timed out',
      'ConnectException',
      'ConnectTimeoutException',
      'HttpException',
      'HandshakeException',
    ];

    return serverConnectivityKeywords.any(
      (keyword) => error.toLowerCase().contains(keyword.toLowerCase()),
    );
  }

  /// Check if error is a network error
  static bool _isNetworkError(String error) {
    return error.contains('Network error') ||
        error.contains('SocketException') ||
        error.contains('No internet connection') ||
        error.contains('connection') && !_isServerConnectivityError(error);
  }

  /// Check if error is a server error
  static bool _isServerError(String error) {
    return error.contains('500') ||
        error.contains('502') ||
        error.contains('503') ||
        error.contains('504') ||
        error.contains('Internal Server Error') ||
        error.contains('Bad Gateway') ||
        error.contains('Service Unavailable') ||
        error.contains('Gateway Timeout');
  }

  /// Check if error is an authentication error
  static bool _isAuthenticationError(String error) {
    return error.contains('401') ||
        error.contains('Unauthorized') ||
        error.contains('UnauthorizedException') ||
        error.contains('session has expired') ||
        error.contains('please log in again') ||
        error.contains('Invalid token') ||
        error.contains('Token expired');
  }

  /// Check if error is an authorization error
  static bool _isAuthorizationError(String error) {
    return error.contains('403') ||
        error.contains('Access denied') ||
        error.contains('Forbidden') ||
        error.contains('not a participant') ||
        error.contains('ChatRoomAccessDeniedException') ||
        error.contains('You are not a participant') ||
        error.contains('Permission denied');
  }

  /// Check if error is a file upload error
  static bool _isFileUploadError(String error) {
    return error.contains('Content type not allowed') ||
        error.contains('file type is not supported') ||
        error.contains('File size exceeds') ||
        error.contains('file too large') ||
        error.contains('Upload failed') ||
        error.contains('File upload error');
  }

  /// Check if error is a chat room error
  static bool _isChatRoomError(String error) {
    return error.contains('Room not found') ||
        error.contains('Chat room not found') ||
        error.contains('Message not found') ||
        error.contains('ChatRoomNotFoundException');
  }

  /// Check if error is a timeout error
  static bool _isTimeoutError(String error) {
    return error.contains('timed out') ||
        error.contains('timeout') ||
        error.contains('TimeoutException');
  }

  /// Get specific file upload error message
  static String _getFileUploadErrorMessage(String error) {
    if (error.contains('Content type not allowed') ||
        error.contains('file type is not supported')) {
      return 'This file type is not supported. Please use JPEG, PNG, PDF, or TXT format.';
    }

    if (error.contains('File size exceeds') ||
        error.contains('file too large')) {
      return 'File is too large. Please select a file under 1GB.';
    }

    return 'File upload failed. Please try again with a different file.';
  }

  /// Get specific chat room error message
  static String _getChatRoomErrorMessage(String error) {
    if (error.contains('Room not found') ||
        error.contains('Chat room not found')) {
      return 'This chat room no longer exists or you don\'t have access to it.';
    }

    if (error.contains('Message not found')) {
      return 'This message is no longer available.';
    }

    return 'Chat room error. Please refresh and try again.';
  }

  /// Get error type for categorization
  static ErrorType getErrorType(String error) {
    if (_isServerConnectivityError(error) || _isNetworkError(error)) {
      return ErrorType.network;
    } else if (_isServerError(error)) {
      return ErrorType.server;
    } else if (_isAuthenticationError(error)) {
      return ErrorType.authentication;
    } else if (_isAuthorizationError(error)) {
      return ErrorType.authorization;
    } else if (_isFileUploadError(error)) {
      return ErrorType.fileUpload;
    } else if (_isChatRoomError(error)) {
      return ErrorType.chatRoom;
    } else {
      return ErrorType.unknown;
    }
  }

  /// Get error severity
  static ErrorSeverity getErrorSeverity(String error) {
    if (_isServerConnectivityError(error) || _isAuthenticationError(error)) {
      return ErrorSeverity.critical;
    } else if (_isServerError(error) || _isAuthorizationError(error)) {
      return ErrorSeverity.error;
    } else if (_isTimeoutError(error) || _isNetworkError(error)) {
      return ErrorSeverity.warning;
    } else {
      return ErrorSeverity.info;
    }
  }

  /// Show a user-friendly error message in a SnackBar
  static void showErrorSnackBar(
    BuildContext context,
    String error, {
    Duration duration = const Duration(seconds: 4),
    Color? backgroundColor,
    String? actionText,
    VoidCallback? onAction,
  }) {
    final userFriendlyMessage = getUserFriendlyMessage(error);
    final severity = getErrorSeverity(error);

    // Log the original error for debugging
    AppLogger.e('ErrorHandler', 'Error: $error');

    // Determine background color based on severity
    Color bgColor = backgroundColor ?? _getColorForSeverity(severity);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(getErrorIcon(error), color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                userFriendlyMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        duration: _getDurationForSeverity(severity, duration),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: actionText ?? 'Dismiss',
          textColor: Colors.white,
          onPressed:
              onAction ??
              () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
        ),
      ),
    );
  }

  /// Show an error dialog with user-friendly message
  static void showErrorDialog(
    BuildContext context,
    String error, {
    String? title,
    String? actionText,
    VoidCallback? onAction,
    bool barrierDismissible = true,
  }) {
    final userFriendlyMessage = getUserFriendlyMessage(error);
    final errorType = getErrorType(error);
    final severity = getErrorSeverity(error);

    // Log the original error for debugging
    AppLogger.e('ErrorHandler', 'Error: $error');

    // Determine title based on error type
    String dialogTitle = title ?? _getTitleForErrorType(errorType);

    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  getErrorIcon(error),
                  color: _getColorForSeverity(severity),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    dialogTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _getColorForSeverity(severity),
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              userFriendlyMessage,
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
            actions: [
              if (actionText != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: _getColorForSeverity(severity),
                  ),
                  child: Text(actionText),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  /// Check if an error is an authorization error (backward compatibility)
  static bool isAuthorizationError(String error) {
    return _isAuthorizationError(error);
  }

  /// Check if an error is an authentication error (backward compatibility)
  static bool isAuthenticationError(String error) {
    return _isAuthenticationError(error);
  }

  /// Check if an error is a server connectivity error
  static bool isServerConnectivityError(String error) {
    return _isServerConnectivityError(error);
  }

  /// Get an appropriate icon for the error type
  static IconData getErrorIcon(String error) {
    final errorType = getErrorType(error);

    switch (errorType) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.server:
        return Icons.cloud_off;
      case ErrorType.authentication:
        return Icons.login;
      case ErrorType.authorization:
        return Icons.lock_outline;
      case ErrorType.fileUpload:
        return Icons.file_upload_off;
      case ErrorType.chatRoom:
        return Icons.chat_bubble_outline;
      case ErrorType.validation:
        return Icons.warning_outlined;
      case ErrorType.unknown:
        return Icons.error_outline;
    }
  }

  /// Get color for error severity
  static Color _getColorForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.critical:
        return const Color(0xFFD32F2F); // Red
      case ErrorSeverity.error:
        return const Color(0xFFE53935); // Light red
      case ErrorSeverity.warning:
        return const Color(0xFFFF9800); // Orange
      case ErrorSeverity.info:
        return const Color(0xFF1976D2); // Blue
    }
  }

  /// Get duration for error severity
  static Duration _getDurationForSeverity(
    ErrorSeverity severity,
    Duration defaultDuration,
  ) {
    switch (severity) {
      case ErrorSeverity.critical:
        return const Duration(seconds: 8);
      case ErrorSeverity.error:
        return const Duration(seconds: 6);
      case ErrorSeverity.warning:
        return const Duration(seconds: 4);
      case ErrorSeverity.info:
        return const Duration(seconds: 3);
    }
  }

  /// Get title for error type
  static String _getTitleForErrorType(ErrorType errorType) {
    switch (errorType) {
      case ErrorType.network:
        return 'Connection Problem';
      case ErrorType.server:
        return 'Server Issue';
      case ErrorType.authentication:
        return 'Authentication Required';
      case ErrorType.authorization:
        return 'Access Denied';
      case ErrorType.fileUpload:
        return 'Upload Failed';
      case ErrorType.chatRoom:
        return 'Chat Error';
      case ErrorType.validation:
        return 'Invalid Input';
      case ErrorType.unknown:
        return 'Error';
    }
  }
}
