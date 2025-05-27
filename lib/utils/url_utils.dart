import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

class UrlUtils {
  // Store token for authentication
  static String? _authToken;

  // Callback for token updates
  static Function(String)? _onTokenUpdated;

  // Set the authorization token for image URLs
  static void setAuthToken(String token) {
    _authToken = token;
    if (kDebugMode) {
      print('UrlUtils: Token updated');
    }
    // Notify listeners about token update
    _onTokenUpdated?.call(token);
  }

  // Get current auth token
  static String? getAuthToken() {
    return _authToken;
  }

  // Set token update callback
  static void setTokenUpdateCallback(Function(String) callback) {
    _onTokenUpdated = callback;
  }

  // Clear token update callback
  static void clearTokenUpdateCallback() {
    _onTokenUpdated = null;
  }

  // Get the current server URL
  static String getBaseUrl() {
    // Use the API config base URL (abusaker.zapto.org)
    return ApiConfig.baseUrl;
  }

  /// Determines if a string is likely an image URL or file path
  static bool isImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;

    // Check for common image extensions
    final hasImageExtension =
        url.toLowerCase().endsWith('.jpg') ||
        url.toLowerCase().endsWith('.jpeg') ||
        url.toLowerCase().endsWith('.png') ||
        url.toLowerCase().endsWith('.gif') ||
        url.toLowerCase().endsWith('.webp') ||
        url.toLowerCase().endsWith('.bmp');

    // Check for URL/path patterns
    final hasUrlPattern =
        url.contains('/') ||
        url.contains('\\') ||
        url.startsWith('http') ||
        url.startsWith('C:') ||
        url.startsWith('c:');

    // Check for server-specific patterns
    final hasServerPattern =
        url.contains('uploads/') ||
        url.contains('assets/') ||
        url.contains('images/') ||
        url.contains('auto_generated');

    return hasImageExtension || (hasUrlPattern && hasServerPattern);
  }

  /// Normalizes file URLs (images/videos) from different sources to a consistent format
  static String normalizeImageUrl(String url) {
    if (kDebugMode) {
      print('Normalizing URL: $url');
    }

    // If URL already contains our base URL, check if it needs conversion to download endpoint
    if (url.startsWith(ApiConfig.baseUrl)) {
      // Check if this is the old /api/files/{id} format that needs conversion
      final fileIdPattern = RegExp(r'/api/files/(\d+)$');
      final match = fileIdPattern.firstMatch(url);
      if (match != null) {
        final fileId = match.group(1);
        // Convert to download endpoint format - we'll assume .mp4 for videos
        // The actual filename should be determined by the calling code
        String normalizedUrl =
            '${ApiConfig.baseUrl}/api/files/download/$fileId.mp4';
        if (kDebugMode) {
          print('Converted file ID URL to download format: $normalizedUrl');
        }
        return normalizedUrl;
      }

      // Remove any existing token query parameters since we use Bearer auth
      String normalizedUrl = _removeTokenFromUrl(url);
      if (kDebugMode) {
        print('URL already has base, normalized to: $normalizedUrl');
      }
      return normalizedUrl;
    }

    String baseUrl = getBaseUrl();
    String normalizedUrl = url;

    // Handle Windows absolute file paths - convert to server URLs for mobile access
    if (url.startsWith('C:') ||
        url.startsWith('c:') ||
        url.startsWith('D:') ||
        url.startsWith('d:')) {
      // Extract the filename from the Windows path
      String fileName = getFileNameFromUrl(url);
      // Use the correct API endpoint for file downloads
      normalizedUrl = '$baseUrl/api/files/download/$fileName';
    }
    // Handle auto-generated URLs with relative paths
    else if (url.contains('auto_generated') ||
        url.contains('uploads/') ||
        url.startsWith('uploads/')) {
      normalizedUrl =
          '$baseUrl/${url.startsWith('/') ? url.substring(1) : url}';
    }
    // Add http schema if missing but URL has a domain-like structure
    else if (!url.startsWith('http') &&
        !url.startsWith('file://') &&
        url.contains('.') &&
        !url.startsWith('/')) {
      normalizedUrl = 'https://$url';
    }
    // Add base URL for server-relative paths
    else if (url.startsWith('/') ||
        (!url.startsWith('http') && !url.contains(':') && url.contains('/') ||
            url.contains('uploads') ||
            url.contains('assets') ||
            url.contains('images'))) {
      // Remove leading slash if present for consistency
      final path = url.startsWith('/') ? url.substring(1) : url;
      normalizedUrl = '$baseUrl/$path';
    }
    // Handle Windows backslashes for file paths without drive letters
    else if (url.contains('\\')) {
      // Extract filename and use correct API endpoint
      String fileName = getFileNameFromUrl(url.replaceAll('\\', '/'));
      normalizedUrl = '$baseUrl/api/files/download/$fileName';
    }
    // Handle /api/files/{id} pattern without base URL
    else if (url.startsWith('/api/files/') &&
        RegExp(r'/api/files/(\d+)$').hasMatch(url)) {
      final fileIdPattern = RegExp(r'/api/files/(\d+)$');
      final match = fileIdPattern.firstMatch(url);
      if (match != null) {
        final fileId = match.group(1);
        // Convert to download endpoint format
        normalizedUrl = '$baseUrl/api/files/download/$fileId.mp4';
      }
    }
    // Handle bare filenames (likely from server responses)
    else if (!url.contains('/') &&
        !url.contains('\\') &&
        !url.startsWith('http')) {
      // This is likely a filename from the server, use the download endpoint
      normalizedUrl = '$baseUrl/api/files/download/$url';
    }

    // Note: Authentication is now handled via Bearer token in Authorization header
    // by AuthenticatedImageProvider, so we don't add query parameters here

    if (kDebugMode) {
      print('Normalized URL: $normalizedUrl');
    }

    return normalizedUrl;
  }

  /// Remove existing token parameter from URL
  static String _removeTokenFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final queryParams = Map<String, String>.from(uri.queryParameters);
      queryParams.remove('token');

      final newUri = uri.replace(
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      return newUri.toString();
    } catch (e) {
      // Fallback to simple string replacement if URI parsing fails
      if (url.contains('token=')) {
        final parts = url.split('?');
        if (parts.length > 1) {
          final baseUrl = parts[0];
          final queryString = parts[1];
          final queryParams =
              queryString
                  .split('&')
                  .where((param) => !param.startsWith('token='))
                  .toList();

          if (queryParams.isEmpty) {
            return baseUrl;
          } else {
            return '$baseUrl?${queryParams.join('&')}';
          }
        }
      }
      return url;
    }
  }

  /// Extract filename from URL or path
  static String getFileNameFromUrl(String url) {
    try {
      // Try parsing as a URI
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        return pathSegments.last;
      }
    } catch (e) {
      // If parsing fails, try simple string operations
    }

    // Handle Windows paths
    if (url.contains('\\')) {
      final parts = url.split('\\');
      return parts.last;
    }

    // Handle Unix paths and URLs
    if (url.contains('/')) {
      final parts = url.split('/');
      return parts.last;
    }

    return url;
  }
}
