import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/chat_room_model.dart';
import '../../../providers/chat_provider.dart';
import '../../../widgets/blocked_user_indicator.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatListItem extends StatelessWidget {
  final ChatRoomModel chatRoom;
  final String currentUserId;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ChatListItem({
    super.key,
    required this.chatRoom,
    required this.currentUserId,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = chatRoom.getDisplayName(currentUserId);
    final avatarUrl = chatRoom.getAvatarUrl(currentUserId);
    final isGroup = chatRoom.type == ChatRoomType.group;
    final isOnline = !isGroup && chatRoom.isUserOnline(currentUserId);
    final otherUserId = chatRoom.getOtherUserId(currentUserId);

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        // Get real-time unread count from ChatProvider
        final realTimeUnreadCount = chatProvider.getUnreadCount(chatRoom.id);

        final chatListWidget = Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.08),
              width: 0.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              borderRadius: BorderRadius.circular(20),
              splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Professional Avatar with Status Indicator
                    _buildAvatar(
                      displayName: displayName,
                      avatarUrl: avatarUrl,
                      isGroup: isGroup,
                      isOnline: isOnline,
                      theme: theme,
                    ),
                    const SizedBox(width: 18),

                    // Chat info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Chat name
                              Expanded(
                                child: Text(
                                  displayName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 17,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              // Timestamp
                              if (chatRoom.lastMessageTime != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _formatTimestamp(chatRoom.lastMessageTime!),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Last message and unread count
                          Row(
                            children: [
                              // Last message
                              Expanded(
                                child: Text(
                                  _getLastMessageDisplay(chatRoom, isGroup),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 15,
                                    color:
                                        realTimeUnreadCount > 0
                                            ? theme.colorScheme.onSurface
                                            : theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                    fontWeight:
                                        realTimeUnreadCount > 0
                                            ? FontWeight.w500
                                            : FontWeight.w400,
                                    letterSpacing: -0.1,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Unread count (using real-time data from ChatProvider)
                              if (realTimeUnreadCount > 0)
                                Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 24,
                                    minHeight: 24,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        theme.colorScheme.primary,
                                        theme.colorScheme.primary.withValues(
                                          alpha: 0.8,
                                        ),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    realTimeUnreadCount > 99
                                        ? '99+'
                                        : realTimeUnreadCount.toString(),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Wrap with blocked user indicator for private chats
        if (!isGroup && otherUserId != null) {
          return BlockedUserIndicator(
            otherUserId: otherUserId,
            child: chatListWidget,
          );
        }

        return chatListWidget;
      },
    );
  }

  Widget _buildAvatar({
    required String displayName,
    required String avatarUrl,
    required bool isGroup,
    required bool isOnline,
    required ThemeData theme,
  }) {
    return Stack(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient:
                isGroup
                    ? LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                        theme.colorScheme.tertiary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0.0, 0.6, 1.0],
                    )
                    : LinearGradient(
                      colors: [
                        theme.colorScheme.primaryContainer,
                        theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.8,
                        ),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child:
                avatarUrl.isNotEmpty
                    ? CachedNetworkImage(
                      imageUrl: avatarUrl,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            color: theme.colorScheme.primaryContainer,
                            child: Icon(
                              isGroup ? Icons.group : Icons.person,
                              color: theme.colorScheme.onPrimaryContainer,
                              size: 28,
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            color: theme.colorScheme.primaryContainer,
                            child: Icon(
                              isGroup ? Icons.group : Icons.person,
                              color: theme.colorScheme.onPrimaryContainer,
                              size: 28,
                            ),
                          ),
                    )
                    : Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient:
                            isGroup
                                ? LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.secondary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                                : null,
                        color:
                            !isGroup
                                ? theme.colorScheme.primaryContainer
                                : null,
                      ),
                      child: Center(
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color:
                                isGroup
                                    ? Colors.white
                                    : theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                            fontSize: 22,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
          ),
        ),
        // Online status indicator for private chats
        if (!isGroup)
          Positioned(
            right: 4,
            bottom: 4,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isOnline ? const Color(0xFF4CAF50) : Colors.grey[400],
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.surface, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: (isOnline
                            ? const Color(0xFF4CAF50)
                            : Colors.grey[400]!)
                        .withValues(alpha: 0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _getLastMessageDisplay(ChatRoomModel chatRoom, bool isGroup) {
    final lastMessage = chatRoom.lastMessage;
    final lastMessageSender = chatRoom.lastMessageSender;

    if (lastMessage != null && lastMessage.isNotEmpty) {
      if (isGroup &&
          lastMessageSender != null &&
          lastMessageSender.isNotEmpty) {
        // For group chats, show "SenderName: message"
        return '$lastMessageSender: $lastMessage';
      } else {
        // For private chats, just show the message content
        return lastMessage;
      }
    }

    return 'No messages yet';
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (messageDate == today) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(timestamp).inDays < 7) {
      return DateFormat('EEEE').format(timestamp); // Day name
    } else {
      return DateFormat('dd/MM/yyyy').format(timestamp);
    }
  }
}
