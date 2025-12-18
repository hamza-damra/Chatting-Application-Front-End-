import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../design_system/tokens/app_spacing.dart';
import '../utils/logger.dart';
import '../utils/url_utils.dart';
import '../widgets/shimmer_widgets.dart';
import '../widgets/video_player_widget.dart';

import '../core/services/token_service.dart';

class MediaPreviewScreen extends StatefulWidget {
  final String attachmentUrl;
  final String? contentType;
  final String? fileName;

  const MediaPreviewScreen({
    super.key,
    required this.attachmentUrl,
    this.contentType,
    this.fileName,
  });

  @override
  State<MediaPreviewScreen> createState() => _MediaPreviewScreenState();
}

class _MediaPreviewScreenState extends State<MediaPreviewScreen> {
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Simulate loading delay
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.e('MediaPreviewScreen', 'Error loading media: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading media: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileType = _getFileType();
    final displayName = widget.fileName ?? _getDisplayName();
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom header row
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sharing not implemented in this demo'),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Download started')),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child:
                  _isLoading
                      ? Center(
                        child: ShimmerWidgets.mediaPreviewShimmer(
                          context: context,
                        ),
                      )
                      : _errorMessage.isNotEmpty
                      ? _buildErrorWidget()
                      : _buildMediaPreview(fileType),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Failed to load Image',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadMedia,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageErrorWidget(String errorMessage) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Failed to load Image',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Error: $errorMessage',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadMedia();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview(String fileType) {
    // Get responsive max dimensions for media on large screens
    final maxMediaWidth = ResponsiveLayout.value<double>(
      context: context,
      mobile: double.infinity,
      tablet: 600.0,
      desktop: 800.0,
    );
    final maxMediaHeight = ResponsiveLayout.value<double>(
      context: context,
      mobile: double.infinity,
      tablet: 500.0,
      desktop: 600.0,
    );
    final horizontalMargin = ResponsiveLayout.value<double>(
      context: context,
      mobile: 0.0,
      tablet: AppSpacing.xxl,
      desktop: AppSpacing.huge,
    );

    if (fileType.contains('image')) {
      // Get token service for authenticated image loading
      TokenService? tokenService;
      try {
        tokenService = Provider.of<TokenService>(context, listen: false);
      } catch (e) {
        AppLogger.w('MediaPreviewScreen', 'TokenService not available: $e');
      }

      final normalizedUrl = UrlUtils.normalizeImageUrl(widget.attachmentUrl);

      return Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
          constraints: BoxConstraints(
            maxWidth: maxMediaWidth,
            maxHeight: maxMediaHeight,
          ),
          child: CachedNetworkImage(
            imageUrl: normalizedUrl,
            fit: BoxFit.contain,
            httpHeaders:
                tokenService?.accessToken != null
                    ? {'Authorization': 'Bearer ${tokenService!.accessToken}'}
                    : null,
            placeholder:
                (context, url) => Center(
                  child: ShimmerWidgets.imageShimmer(
                    width: 200,
                    height: 200,
                    context: context,
                  ),
                ),
            errorWidget: (context, url, error) {
              AppLogger.e('MediaPreviewScreen', 'Error loading image: $error');
              return _buildImageErrorWidget(error.toString());
            },
          ),
        ),
      );
    } else if (fileType.contains('video')) {
      // Use the VideoPlayerWidget to play videos with responsive constraints
      return Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
          constraints: BoxConstraints(
            maxWidth: maxMediaWidth,
            maxHeight: maxMediaHeight,
          ),
          child: VideoPlayerWidget(videoUrl: widget.attachmentUrl),
        ),
      );
    } else if (fileType.contains('audio')) {
      // Audio player would be implemented here
      return Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
          constraints: BoxConstraints(maxWidth: maxMediaWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.audiotrack,
                size: 72,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              const Text('Audio player not implemented in this demo'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Open audio in external player
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Opening audio in external player'),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open in external player'),
              ),
            ],
          ),
        ),
      );
    } else if (fileType.contains('pdf')) {
      // PDF viewer would be implemented here
      return Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
          constraints: BoxConstraints(maxWidth: maxMediaWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.picture_as_pdf, size: 72, color: Colors.red),
              const SizedBox(height: 16),
              const Text('PDF viewer not implemented in this demo'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Open PDF in external viewer
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Opening PDF in external viewer'),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open in external viewer'),
              ),
            ],
          ),
        ),
      );
    } else {
      // Generic file preview
      return Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
          constraints: BoxConstraints(maxWidth: maxMediaWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getIconForFileType(fileType),
                size: 72,
                color: _getColorForFileType(fileType),
              ),
              const SizedBox(height: 16),
              Text(
                widget.fileName ?? _getDisplayName(),
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(fileType, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Open file in external app
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Opening file in external app'),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open in external app'),
              ),
            ],
          ),
        ),
      );
    }
  }

  String _getFileType() {
    if (widget.contentType != null) {
      return widget.contentType!;
    }

    final extension = widget.attachmentUrl.split('.').last.toLowerCase();

    if ([
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'svg',
      'bmp',
    ].contains(extension)) {
      return 'image';
    } else if ([
      'pdf',
      'doc',
      'docx',
      'xls',
      'xlsx',
      'ppt',
      'pptx',
      'txt',
    ].contains(extension)) {
      return 'document';
    } else if (['mp3', 'wav', 'ogg', 'aac', 'flac'].contains(extension)) {
      return 'audio';
    } else if (['mp4', 'mpeg', 'webm', 'mov', 'avi'].contains(extension)) {
      return 'video';
    } else {
      return 'other';
    }
  }

  String _getDisplayName() {
    if (widget.attachmentUrl.isEmpty) return '';

    try {
      final uri = Uri.parse(widget.attachmentUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        return pathSegments.last;
      }
    } catch (e) {
      AppLogger.e('MediaPreviewScreen', 'Error parsing URL: $e');
    }

    // Fallback: just use the last part of the URL
    final parts = widget.attachmentUrl.split('/');
    return parts.isNotEmpty ? parts.last : 'File';
  }

  IconData _getIconForFileType(String fileType) {
    if (fileType.contains('image')) {
      return Icons.image;
    } else if (fileType.contains('pdf')) {
      return Icons.picture_as_pdf;
    } else if (fileType.contains('doc')) {
      return Icons.description;
    } else if (fileType.contains('sheet') || fileType.contains('xls')) {
      return Icons.table_chart;
    } else if (fileType.contains('presentation') || fileType.contains('ppt')) {
      return Icons.slideshow;
    } else if (fileType.contains('audio')) {
      return Icons.audiotrack;
    } else if (fileType.contains('video')) {
      return Icons.videocam;
    } else if (fileType.contains('zip') ||
        fileType.contains('rar') ||
        fileType.contains('tar')) {
      return Icons.archive;
    } else if (fileType.contains('text') || fileType.contains('txt')) {
      return Icons.text_snippet;
    } else {
      return Icons.insert_drive_file;
    }
  }

  Color _getColorForFileType(String fileType) {
    if (fileType.contains('image')) {
      return Colors.blue;
    } else if (fileType.contains('pdf')) {
      return Colors.red;
    } else if (fileType.contains('doc')) {
      return Colors.indigo;
    } else if (fileType.contains('sheet') || fileType.contains('xls')) {
      return Colors.green;
    } else if (fileType.contains('presentation') || fileType.contains('ppt')) {
      return Colors.orange;
    } else if (fileType.contains('audio')) {
      return Colors.purple;
    } else if (fileType.contains('video')) {
      return Colors.pink;
    } else if (fileType.contains('zip') ||
        fileType.contains('rar') ||
        fileType.contains('tar')) {
      return Colors.brown;
    } else if (fileType.contains('text') || fileType.contains('txt')) {
      return Colors.teal;
    } else {
      return Colors.grey;
    }
  }
}
