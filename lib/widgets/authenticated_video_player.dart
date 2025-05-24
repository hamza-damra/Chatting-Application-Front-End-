import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../core/services/token_service.dart';
import '../utils/logger.dart';
import '../utils/url_utils.dart';

class AuthenticatedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? heroTag;
  final TokenService? tokenService;

  const AuthenticatedVideoPlayer({
    super.key,
    required this.videoUrl,
    this.heroTag,
    this.tokenService,
  });

  @override
  State<AuthenticatedVideoPlayer> createState() =>
      _AuthenticatedVideoPlayerState();
}

class _AuthenticatedVideoPlayerState extends State<AuthenticatedVideoPlayer> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  File? _tempVideoFile;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      // Reset error state
      if (mounted) {
        setState(() {
          _isLoading = true;
          _hasError = false;
          _errorMessage = '';
        });
      }

      // Dispose previous controllers if they exist
      _chewieController?.dispose();
      _videoPlayerController?.dispose();

      // Clean up previous temp file
      if (_tempVideoFile != null && await _tempVideoFile!.exists()) {
        await _tempVideoFile!.delete();
      }

      // Get TokenService from context if not provided
      final tokenService =
          widget.tokenService ??
          (mounted ? Provider.of<TokenService?>(context, listen: false) : null);

      // Normalize the video URL
      final normalizedUrl = UrlUtils.normalizeImageUrl(widget.videoUrl);
      AppLogger.d(
        'AuthenticatedVideoPlayer',
        'Normalized video URL: $normalizedUrl',
      );

      // Download video with authentication
      final videoBytes = await _downloadVideoWithAuth(
        normalizedUrl,
        tokenService,
      );

      // Save to temporary file
      _tempVideoFile = await _saveToTempFile(videoBytes);

      // Initialize video player with local file
      _videoPlayerController = VideoPlayerController.file(_tempVideoFile!);
      await _videoPlayerController!.initialize();

      // Check if the widget is still mounted before creating Chewie controller
      if (!mounted) return;

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Theme.of(context).primaryColor,
          handleColor: Theme.of(context).primaryColor,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.grey[300]!,
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 42),
                const SizedBox(height: 8),
                Text(
                  'Error: $errorMessage',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _initializePlayer,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.e(
        'AuthenticatedVideoPlayer',
        'Error initializing video player: $e',
      );
      AppLogger.e('AuthenticatedVideoPlayer', 'Error type: ${e.runtimeType}');
      AppLogger.e(
        'AuthenticatedVideoPlayer',
        'Stack trace: ${StackTrace.current}',
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = _getUserFriendlyErrorMessage(e.toString());
        });
      }
    }
  }

  Future<Uint8List> _downloadVideoWithAuth(
    String url,
    TokenService? tokenService,
  ) async {
    AppLogger.d('AuthenticatedVideoPlayer', 'Downloading video: $url');

    final requestHeaders = <String, String>{'User-Agent': 'Flutter App'};

    // Add Authorization header with Bearer token if available
    final token = tokenService?.accessToken;
    if (token != null) {
      requestHeaders['Authorization'] = 'Bearer $token';
      AppLogger.d(
        'AuthenticatedVideoPlayer',
        'Added Authorization header with Bearer token',
      );
    }

    try {
      final response = await http
          .get(Uri.parse(url), headers: requestHeaders)
          .timeout(const Duration(seconds: 60)); // Longer timeout for videos

      if (response.statusCode == 200) {
        AppLogger.d(
          'AuthenticatedVideoPlayer',
          'Video downloaded successfully, size: ${response.bodyBytes.length} bytes',
        );
        return response.bodyBytes;
      } else if (response.statusCode == 401 && tokenService != null) {
        AppLogger.w(
          'AuthenticatedVideoPlayer',
          'Received 401, attempting token refresh',
        );

        // Try to refresh the token
        final refreshed = await tokenService.performTokenRefresh();
        if (refreshed) {
          AppLogger.i(
            'AuthenticatedVideoPlayer',
            'Token refreshed, retrying video download',
          );

          // Update UrlUtils with the new token
          final newToken = tokenService.accessToken;
          if (newToken != null) {
            UrlUtils.setAuthToken(newToken);
            requestHeaders['Authorization'] = 'Bearer $newToken';
          }

          // Retry with the new token
          final retryResponse = await http
              .get(Uri.parse(url), headers: requestHeaders)
              .timeout(const Duration(seconds: 60));

          if (retryResponse.statusCode == 200) {
            AppLogger.i(
              'AuthenticatedVideoPlayer',
              'Video downloaded successfully after token refresh',
            );
            return retryResponse.bodyBytes;
          } else {
            throw HttpException(
              'Failed to download video after token refresh: ${retryResponse.statusCode}',
            );
          }
        } else {
          throw HttpException('Token refresh failed, cannot download video');
        }
      } else {
        throw HttpException('Failed to download video: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.e('AuthenticatedVideoPlayer', 'Error downloading video: $e');
      rethrow;
    }
  }

  Future<File> _saveToTempFile(Uint8List bytes) async {
    final tempDir = await getTemporaryDirectory();

    // Try to determine file extension from original URL
    String extension = '.mp4'; // Default to mp4
    try {
      final uri = Uri.parse(widget.videoUrl);
      final path = uri.path.toLowerCase();
      if (path.endsWith('.mov')) {
        extension = '.mov';
      } else if (path.endsWith('.avi')) {
        extension = '.avi';
      } else if (path.endsWith('.webm')) {
        extension = '.webm';
      } else if (path.endsWith('.mkv')) {
        extension = '.mkv';
      }
    } catch (e) {
      AppLogger.w(
        'AuthenticatedVideoPlayer',
        'Could not determine file extension: $e',
      );
    }

    final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}$extension';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    AppLogger.d(
      'AuthenticatedVideoPlayer',
      'Video saved to temp file: ${file.path} (${bytes.length} bytes)',
    );

    // Verify the file was written correctly
    if (await file.exists()) {
      final fileSize = await file.length();
      AppLogger.d(
        'AuthenticatedVideoPlayer',
        'Temp file verified: $fileSize bytes',
      );
    } else {
      throw Exception('Failed to save video to temp file');
    }

    return file;
  }

  String _getUserFriendlyErrorMessage(String error) {
    if (error.contains('CleartextNotPermittedException') ||
        error.contains('Cleartext HTTP traffic not permitted')) {
      return 'Video cannot be loaded due to security restrictions. The server needs to use HTTPS.';
    } else if (error.contains('404') || error.contains('Not Found')) {
      return 'Video not found on server.';
    } else if (error.contains('403') || error.contains('Forbidden')) {
      return 'Access denied to video.';
    } else if (error.contains('timeout')) {
      return 'Connection timeout while loading video.';
    } else if (error.contains('network') || error.contains('Network')) {
      return 'Network error while loading video.';
    } else {
      return 'Unable to load video: ${error.length > 100 ? '${error.substring(0, 100)}...' : error}';
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();

    // Clean up temp file
    if (_tempVideoFile != null) {
      _tempVideoFile!.delete().catchError((e) {
        AppLogger.w(
          'AuthenticatedVideoPlayer',
          'Failed to delete temp file: $e',
        );
        return _tempVideoFile!; // Return the file object to satisfy the type requirement
      });
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_isLoading) {
      content = const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading video...'),
          ],
        ),
      );
    } else if (_hasError) {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error playing video',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializePlayer,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else if (_chewieController != null) {
      content = Chewie(controller: _chewieController!);
    } else {
      content = const Center(child: Text('Unable to load video player'));
    }

    if (widget.heroTag != null) {
      return Hero(tag: widget.heroTag!, child: content);
    }

    return content;
  }
}
