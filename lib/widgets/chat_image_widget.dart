import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/logger.dart';

/// A widget that handles different types of image URIs:
/// - Network URLs (http://, https://)
/// - Data URIs (data:image/...)
/// - Local file paths (file:///, /data/user/...)
class ChatImageWidget extends StatelessWidget {
  final String uri;
  final double width;
  final double height;
  final BoxFit fit;
  final bool isCurrentUser;
  final ThemeData theme;

  const ChatImageWidget({
    super.key,
    required this.uri,
    required this.width,
    required this.height,
    required this.fit,
    required this.isCurrentUser,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    AppLogger.d('ChatImageWidget', 'Building image widget for URI: $uri');

    // Check if it's a data URI (base64 image)
    if (uri.startsWith('data:image/')) {
      return _buildDataUriImage();
    }

    // Check if it's a network URL
    if (uri.startsWith('http://') || uri.startsWith('https://')) {
      return _buildNetworkImage();
    }

    // Check if it's a file URI or local path
    if (uri.startsWith('file:///') ||
        uri.startsWith('/data/') ||
        uri.startsWith('/')) {
      return _buildFileImage();
    }

    // Try to handle as a relative path or filename
    if (!uri.contains('://') && (uri.contains('.') || uri.contains('/'))) {
      return _buildRelativePathImage();
    }

    // If all else fails, show error widget
    AppLogger.e('ChatImageWidget', 'Unsupported image URI format: $uri');
    return _buildErrorWidget();
  }

  Widget _buildDataUriImage() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[300],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          _decodeDataUri(uri),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            AppLogger.e(
              'ChatImageWidget',
              'Error loading data URI image: $error',
            );
            return _buildErrorWidget();
          },
        ),
      ),
    );
  }

  Widget _buildNetworkImage() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[300],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: uri,
          width: width,
          height: height,
          fit: fit,
          memCacheWidth: _safeToInt(width),
          memCacheHeight: _safeToInt(height),
          placeholder: (context, url) => _buildLoadingWidget(),
          errorWidget: (context, url, error) {
            AppLogger.e(
              'ChatImageWidget',
              'Error loading network image: $error, URL: $url',
            );
            return _buildErrorWidget();
          },
        ),
      ),
    );
  }

  Widget _buildFileImage() {
    try {
      // For file paths, use File.fromUri if it's a URI, otherwise use File directly
      final file =
          uri.startsWith('file:///') ? File.fromUri(Uri.parse(uri)) : File(uri);

      if (!file.existsSync()) {
        AppLogger.e('ChatImageWidget', 'File does not exist: $uri');
        return _buildErrorWidget();
      }

      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[300],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              AppLogger.e(
                'ChatImageWidget',
                'Error loading file image: $error, Path: $uri',
              );
              return _buildErrorWidget();
            },
          ),
        ),
      );
    } catch (e) {
      AppLogger.e(
        'ChatImageWidget',
        'Error processing file path: $e, Path: $uri',
      );
      return _buildErrorWidget();
    }
  }

  Widget _buildRelativePathImage() {
    try {
      final file = File(uri);
      if (file.existsSync()) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[300],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              file,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (context, error, stackTrace) {
                AppLogger.e(
                  'ChatImageWidget',
                  'Error loading relative path image: $error, Path: $uri',
                );
                return _buildErrorWidget();
              },
            ),
          ),
        );
      } else {
        // File doesn't exist locally, return error widget
        AppLogger.e(
          'ChatImageWidget',
          'Relative path file does not exist: $uri',
        );
        return _buildErrorWidget();
      }
    } catch (e) {
      AppLogger.e(
        'ChatImageWidget',
        'Error processing relative path: $e, Path: $uri',
      );
      return _buildErrorWidget();
    }
  }

  Widget _buildLoadingWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300], // Use neutral color for all error states
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[400]!, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            color: Colors.grey[700], // Use neutral color for all error icons
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Image not available',
            style: TextStyle(
              color: Colors.grey[800], // Use neutral color for all error text
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (uri.length > 20)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'URI: ${uri.substring(0, 20)}...',
                style: TextStyle(
                  color:
                      Colors
                          .grey[600], // Use neutral color for all error details
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Uint8List _decodeDataUri(String dataUri) {
    try {
      // Extract the base64 part from the data URI
      final base64String = dataUri.split(',')[1];
      return base64Decode(base64String);
    } catch (e) {
      AppLogger.e('ChatImageWidget', 'Error decoding data URI: $e');
      throw Exception('Invalid data URI format');
    }
  }

  /// Safely convert a double to int, handling Infinity and NaN values
  int? _safeToInt(double value) {
    if (!value.isFinite) {
      return null;
    }
    return value.toInt();
  }
}
