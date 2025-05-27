import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';
import '../widgets/chat_image_thumbnail.dart';
import '../widgets/video_player_widget.dart';
import '../utils/url_utils.dart';
import '../utils/logger.dart';

/// Modern message bubble widget with consistent theming and animations
class ModernMessageBubble extends StatefulWidget {
  final Message message;
  final bool isCurrentUser;
  final bool showSenderName;
  final bool showTimestamp;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ModernMessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.showSenderName = true,
    this.showTimestamp = true,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<ModernMessageBubble> createState() => _ModernMessageBubbleState();
}

class _ModernMessageBubbleState extends State<ModernMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin:
          widget.isCurrentUser ? const Offset(0.3, 0) : const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // Start animation
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              alignment:
                  widget.isCurrentUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
              child: _buildMessageContainer(theme, isDark),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageContainer(ThemeData theme, bool isDark) {
    return Align(
      alignment:
          widget.isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: widget.isCurrentUser ? 80 : 16,
          right: widget.isCurrentUser ? 16 : 80,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
          minWidth: 60,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: _getBorderRadius(),
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            borderRadius: _getBorderRadius(),
            splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
            child: Container(
              decoration: _getMessageDecoration(theme, isDark),
              child: _buildMessageContent(theme, isDark),
            ),
          ),
        ),
      ),
    );
  }

  BorderRadius _getBorderRadius() {
    return BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(widget.isCurrentUser ? 20 : 4),
      bottomRight: Radius.circular(widget.isCurrentUser ? 4 : 20),
    );
  }

  BoxDecoration _getMessageDecoration(ThemeData theme, bool isDark) {
    if (widget.isCurrentUser) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: _getBorderRadius(),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      );
    } else {
      return BoxDecoration(
        color:
            isDark
                ? theme.colorScheme.surfaceContainerHigh
                : theme.colorScheme.surfaceContainerLowest,
        borderRadius: _getBorderRadius(),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(
            alpha: isDark ? 0.3 : 0.15,
          ),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: isDark ? 6 : 4,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      );
    }
  }

  Widget _buildMessageContent(ThemeData theme, bool isDark) {
    final textColor =
        widget.isCurrentUser
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface;

    final timestampColor =
        widget.isCurrentUser
            ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
            : theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sender name for group chats
          if (widget.showSenderName && !widget.isCurrentUser)
            _buildSenderName(theme),

          // Message content
          _buildContentByType(theme, textColor),

          // Timestamp and status
          if (widget.showTimestamp) _buildTimestampRow(theme, timestampColor),
        ],
      ),
    );
  }

  Widget _buildSenderName(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        widget.message.senderName ?? 'Unknown',
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
          fontSize: 12,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildTimestampRow(ThemeData theme, Color timestampColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTimestamp(widget.message.sentAt),
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: timestampColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (widget.isCurrentUser) ...[
            const SizedBox(width: 6),
            _buildStatusIcon(theme, timestampColor),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon(ThemeData theme, Color color) {
    // This would need to be adapted based on your Message model's status field
    return Icon(Icons.done_all, size: 14, color: color);
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';
    return DateFormat('HH:mm').format(timestamp);
  }

  Widget _buildContentByType(ThemeData theme, Color textColor) {
    final contentType = widget.message.contentType?.toLowerCase() ?? '';

    // Handle different content types
    if (contentType.startsWith('image/') || _isImageContent()) {
      return _buildImageContent(theme, textColor);
    } else if (contentType.startsWith('video/') || _isVideoContent()) {
      return _buildVideoContent(theme, textColor);
    } else if (contentType.startsWith('audio/') || _isAudioContent()) {
      return _buildAudioContent(theme, textColor);
    } else if (_isFileContent()) {
      return _buildFileContent(theme, textColor);
    } else {
      return _buildTextContent(theme, textColor);
    }
  }

  bool _isImageContent() {
    final content = widget.message.content ?? '';
    final attachmentUrl = widget.message.attachmentUrl ?? '';
    return content.contains('.jpg') ||
        content.contains('.jpeg') ||
        content.contains('.png') ||
        content.contains('.gif') ||
        content.contains('.webp') ||
        attachmentUrl.contains('.jpg') ||
        attachmentUrl.contains('.jpeg') ||
        attachmentUrl.contains('.png') ||
        attachmentUrl.contains('.gif') ||
        attachmentUrl.contains('.webp');
  }

  bool _isVideoContent() {
    final content = widget.message.content ?? '';
    final attachmentUrl = widget.message.attachmentUrl ?? '';
    return content.contains('.mp4') ||
        content.contains('.mov') ||
        content.contains('.avi') ||
        content.contains('.mkv') ||
        attachmentUrl.contains('.mp4') ||
        attachmentUrl.contains('.mov') ||
        attachmentUrl.contains('.avi') ||
        attachmentUrl.contains('.mkv');
  }

  bool _isAudioContent() {
    final content = widget.message.content ?? '';
    final attachmentUrl = widget.message.attachmentUrl ?? '';
    return content.contains('.mp3') ||
        content.contains('.wav') ||
        content.contains('.m4a') ||
        content.contains('.aac') ||
        attachmentUrl.contains('.mp3') ||
        attachmentUrl.contains('.wav') ||
        attachmentUrl.contains('.m4a') ||
        attachmentUrl.contains('.aac');
  }

  bool _isFileContent() {
    final contentType = widget.message.contentType?.toLowerCase() ?? '';
    return contentType.startsWith('application/') ||
        contentType.startsWith('text/') ||
        widget.message.attachmentUrl?.isNotEmpty == true;
  }

  Widget _buildTextContent(ThemeData theme, Color textColor) {
    final content = widget.message.content ?? '';
    if (content.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: textColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: textColor.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Text(
              'Empty message',
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Text(
      content,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: textColor,
        height: 1.4,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
      ),
    );
  }

  Widget _buildImageContent(ThemeData theme, Color textColor) {
    String imageUrl = _getImageUrl();

    if (imageUrl.isEmpty) {
      return _buildErrorContent(
        theme,
        textColor,
        'Image not found',
        Icons.image_not_supported,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ChatImageThumbnail(
            imageUrl: imageUrl,
            heroTag: 'image-${widget.message.id}',
            isCurrentUser: widget.isCurrentUser,
            width: 240,
            height: 180,
          ),
        ),
        if (widget.message.content?.isNotEmpty == true &&
            !widget.message.content!.contains('http') &&
            !_isImageUrl(widget.message.content!))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              widget.message.content!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                height: 1.4,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVideoContent(ThemeData theme, Color textColor) {
    String videoUrl = _getVideoUrl();

    if (videoUrl.isEmpty) {
      return _buildErrorContent(
        theme,
        textColor,
        'Video not found',
        Icons.videocam_off,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 240,
            child: VideoThumbnail(
              videoUrl: videoUrl,
              heroTag: 'video-${widget.message.id}',
              isCurrentUser: widget.isCurrentUser,
            ),
          ),
        ),
        if (widget.message.content?.isNotEmpty == true &&
            !widget.message.content!.contains('http') &&
            !_isVideoUrl(widget.message.content!))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              widget.message.content!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                height: 1.4,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAudioContent(ThemeData theme, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.audiotrack,
              size: 24,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Audio Message',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap to play',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.play_circle_outline,
            size: 32,
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildFileContent(ThemeData theme, Color textColor) {
    final fileName = _getFileName();
    final fileSize = _getFileSize();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getFileIcon(),
              size: 24,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (fileSize.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    fileSize,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.download,
            size: 20,
            color: textColor.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(
    ThemeData theme,
    Color textColor,
    String message,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getImageUrl() {
    if (widget.message.attachmentUrl?.isNotEmpty == true) {
      return UrlUtils.normalizeImageUrl(widget.message.attachmentUrl!);
    }
    if (widget.message.content?.contains('http') == true) {
      return widget.message.content!;
    }
    if (widget.message.content?.isNotEmpty == true &&
        _isImageUrl(widget.message.content!)) {
      return UrlUtils.normalizeImageUrl(widget.message.content!);
    }
    return '';
  }

  String _getVideoUrl() {
    if (widget.message.attachmentUrl?.isNotEmpty == true) {
      return UrlUtils.normalizeImageUrl(widget.message.attachmentUrl!);
    }
    if (widget.message.content?.contains('http') == true) {
      return widget.message.content!;
    }
    if (widget.message.content?.isNotEmpty == true &&
        _isVideoUrl(widget.message.content!)) {
      return UrlUtils.normalizeImageUrl(widget.message.content!);
    }
    return '';
  }

  String _getFileName() {
    // Try to extract filename from various sources
    if (widget.message.attachmentUrl?.isNotEmpty == true) {
      final url = widget.message.attachmentUrl!;
      final parts = url.split('/');
      if (parts.isNotEmpty) {
        return parts.last;
      }
    }

    if (widget.message.content?.isNotEmpty == true) {
      final content = widget.message.content!;
      if (content.contains('/')) {
        final parts = content.split('/');
        return parts.last;
      }
      return content;
    }

    return 'Unknown file';
  }

  String _getFileSize() {
    // This would need to be implemented based on your message model
    // For now, return empty string
    return '';
  }

  IconData _getFileIcon() {
    final fileName = _getFileName().toLowerCase();
    if (fileName.contains('.pdf')) {
      return Icons.picture_as_pdf;
    }
    if (fileName.contains('.doc') || fileName.contains('.docx')) {
      return Icons.description;
    }
    if (fileName.contains('.xls') || fileName.contains('.xlsx')) {
      return Icons.table_chart;
    }
    if (fileName.contains('.ppt') || fileName.contains('.pptx')) {
      return Icons.slideshow;
    }
    if (fileName.contains('.zip') || fileName.contains('.rar')) {
      return Icons.archive;
    }
    if (fileName.contains('.txt')) {
      return Icons.text_snippet;
    }
    return Icons.insert_drive_file;
  }

  bool _isImageUrl(String url) {
    return url.contains('.jpg') ||
        url.contains('.jpeg') ||
        url.contains('.png') ||
        url.contains('.gif') ||
        url.contains('.webp');
  }

  bool _isVideoUrl(String url) {
    return url.contains('.mp4') ||
        url.contains('.mov') ||
        url.contains('.avi') ||
        url.contains('.mkv');
  }
}
