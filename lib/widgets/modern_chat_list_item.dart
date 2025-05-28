import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_room.dart';
import '../providers/chat_provider.dart';
import '../providers/user_status_provider.dart';
import '../widgets/blocked_user_indicator.dart';
import 'package:intl/intl.dart';

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

    return Consumer2<ChatProvider, UserStatusProvider>(
      builder: (context, chatProvider, userStatusProvider, child) {
        final roomIdString = chatRoom.id.toString();
        final unreadCount = chatProvider.getUnreadCount(roomIdString);

        // Get display name using the new method
        final displayName = chatRoom.getDisplayName(
          currentUserId,
          chatProvider.getUserNameById,
        );

        // Get online status for private chats
        bool isOnline = false;
        if (chatRoom.isPrivate && otherUserId != null && otherUserId != -1) {
          isOnline = userStatusProvider.isUserOnline(otherUserId.toString());
          // Subscribe to user status updates if not already subscribed
          WidgetsBinding.instance.addPostFrameCallback((_) {
            userStatusProvider.subscribeToUserStatus(otherUserId.toString());
          });
        }

        final chatListWidget = Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              borderRadius: BorderRadius.circular(12),
              splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Professional Avatar with Online Status
                    _buildAvatar(
                      chatRoom: chatRoom,
                      isGroup: isGroup,
                      isOnline: isOnline,
                      theme: theme,
                    ),
                    const SizedBox(width: 16),

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
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    unreadCount > 99
                                        ? '99+'
                                        : unreadCount.toString(),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onPrimary,
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
    required bool isOnline,
    required ThemeData theme,
  }) {
    return Stack(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              isGroup ? Icons.group_rounded : Icons.person_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        // Online status indicator for private chats
        if (!isGroup)
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: isOnline ? const Color(0xFF4CAF50) : Colors.grey[400],
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.surface, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: (isOnline
                            ? const Color(0xFF4CAF50)
                            : Colors.grey[400]!)
                        .withValues(alpha: 0.3),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _getSubtitle(ChatRoom chatRoom, bool isGroup) {
    // Check if we have last message data
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

    // Fallback to original behavior if no last message
    if (isGroup) {
      return '${chatRoom.participantIds.length} members${chatRoom.description != null ? ' • ${chatRoom.description}' : ''}';
    } else {
      return 'No messages yet';
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
