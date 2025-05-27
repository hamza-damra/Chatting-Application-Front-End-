import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class CustomChatMessage extends StatelessWidget {
  final types.Message message;
  final String currentUserId;
  final Widget child;

  const CustomChatMessage({
    super.key,
    required this.message,
    required this.currentUserId,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Check if this is a message from the current user
    final isCurrentUser = message.author.id == currentUserId;

    // Use theme colors for better consistency
    final theme = Theme.of(context);
    final backgroundColor =
        isCurrentUser
            ? theme.colorScheme.primary
            : (theme.brightness == Brightness.dark
                ? theme.colorScheme.surfaceContainerHigh
                : theme.colorScheme.surfaceContainerLowest);
    final textColor =
        isCurrentUser
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface;

    // Create a custom message bubble with the appropriate colors
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DefaultTextStyle(
        style: TextStyle(color: textColor, fontSize: 16),
        child: child,
      ),
    );
  }
}
