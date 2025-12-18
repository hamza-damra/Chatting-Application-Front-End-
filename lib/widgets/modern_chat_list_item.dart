import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_room.dart';
import '../providers/chat_provider.dart';
import '../providers/user_status_provider.dart';
import '../widgets/blocked_user_indicator.dart';
import '../design_system/components/app_avatar.dart';
import '../design_system/components/app_badge.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import 'package:intl/intl.dart';

/// A modern chat list item component that displays chat room information
/// including avatar, name, last message preview, timestamp, unread badge,
/// and online status indicator.
///
/// Requirements: 4.1, 5.3
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
    final isDark = theme.brightness == Brightness.dark;
    final colors = isDark ? const DarkAppColors() : const LightAppColors();
    final isGroup = !chatRoom.isPrivate;

    // Get responsive horizontal margin for list items
    final horizontalMargin = ResponsiveLayout.value<double>(
      context: context,
      mobile: AppSpacing.xl,
      tablet: AppSpacing.xxl,
      desktop: AppSpacing.xxxl,
    );

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

        final chatListWidget = Semantics(
          button: true,
          label: '$displayName chat${unreadCount > 0 ? ', $unreadCount unread messages' : ''}',
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: horizontalMargin,
              vertical: AppSpacing.sm,
            ),
            constraints: const BoxConstraints(
              minWidth: 280, // Minimum width to prevent layout issues
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: colors.outline.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: InkWell(
                onTap: onTap,
                onLongPress: onLongPress,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                splashColor: colors.primary.withValues(alpha: 0.1),
                highlightColor: colors.primary.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      // Avatar using AppAvatar component
                      AppAvatar(
                        name: displayName,
                        size: AppAvatarSize.medium,
                        showOnlineIndicator: !isGroup,
                        isOnline: isOnline,
                        semanticLabel: '$displayName avatar',
                      ),
                      const SizedBox(width: AppSpacing.lg),

                      // Chat info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Chat name - use Flexible to prevent overflow
                                Flexible(
                                  fit: FlexFit.tight,
                                  child: Text(
                                    displayName,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 17,
                                      letterSpacing: -0.2,
                                      color: colors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                // Timestamp - fixed width, doesn't expand
                                if (chatRoom.lastActivity != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: AppSpacing.sm),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.surfaceElevated,
                                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                      ),
                                      child: Text(
                                        _formatTimestamp(chatRoom.lastActivity!),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),

                            // Subtitle and unread count
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Subtitle (last message or member count) - use Flexible to prevent overflow
                                Flexible(
                                  fit: FlexFit.tight,
                                  child: Text(
                                    _getSubtitle(chatRoom, isGroup),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 15,
                                      color: unreadCount > 0
                                          ? colors.textPrimary
                                          : colors.textSecondary,
                                      fontWeight: unreadCount > 0
                                          ? FontWeight.w500
                                          : FontWeight.w400,
                                      letterSpacing: -0.1,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                // Unread count badge using AppBadge component - fixed size
                                if (unreadCount > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(left: AppSpacing.md),
                                    child: AppBadge.count(
                                      count: unreadCount,
                                      type: AppBadgeType.primary,
                                      size: AppBadgeSize.medium,
                                      semanticLabel: '$unreadCount unread messages',
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
