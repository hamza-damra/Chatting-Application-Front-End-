import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:provider/provider.dart';
import '../utils/logger.dart';
import '../core/services/token_service.dart';
import '../utils/url_utils.dart';
import 'authenticated_video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String? heroTag;

  const VideoPlayerWidget({super.key, required this.videoUrl, this.heroTag});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  @override
  Widget build(BuildContext context) {
    // Get TokenService from context
    final tokenService = Provider.of<TokenService?>(context, listen: false);

    // Normalize the video URL
    final normalizedUrl = UrlUtils.normalizeImageUrl(widget.videoUrl);

    // Enhanced debugging
    AppLogger.d('VideoPlayerWidget', 'Original video URL: ${widget.videoUrl}');
    AppLogger.d('VideoPlayerWidget', 'Normalized video URL: $normalizedUrl');
    AppLogger.d(
      'VideoPlayerWidget',
      'TokenService available: ${tokenService != null}',
    );
    AppLogger.d(
      'VideoPlayerWidget',
      'TokenService token: ${tokenService?.accessToken != null ? "Available" : "Not available"}',
    );

    // Check if this is a server URL that needs authentication
    final needsAuth =
        normalizedUrl.startsWith('http://abusaker.zapto.org:8080') ||
        normalizedUrl.startsWith('http://localhost:8080') ||
        normalizedUrl.startsWith('https://');

    AppLogger.d('VideoPlayerWidget', 'Needs authentication: $needsAuth');

    if (needsAuth && tokenService != null) {
      AppLogger.i(
        'VideoPlayerWidget',
        'Using AuthenticatedVideoPlayer for: $normalizedUrl',
      );
      // Use authenticated video player for server videos
      return AuthenticatedVideoPlayer(
        videoUrl: widget.videoUrl,
        heroTag: widget.heroTag,
        tokenService: tokenService,
      );
    } else {
      AppLogger.i(
        'VideoPlayerWidget',
        'Using LegacyVideoPlayer for: $normalizedUrl',
      );
      // Use legacy implementation for public videos
      return _LegacyVideoPlayer(
        videoUrl: normalizedUrl,
        heroTag: widget.heroTag,
      );
    }
  }
}

// Legacy video player for backward compatibility
class _LegacyVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? heroTag;

  const _LegacyVideoPlayer({required this.videoUrl, this.heroTag});

  @override
  State<_LegacyVideoPlayer> createState() => _LegacyVideoPlayerState();
}

class _LegacyVideoPlayerState extends State<_LegacyVideoPlayer> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

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

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await _videoPlayerController!.initialize();

      // Check if the widget is still mounted before creating Chewie controller
      if (!mounted) return;

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        autoPlay: false, // Changed to false for better UX
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
      AppLogger.e('VideoPlayerWidget', 'Error initializing video player: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = _getUserFriendlyErrorMessage(e.toString());
        });
      }
    }
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
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

// A simpler thumbnail version for the chat
class VideoThumbnail extends StatelessWidget {
  final String videoUrl;
  final String heroTag;
  final bool isCurrentUser;

  const VideoThumbnail({
    super.key,
    required this.videoUrl,
    required this.heroTag,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => Scaffold(
                  appBar: AppBar(title: const Text('Video')),
                  body: SafeArea(
                    child: VideoPlayerWidget(
                      videoUrl: videoUrl,
                      heroTag: heroTag,
                    ),
                  ),
                ),
          ),
        );
      },
      child: Hero(
        tag: heroTag,
        child: Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.grey[800],
                child: Center(
                  child: Icon(
                    Icons.videocam,
                    size: 64,
                    color: isCurrentUser ? Colors.white70 : Colors.grey[400],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      isCurrentUser
                          ? Theme.of(context).primaryColor.withAlpha(204)
                          : Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
