import 'package:flutter/material.dart';
import '../utils/error_handler.dart';

/// Professional error message card widget
class ErrorMessageCard extends StatelessWidget {
  final String error;
  final String? title;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool showIcon;
  final EdgeInsets? margin;

  const ErrorMessageCard({
    super.key,
    required this.error,
    this.title,
    this.onRetry,
    this.onDismiss,
    this.showIcon = true,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final errorType = ErrorHandler.getErrorType(error);
    final severity = ErrorHandler.getErrorSeverity(error);
    final userFriendlyMessage = ErrorHandler.getUserFriendlyMessage(error);
    final cardTitle = title ?? _getTitleForErrorType(errorType);

    return Container(
      margin: margin ?? const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: _getColorForSeverity(severity).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and title
              Row(
                children: [
                  if (showIcon) ...[
                    Icon(
                      ErrorHandler.getErrorIcon(error),
                      color: _getColorForSeverity(severity),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      cardTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _getColorForSeverity(severity),
                      ),
                    ),
                  ),
                  if (onDismiss != null)
                    IconButton(
                      onPressed: onDismiss,
                      icon: const Icon(Icons.close),
                      iconSize: 20,
                      color: Colors.grey[600],
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Error message
              Text(
                userFriendlyMessage,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: Colors.black87,
                ),
              ),

              // Action buttons
              if (onRetry != null) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: onRetry,
                      style: TextButton.styleFrom(
                        foregroundColor: _getColorForSeverity(severity),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Retry',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getTitleForErrorType(ErrorType errorType) {
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

  Color _getColorForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.critical:
        return const Color(0xFFD32F2F);
      case ErrorSeverity.error:
        return const Color(0xFFE53935);
      case ErrorSeverity.warning:
        return const Color(0xFFFF9800);
      case ErrorSeverity.info:
        return const Color(0xFF1976D2);
    }
  }
}

/// Inline error message widget for forms and inputs
class InlineErrorMessage extends StatelessWidget {
  final String error;
  final EdgeInsets? padding;
  final bool showIcon;

  const InlineErrorMessage({
    super.key,
    required this.error,
    this.padding,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final userFriendlyMessage = ErrorHandler.getUserFriendlyMessage(error);
    final severity = ErrorHandler.getErrorSeverity(error);

    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: _getColorForSeverity(severity).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getColorForSeverity(severity).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (showIcon) ...[
            Icon(
              ErrorHandler.getErrorIcon(error),
              color: _getColorForSeverity(severity),
              size: 16,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              userFriendlyMessage,
              style: TextStyle(
                fontSize: 14,
                color: _getColorForSeverity(severity),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.critical:
        return const Color(0xFFD32F2F);
      case ErrorSeverity.error:
        return const Color(0xFFE53935);
      case ErrorSeverity.warning:
        return const Color(0xFFFF9800);
      case ErrorSeverity.info:
        return const Color(0xFF1976D2);
    }
  }
}

/// Full-screen error widget for critical errors
class FullScreenErrorWidget extends StatelessWidget {
  final String error;
  final String? title;
  final VoidCallback? onRetry;
  final VoidCallback? onGoBack;

  const FullScreenErrorWidget({
    super.key,
    required this.error,
    this.title,
    this.onRetry,
    this.onGoBack,
  });

  @override
  Widget build(BuildContext context) {
    final errorType = ErrorHandler.getErrorType(error);
    final severity = ErrorHandler.getErrorSeverity(error);
    final userFriendlyMessage = ErrorHandler.getUserFriendlyMessage(error);
    final screenTitle = title ?? _getTitleForErrorType(errorType);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _getColorForSeverity(severity).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  ErrorHandler.getErrorIcon(error),
                  size: 64,
                  color: _getColorForSeverity(severity),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                screenTitle,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _getColorForSeverity(severity),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Error message
              Text(
                userFriendlyMessage,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Action buttons
              Column(
                children: [
                  if (onRetry != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onRetry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getColorForSeverity(severity),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Try Again',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  if (onRetry != null && onGoBack != null)
                    const SizedBox(height: 12),
                  if (onGoBack != null)
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: onGoBack,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Go Back',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTitleForErrorType(ErrorType errorType) {
    switch (errorType) {
      case ErrorType.network:
        return 'No Internet Connection';
      case ErrorType.server:
        return 'Server Unavailable';
      case ErrorType.authentication:
        return 'Please Sign In';
      case ErrorType.authorization:
        return 'Access Denied';
      case ErrorType.fileUpload:
        return 'Upload Failed';
      case ErrorType.chatRoom:
        return 'Chat Unavailable';
      case ErrorType.validation:
        return 'Invalid Input';
      case ErrorType.unknown:
        return 'Something Went Wrong';
    }
  }

  Color _getColorForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.critical:
        return const Color(0xFFD32F2F);
      case ErrorSeverity.error:
        return const Color(0xFFE53935);
      case ErrorSeverity.warning:
        return const Color(0xFFFF9800);
      case ErrorSeverity.info:
        return const Color(0xFF1976D2);
    }
  }
}
