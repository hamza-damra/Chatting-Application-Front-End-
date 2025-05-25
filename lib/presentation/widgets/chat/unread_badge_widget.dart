import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../theme/app_theme.dart';

/// Widget that displays the total unread message count across all chat rooms
class UnreadBadgeWidget extends StatelessWidget {
  final double? size;
  final Color? backgroundColor;
  final Color? textColor;
  final bool showZero;

  const UnreadBadgeWidget({
    super.key,
    this.size,
    this.backgroundColor,
    this.textColor,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        // Calculate total unread count across all rooms
        int totalUnreadCount = 0;

        // Count unread messages from private chats
        for (final room in chatProvider.privateChatRooms) {
          totalUnreadCount += chatProvider.getUnreadCount(room.id.toString());
        }

        // Count unread messages from group chats
        for (final room in chatProvider.groupChatRooms) {
          totalUnreadCount += chatProvider.getUnreadCount(room.id.toString());
        }

        // Don't show badge if count is 0 and showZero is false
        if (totalUnreadCount == 0 && !showZero) {
          return const SizedBox.shrink();
        }

        final badgeSize = size ?? 20.0;
        final bgColor = backgroundColor ?? AppTheme.primaryColor;
        final txtColor = textColor ?? Colors.white;

        return Container(
          constraints: BoxConstraints(
            minWidth: badgeSize,
            minHeight: badgeSize,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(badgeSize / 2),
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: Center(
            child: Text(
              totalUnreadCount > 99 ? '99+' : totalUnreadCount.toString(),
              style: TextStyle(
                color: txtColor,
                fontSize: badgeSize * 0.6,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}

/// Widget that displays unread count for a specific room
class RoomUnreadBadgeWidget extends StatelessWidget {
  final String roomId;
  final double? size;
  final Color? backgroundColor;
  final Color? textColor;
  final bool showZero;

  const RoomUnreadBadgeWidget({
    super.key,
    required this.roomId,
    this.size,
    this.backgroundColor,
    this.textColor,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final unreadCount = chatProvider.getUnreadCount(roomId);

        // Don't show badge if count is 0 and showZero is false
        if (unreadCount == 0 && !showZero) {
          return const SizedBox.shrink();
        }

        final badgeSize = size ?? 18.0;
        final bgColor = backgroundColor ?? AppTheme.primaryColor;
        final txtColor = textColor ?? Colors.white;

        return Container(
          constraints: BoxConstraints(
            minWidth: badgeSize,
            minHeight: badgeSize,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(badgeSize / 2),
          ),
          child: Center(
            child: Text(
              unreadCount > 99 ? '99+' : unreadCount.toString(),
              style: TextStyle(
                color: txtColor,
                fontSize: badgeSize * 0.65,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}

/// Widget that shows a pulsing animation for new unread messages
class PulsingUnreadBadgeWidget extends StatefulWidget {
  final String roomId;
  final double? size;
  final Color? backgroundColor;
  final Color? textColor;

  const PulsingUnreadBadgeWidget({
    super.key,
    required this.roomId,
    this.size,
    this.backgroundColor,
    this.textColor,
  });

  @override
  State<PulsingUnreadBadgeWidget> createState() =>
      _PulsingUnreadBadgeWidgetState();
}

class _PulsingUnreadBadgeWidgetState extends State<PulsingUnreadBadgeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Start pulsing animation
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final unreadCount = chatProvider.getUnreadCount(widget.roomId);

        if (unreadCount == 0) {
          return const SizedBox.shrink();
        }

        return AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: RoomUnreadBadgeWidget(
                roomId: widget.roomId,
                size: widget.size,
                backgroundColor: widget.backgroundColor,
                textColor: widget.textColor,
              ),
            );
          },
        );
      },
    );
  }
}
