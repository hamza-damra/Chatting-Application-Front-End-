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
    // Use the API config base URL (archivingalquds.ddns.net)
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

    // First, rewrite any old server URLs to the new server
    String processedUrl = url;
    if (url.contains('abusaker.zapto.org')) {
      processedUrl = url.replaceAll(
        'abusaker.zapto.org',
        'archivingalquds.ddns.net',
      );
      if (kDebugMode) {
        print('Rewrote old server URL to: $processedUrl');
      }
    }

    // If URL already contains our base URL, check if it needs conversion to download endpoint
    if (processedUrl.startsWith(ApiConfig.baseUrl)) {
      // Check if this is the old /api/files/{id} format that needs conversion
      final fileIdPattern = RegExp(r'/api/files/(\d+)$');
      final match = fileIdPattern.firstMatch(processedUrl);
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
      String normalizedUrl = _removeTokenFromUrl(processedUrl);
      if (kDebugMode) {
        print('URL already has base, normalized to: $normalizedUrl');
      }
      return normalizedUrl;
    }

    String baseUrl = getBaseUrl();
    String normalizedUrl = processedUrl;

    // Handle Windows absolute file paths - convert to server URLs for mobile access
    if (processedUrl.startsWith('C:') ||
        processedUrl.startsWith('c:') ||
        processedUrl.startsWith('D:') ||
        processedUrl.startsWith('d:')) {
      // Extract the filename from the Windows path
      String fileName = getFileNameFromUrl(processedUrl);
      // Use the correct API endpoint for file downloads
      normalizedUrl = '$baseUrl/api/files/download/$fileName';
    }
    // Handle auto-generated URLs with relative paths
    else if (processedUrl.contains('auto_generated') ||
        processedUrl.contains('uploads/') ||
        processedUrl.startsWith('uploads/')) {
      normalizedUrl =
          '$baseUrl/${processedUrl.startsWith('/') ? processedUrl.substring(1) : processedUrl}';
    }
    // Add http schema if missing but URL has a domain-like structure
    else if (!processedUrl.startsWith('http') &&
        !processedUrl.startsWith('file://') &&
        processedUrl.contains('.') &&
        !processedUrl.startsWith('/')) {
      normalizedUrl = 'https://$processedUrl';
    }
    // Add base URL for server-relative paths
    else if (processedUrl.startsWith('/') ||
        (!processedUrl.startsWith('http') &&
                !processedUrl.contains(':') &&
                processedUrl.contains('/') ||
            processedUrl.contains('uploads') ||
            processedUrl.contains('assets') ||
            processedUrl.contains('images'))) {
      // Remove leading slash if present for consistency
      final path =
          processedUrl.startsWith('/')
              ? processedUrl.substring(1)
              : processedUrl;
      normalizedUrl = '$baseUrl/$path';
    }
    // Handle Windows backslashes for file paths without drive letters
    else if (processedUrl.contains('\\')) {
      // Extract filename and use correct API endpoint
      String fileName = getFileNameFromUrl(processedUrl.replaceAll('\\', '/'));
      normalizedUrl = '$baseUrl/api/files/download/$fileName';
    }
    // Handle /api/files/{id} pattern without base URL
    else if (processedUrl.startsWith('/api/files/') &&
        RegExp(r'/api/files/(\d+)$').hasMatch(processedUrl)) {
      final fileIdPattern = RegExp(r'/api/files/(\d+)$');
      final match = fileIdPattern.firstMatch(processedUrl);
      if (match != null) {
        final fileId = match.group(1);
        // Convert to download endpoint format
        normalizedUrl = '$baseUrl/api/files/download/$fileId.mp4';
      }
    }
    // Handle bare filenames (likely from server responses)
    else if (!processedUrl.contains('/') &&
        !processedUrl.contains('\\') &&
        !processedUrl.startsWith('http')) {
      // This is likely a filename from the server, use the download endpoint
      normalizedUrl = '$baseUrl/api/files/download/$processedUrl';
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
