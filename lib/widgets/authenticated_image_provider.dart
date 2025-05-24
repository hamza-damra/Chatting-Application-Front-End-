import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/services/token_service.dart';
import '../utils/url_utils.dart';
import '../utils/logger.dart';

/// A custom image provider that handles authentication and token refresh for image loading
class AuthenticatedImageProvider
    extends ImageProvider<AuthenticatedImageProvider> {
  final String imageUrl;
  final TokenService? tokenService;
  final Map<String, String>? headers;
  final double scale;

  const AuthenticatedImageProvider(
    this.imageUrl, {
    this.tokenService,
    this.headers,
    this.scale = 1.0,
  });

  @override
  Future<AuthenticatedImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) {
    return SynchronousFuture<AuthenticatedImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadBuffer(
    AuthenticatedImageProvider key,
    DecoderBufferCallback decode,
  ) {
    // Use the default implementation that calls load
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: key.scale,
      debugLabel: key.imageUrl,
      informationCollector:
          () => <DiagnosticsNode>[
            DiagnosticsProperty<ImageProvider>('Image provider', this),
            DiagnosticsProperty<AuthenticatedImageProvider>('Image key', key),
          ],
    );
  }

  Future<ui.Codec> _loadAsync(
    AuthenticatedImageProvider key,
    DecoderBufferCallback decode,
  ) async {
    try {
      final bytes = await _fetchImageBytes(key.imageUrl);
      if (bytes.lengthInBytes == 0) {
        throw Exception('Image bytes are empty');
      }

      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      return await decode(buffer);
    } catch (e) {
      AppLogger.e('AuthenticatedImageProvider', 'Error loading image: $e');
      rethrow;
    }
  }

  Future<Uint8List> _fetchImageBytes(String url) async {
    AppLogger.d('AuthenticatedImageProvider', 'Fetching image: $url');

    // Normalize the URL to ensure it has the correct token
    final normalizedUrl = UrlUtils.normalizeImageUrl(url);
    AppLogger.d('AuthenticatedImageProvider', 'Normalized URL: $normalizedUrl');

    try {
      final response = await _makeRequest(normalizedUrl);

      if (response.statusCode == 200) {
        AppLogger.d('AuthenticatedImageProvider', 'Image loaded successfully');
        return response.bodyBytes;
      } else if (response.statusCode == 401 && tokenService != null) {
        AppLogger.w(
          'AuthenticatedImageProvider',
          'Received 401, attempting token refresh',
        );

        // Try to refresh the token
        final refreshed = await tokenService!.performTokenRefresh();
        if (refreshed) {
          AppLogger.i(
            'AuthenticatedImageProvider',
            'Token refreshed, retrying image request',
          );

          // Update UrlUtils with the new token
          final newToken = tokenService!.accessToken;
          if (newToken != null) {
            UrlUtils.setAuthToken(newToken);
          }

          // Retry with the new token - use original imageUrl to get fresh token
          final retryUrl = UrlUtils.normalizeImageUrl(imageUrl);
          AppLogger.d(
            'AuthenticatedImageProvider',
            'Retrying with fresh URL: $retryUrl',
          );
          final retryResponse = await _makeRequest(retryUrl);

          if (retryResponse.statusCode == 200) {
            AppLogger.i(
              'AuthenticatedImageProvider',
              'Image loaded successfully after token refresh',
            );
            return retryResponse.bodyBytes;
          } else {
            throw HttpException(
              'Failed to load image after token refresh: ${retryResponse.statusCode}',
            );
          }
        } else {
          throw HttpException('Token refresh failed, cannot load image');
        }
      } else {
        throw HttpException('Failed to load image: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.e(
        'AuthenticatedImageProvider',
        'Error fetching image bytes: $e',
      );
      rethrow;
    }
  }

  Future<http.Response> _makeRequest(String url) async {
    final requestHeaders = <String, String>{
      'User-Agent': 'Flutter App',
      ...?headers,
    };

    // Add Authorization header with Bearer token if available
    final token = tokenService?.accessToken;
    if (token != null) {
      requestHeaders['Authorization'] = 'Bearer $token';
      AppLogger.d(
        'AuthenticatedImageProvider',
        'Added Authorization header with Bearer token',
      );
    }

    AppLogger.d('AuthenticatedImageProvider', 'Making request to: $url');
    AppLogger.d(
      'AuthenticatedImageProvider',
      'Request headers: $requestHeaders',
    );

    return await http
        .get(Uri.parse(url), headers: requestHeaders)
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException(
              'Image request timed out',
              const Duration(seconds: 30),
            );
          },
        );
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is AuthenticatedImageProvider &&
        other.imageUrl == imageUrl &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(imageUrl, scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'AuthenticatedImageProvider')}("$imageUrl", scale: $scale)';
}

/// A widget that displays an authenticated image with automatic token refresh
class AuthenticatedImage extends StatefulWidget {
  final String imageUrl;
  final TokenService? tokenService;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Map<String, String>? headers;

  const AuthenticatedImage({
    super.key,
    required this.imageUrl,
    this.tokenService,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.headers,
  });

  @override
  State<AuthenticatedImage> createState() => _AuthenticatedImageState();
}

class _AuthenticatedImageState extends State<AuthenticatedImage> {
  @override
  Widget build(BuildContext context) {
    return Image(
      image: AuthenticatedImageProvider(
        widget.imageUrl,
        tokenService: widget.tokenService,
        headers: widget.headers,
      ),
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return widget.placeholder ??
            Container(
              width: widget.width,
              height: widget.height,
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
      },
      errorBuilder: (context, error, stackTrace) {
        AppLogger.e('AuthenticatedImage', 'Error displaying image: $error');
        return widget.errorWidget ??
            Container(
              width: widget.width,
              height: widget.height,
              color: Colors.grey[300],
              child: const Icon(
                Icons.broken_image,
                color: Colors.grey,
                size: 32,
              ),
            );
      },
    );
  }
}
