import 'package:flutter/material.dart';
import 'logger.dart';

/// Utility class for handling and displaying user-friendly error messages
class ErrorHandler {
  
  /// Convert technical error messages to user-friendly messages
  static String getUserFriendlyMessage(String error) {
    // Authorization errors
    if (error.contains('not a participant') || 
        error.contains('ChatRoomAccessDeniedException') ||
        error.contains('You are not a participant')) {
      return 'You don\'t have permission to access this chat room.';
    }
    
    if (error.contains('Access denied') || 
        error.contains('403') ||
        error.contains('Forbidden')) {
      return 'Access denied. You may not have permission for this action.';
    }
    
    if (error.contains('UnauthorizedException') ||
        error.contains('401') ||
        error.contains('Unauthorized')) {
      return 'Your session has expired. Please log in again.';
    }
    
    // File upload errors
    if (error.contains('Content type not allowed') ||
        error.contains('file type is not supported')) {
      return 'This file type is not supported. Try using JPEG, PNG, PDF, or TXT format.';
    }
    
    if (error.contains('File size exceeds') ||
        error.contains('file too large')) {
      return 'File is too large. Please select a file under 10MB.';
    }
    
    if (error.contains('timed out') ||
        error.contains('timeout')) {
      return 'Request timed out. Check your connection and try again.';
    }
    
    // Network errors
    if (error.contains('Network error') ||
        error.contains('connection') ||
        error.contains('SocketException')) {
      return 'Network error. Please check your internet connection.';
    }
    
    // Server errors
    if (error.contains('500') ||
        error.contains('Internal Server Error')) {
      return 'Server error. Please try again later.';
    }
    
    if (error.contains('404') ||
        error.contains('Not Found')) {
      return 'The requested resource was not found.';
    }
    
    // Chat room specific errors
    if (error.contains('Room not found') ||
        error.contains('Chat room not found')) {
      return 'This chat room no longer exists or you don\'t have access to it.';
    }
    
    if (error.contains('Message not found')) {
      return 'This message is no longer available.';
    }
    
    // User errors
    if (error.contains('User not found')) {
      return 'User not found or no longer available.';
    }
    
    // Default: return the original error if no specific handling
    return error;
  }
  
  /// Show a user-friendly error message in a SnackBar
  static void showErrorSnackBar(BuildContext context, String error, {
    Duration duration = const Duration(seconds: 4),
    Color? backgroundColor,
  }) {
    final userFriendlyMessage = getUserFriendlyMessage(error);
    
    // Log the original error for debugging
    AppLogger.e('ErrorHandler', 'Error: $error');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(userFriendlyMessage),
        backgroundColor: backgroundColor ?? Colors.red,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
  
  /// Show an error dialog with user-friendly message
  static void showErrorDialog(BuildContext context, String error, {
    String title = 'Error',
    String? actionText,
    VoidCallback? onAction,
  }) {
    final userFriendlyMessage = getUserFriendlyMessage(error);
    
    // Log the original error for debugging
    AppLogger.e('ErrorHandler', 'Error: $error');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(userFriendlyMessage),
        actions: [
          if (actionText != null && onAction != null)
            TextButton(
              onPressed: onAction,
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
  
  /// Check if an error is an authorization error
  static bool isAuthorizationError(String error) {
    return error.contains('403') ||
           error.contains('Access denied') ||
           error.contains('not a participant') ||
           error.contains('ChatRoomAccessDeniedException') ||
           error.contains('UnauthorizedException') ||
           error.contains('Forbidden');
  }
  
  /// Check if an error is an authentication error (requires re-login)
  static bool isAuthenticationError(String error) {
    return error.contains('401') ||
           error.contains('Unauthorized') ||
           error.contains('session has expired') ||
           error.contains('please log in again');
  }
  
  /// Get an appropriate icon for the error type
  static IconData getErrorIcon(String error) {
    if (isAuthorizationError(error)) {
      return Icons.lock_outline;
    } else if (isAuthenticationError(error)) {
      return Icons.login;
    } else if (error.contains('Network') || error.contains('connection')) {
      return Icons.wifi_off;
    } else if (error.contains('File') || error.contains('upload')) {
      return Icons.file_upload_off;
    } else {
      return Icons.error_outline;
    }
  }
}
