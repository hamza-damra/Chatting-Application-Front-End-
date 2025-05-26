import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_room.dart';
import '../providers/chat_provider.dart';
import '../widgets/blocked_user_indicator.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ModernChatListItem extends StatelessWidget {
  final ChatRoom chatRoom;
  final int currentUserId;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ModernChatListItem({
    super.key,
    required this.chatRoom,
    required this.currentUserId,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGroup = !chatRoom.isPrivate;

    // Get the other user ID for blocking status check (for private chats)
    final otherUserId =
        chatRoom.isPrivate
            ? chatRoom.participantIds.firstWhere(
              (id) => id != currentUserId,
              orElse: () => -1,
            )
            : null;

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final roomIdString = chatRoom.id.toString();
        final unreadCount = chatProvider.getUnreadCount(roomIdString);

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
                    // Professional Avatar
                    _buildAvatar(
                      chatRoom: chatRoom,
                      isGroup: isGroup,
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
                                  chatRoom.name ??
                                      (isGroup ? 'Group Chat' : 'Private Chat'),
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
                              if (chatRoom.lastActivity != null)
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
                                    _formatTimestamp(chatRoom.lastActivity!),
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

                          // Subtitle and unread count
                          Row(
                            children: [
                              // Subtitle (last message or member count)
                              Expanded(
                                child: Text(
                                  _getSubtitle(chatRoom, isGroup),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 15,
                                    color:
                                        unreadCount > 0
                                            ? theme.colorScheme.onSurface
                                            : theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                    fontWeight:
                                        unreadCount > 0
                                            ? FontWeight.w500
                                            : FontWeight.w400,
                                    letterSpacing: -0.1,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Unread count badge
                              if (unreadCount > 0)
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
                                    unreadCount > 99
                                        ? '99+'
                                        : unreadCount.toString(),
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
        if (!isGroup && otherUserId != null && otherUserId != -1) {
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
    required ChatRoom chatRoom,
    required bool isGroup,
    required ThemeData theme,
  }) {
    final displayName = chatRoom.name ?? (isGroup ? 'G' : 'U');

    return Container(
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
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.8),
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
        child: Center(
          child: Text(
            displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
            style: TextStyle(
              color:
                  isGroup ? Colors.white : theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
              fontSize: 22,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  String _getSubtitle(ChatRoom chatRoom, bool isGroup) {
    if (isGroup) {
      return '${chatRoom.participantIds.length} members${chatRoom.description != null ? ' • ${chatRoom.description}' : ''}';
    } else {
      return chatRoom.description ?? 'Private conversation';
    }
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
