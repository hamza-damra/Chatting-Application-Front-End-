import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/message_model.dart';
import '../../../core/constants/app_theme.dart';
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

    // Enhanced color scheme for better visual hierarchy
    final backgroundColor =
        isMe
            ? theme.colorScheme.primary
            : (isDark
                ? theme.colorScheme.surfaceContainerHighest
                : const Color(0xFFF1F3F4));

    final textColor =
        isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;

    final timestampColor =
        isMe
            ? theme.colorScheme.onPrimary.withAlpha(179) // 70% opacity
            : theme.colorScheme.onSurfaceVariant;

    final senderNameColor =
        isDark
            ? theme.colorScheme.primary
            : theme.colorScheme.primary.withAlpha(204); // 80% opacity

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 2,
          bottom: 2,
          left: isMe ? 48 : 0,
          right: isMe ? 0 : 48,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(
                isDark ? 51 : 26,
              ), // 0.2 : 0.1 opacity
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    message.sender.fullName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: senderNameColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              _buildMessageContent(context, textColor),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm').format(message.sentAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: timestampColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 6),
                    _buildStatusIcon(timestampColor),
                  ],
                ],
              ),
            ],
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
            height: 1.4,
          ),
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
              color: Colors.grey[200], // Use neutral color instead of red
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.grey[700],
                ), // Use neutral color
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Image URL not found',
                    style: TextStyle(
                      color: Colors.grey[800],
                    ), // Use neutral color
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
            const Icon(Icons.insert_drive_file, size: 40),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.metadata?['name'] ?? 'File',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          isMe
                              ? AppTheme.sentMessageTextColor
                              : AppTheme.receivedMessageTextColor,
                    ),
                  ),
                  Text(
                    _formatFileSize(message.metadata?['size'] ?? 0),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
            VideoThumbnail(
              videoUrl: videoUrl,
              heroTag: 'video-${message.id}',
              isCurrentUser: isMe,
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
        return Text(
          'Unsupported message type',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: textColor.withAlpha(179), // 70% opacity
            fontStyle: FontStyle.italic,
            height: 1.4,
          ),
        );
    }
  }

  Widget _buildStatusIcon(Color color) {
    switch (message.status) {
      case MessageStatus.sending:
        return Icon(
          Icons.access_time,
          size: 12,
          color: color.withAlpha(153),
        ); // 60% opacity
      case MessageStatus.sent:
        return Icon(
          Icons.check,
          size: 12,
          color: color.withAlpha(179),
        ); // 70% opacity
      case MessageStatus.delivered:
        return Icon(
          Icons.done_all,
          size: 12,
          color: color.withAlpha(179),
        ); // 70% opacity
      case MessageStatus.read:
        return Icon(Icons.done_all, size: 12, color: Colors.blue.shade400);
      case MessageStatus.failed:
        return const Icon(Icons.error_outline, size: 12, color: Colors.red);
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
