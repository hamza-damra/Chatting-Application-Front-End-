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

// A simpler thumbnail version for the chat with loading animation
class VideoThumbnail extends StatefulWidget {
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
  State<VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<VideoThumbnail>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  final bool _hasError = false;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize shimmer animation for loading state
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Initialize pulse animation for play button
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startLoadingAnimation();
    _simulateVideoLoad();
  }

  void _startLoadingAnimation() {
    _shimmerController.repeat();
  }

  void _simulateVideoLoad() {
    // Simulate video metadata loading (in real app, this would check if video is accessible)
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _shimmerController.stop();
        _pulseController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          _isLoading
              ? null
              : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => Scaffold(
                          appBar: AppBar(title: const Text('Video')),
                          body: SafeArea(
                            child: VideoPlayerWidget(
                              videoUrl: widget.videoUrl,
                              heroTag: widget.heroTag,
                            ),
                          ),
                        ),
                  ),
                );
              },
      child: Hero(
        tag: widget.heroTag,
        child: Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.grey[800],
                ),

                // Loading shimmer effect
                if (_isLoading)
                  AnimatedBuilder(
                    animation: _shimmerAnimation,
                    builder: (context, child) {
                      return Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.grey[800]!,
                              Colors.grey[700]!,
                              Colors.grey[600]!,
                              Colors.grey[700]!,
                              Colors.grey[800]!,
                            ],
                            stops: [
                              0.0,
                              0.25 + _shimmerAnimation.value * 0.25,
                              0.5 + _shimmerAnimation.value * 0.25,
                              0.75 + _shimmerAnimation.value * 0.25,
                              1.0,
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                // Video icon (always visible)
                Icon(
                  Icons.videocam,
                  size: 64,
                  color:
                      _isLoading
                          ? Colors.grey[500]
                          : (widget.isCurrentUser
                              ? Colors.white70
                              : Colors.grey[400]),
                ),

                // Loading indicator
                if (_isLoading)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                widget.isCurrentUser
                                    ? Colors.white
                                    : Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Loading...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Play button (only when not loading)
                if (!_isLoading && !_hasError)
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                widget.isCurrentUser
                                    ? Theme.of(
                                      context,
                                    ).primaryColor.withAlpha(230)
                                    : Colors.black.withAlpha(180),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(100),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      );
                    },
                  ),

                // Duration badge (placeholder - could be enhanced to show actual duration)
                if (!_isLoading)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(180),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.videocam, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            'Video',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
