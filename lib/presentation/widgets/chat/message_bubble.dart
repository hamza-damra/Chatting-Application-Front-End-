import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/message_model.dart';
import '../../../widgets/video_player_widget.dart';
import '../../../widgets/chat_image_thumbnail.dart';
import '../../../utils/url_utils.dart';
import '../../../utils/logger.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const MessageBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Enhanced color scheme for better visual hierarchy and modern design
    final backgroundColor =
        isMe
            ? theme.colorScheme.primary
            : (isDark
                ? theme.colorScheme.surfaceContainerHigh
                : theme.colorScheme.surfaceContainerLowest);

    final textColor =
        isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;

    final timestampColor =
        isMe
            ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
            : theme.colorScheme.onSurfaceVariant;

    final senderNameColor =
        isDark
            ? theme.colorScheme.primary.withValues(alpha: 0.9)
            : theme.colorScheme.primary.withValues(alpha: 0.8);

    // Modern gradient effect for sent messages
    final gradient =
        isMe
            ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.9),
              ],
            )
            : null;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 3,
          bottom: 3,
          left: isMe ? 64 : 12,
          right: isMe ? 12 : 64,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
          minWidth: 80,
        ),
        decoration: BoxDecoration(
          color: gradient == null ? backgroundColor : null,
          gradient: gradient,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(24),
            topRight: const Radius.circular(24),
            bottomLeft: Radius.circular(isMe ? 24 : 6),
            bottomRight: Radius.circular(isMe ? 6 : 24),
          ),
          border: Border.all(
            color:
                isMe
                    ? theme.colorScheme.primary.withValues(alpha: 0.3)
                    : (isDark
                        ? theme.colorScheme.outline.withValues(alpha: 0.4)
                        : theme.colorScheme.outline.withValues(alpha: 0.2)),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(
                alpha: isDark ? 0.3 : 0.1,
              ),
              blurRadius: isDark ? 8 : 4,
              offset: Offset(0, isDark ? 2 : 1),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(24),
            topRight: const Radius.circular(24),
            bottomLeft: Radius.circular(isMe ? 24 : 6),
            bottomRight: Radius.circular(isMe ? 6 : 24),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      message.sender.fullName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: senderNameColor,
                        fontSize: 12,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                _buildMessageContent(context, textColor),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(message.sentAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: timestampColor,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 8),
                      _buildStatusIcon(context, timestampColor),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, Color textColor) {
    final theme = Theme.of(context);

    AppLogger.i(
      'MessageBubble',
      'Building message content: id=${message.id}, type=${message.type}, content=${message.content.substring(0, message.content.length.clamp(0, 50))}...',
    );

    switch (message.type) {
      case MessageContentType.text:
        return Text(
          message.content,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: textColor,
            height: 1.5,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.1,
          ),
          textAlign: TextAlign.left,
        );
      case MessageContentType.image:
        // Get the proper image URL - could be from content or metadata
        String imageUrl = message.content;

        AppLogger.i(
          'MessageBubble',
          'Processing image message: id=${message.id}, content=${message.content}, metadata=${message.metadata}',
        );

        // Check if we have an attachment URL in metadata (from WebSocket uploads)
        if (message.metadata != null) {
          if (message.metadata!['attachmentUrl'] != null) {
            imageUrl = message.metadata!['attachmentUrl'];
            AppLogger.i(
              'MessageBubble',
              'Using attachmentUrl from metadata: $imageUrl',
            );
          } else if (message.metadata!['uri'] != null) {
            imageUrl = message.metadata!['uri'];
            AppLogger.i('MessageBubble', 'Using uri from metadata: $imageUrl');
          } else if (message.metadata!['url'] != null) {
            imageUrl = message.metadata!['url'];
            AppLogger.i('MessageBubble', 'Using url from metadata: $imageUrl');
          }
        }

        // If imageUrl is empty or null, try to use content
        if (imageUrl.isEmpty) {
          imageUrl = message.content;
          AppLogger.w('MessageBubble', 'Using content as imageUrl: $imageUrl');
        }

        // If still empty, show error
        if (imageUrl.isEmpty) {
          AppLogger.e(
            'MessageBubble',
            'No valid image URL found for message ${message.id}',
          );
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.onErrorContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Image URL not found',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Normalize the URL if needed
        if (!imageUrl.startsWith('http://') &&
            !imageUrl.startsWith('https://')) {
          imageUrl = UrlUtils.normalizeImageUrl(imageUrl);
          AppLogger.i('MessageBubble', 'Normalized image URL: $imageUrl');
        }

        AppLogger.i(
          'MessageBubble',
          'Displaying image with final URL: $imageUrl',
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Use ChatImageThumbnail which handles the tap and viewer automatically
            ChatImageThumbnail(
              imageUrl: imageUrl,
              heroTag: 'image-${message.id}',
              isCurrentUser: isMe,
              width: 240,
              height: 180,
            ),
            if (message.metadata?['caption'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  message.metadata!['caption'],
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    height: 1.4,
                  ),
                ),
              ),
          ],
        );
      case MessageContentType.file:
        return Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.insert_drive_file,
                size: 24,
                color: textColor.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.metadata?['name'] ?? 'File',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatFileSize(message.metadata?['size'] ?? 0),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: textColor.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case MessageContentType.video:
        // Get the proper video URL - could be from content or metadata
        String videoUrl = message.content;

        // Check if we have an attachment URL in metadata (from WebSocket uploads)
        if (message.metadata != null &&
            message.metadata!['attachmentUrl'] != null) {
          videoUrl = message.metadata!['attachmentUrl'];
        }

        // If content looks like just a filename, try to construct the URL
        if (!videoUrl.contains('/') && !videoUrl.startsWith('http')) {
          // This is likely just a filename, construct the server URL
          videoUrl = UrlUtils.normalizeImageUrl(
            videoUrl,
          ); // UrlUtils works for videos too
        } else if (videoUrl.contains('/') && !videoUrl.startsWith('http')) {
          // This is a relative path, normalize it
          videoUrl = UrlUtils.normalizeImageUrl(videoUrl);
        }

        AppLogger.i('MessageBubble', 'Displaying video with URL: $videoUrl');
        AppLogger.i(
          'MessageBubble',
          'Video message metadata: ${message.metadata}',
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 240,
              child: VideoThumbnail(
                videoUrl: videoUrl,
                heroTag: 'video-${message.id}',
                isCurrentUser: isMe,
              ),
            ),
            if (message.metadata?['caption'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  message.metadata!['caption'],
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    height: 1.4,
                  ),
                ),
              ),
          ],
        );
      default:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: textColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: textColor.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.help_outline,
                size: 18,
                color: textColor.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Unsupported message type',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textColor.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildStatusIcon(BuildContext context, Color color) {
    final theme = Theme.of(context);

    switch (message.status) {
      case MessageStatus.sending:
        return Icon(
          Icons.schedule,
          size: 14,
          color: color.withValues(alpha: 0.6),
        );
      case MessageStatus.sent:
        return Icon(Icons.check, size: 14, color: color.withValues(alpha: 0.7));
      case MessageStatus.delivered:
        return Icon(
          Icons.done_all,
          size: 14,
          color: color.withValues(alpha: 0.7),
        );
      case MessageStatus.read:
        return Icon(
          Icons.done_all,
          size: 14,
          color: theme.colorScheme.tertiary,
        );
      case MessageStatus.failed:
        return Icon(
          Icons.error_outline,
          size: 14,
          color: theme.colorScheme.error,
        );
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
