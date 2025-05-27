import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../providers/chat_provider.dart';
import '../widgets/modern_message_bubble.dart';
import '../widgets/shimmer_widgets.dart';

/// Example of how to integrate the ModernMessageBubble into existing chat screens
/// This shows the recommended way to replace existing message widgets
class ModernChatIntegrationExample extends StatefulWidget {
  final String chatRoomId;
  final String currentUserId;
  final List<Message> messages;

  const ModernChatIntegrationExample({
    super.key,
    required this.chatRoomId,
    required this.currentUserId,
    required this.messages,
  });

  @override
  State<ModernChatIntegrationExample> createState() => _ModernChatIntegrationExampleState();
}

class _ModernChatIntegrationExampleState extends State<ModernChatIntegrationExample> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    // Simulate loading more messages
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Modern Chat'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(theme),
          ),
          _buildChatInput(theme),
        ],
      ),
    );
  }

  Widget _buildMessagesList(ThemeData theme) {
    if (widget.messages.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      itemCount: widget.messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        // Show loading indicator at the top when loading more
        if (index == widget.messages.length) {
          return _buildLoadingIndicator();
        }

        final message = widget.messages[index];
        final isCurrentUser = message.senderId.toString() == widget.currentUserId;
        
        // Determine if we should show sender name (for group chats)
        final showSenderName = _shouldShowSenderName(index);
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: ModernMessageBubble(
            message: message,
            isCurrentUser: isCurrentUser,
            showSenderName: showSenderName && !isCurrentUser,
            showTimestamp: true,
            onTap: () => _onMessageTap(message),
            onLongPress: () => _onMessageLongPress(message),
          ),
        );
      },
    );
  }

  bool _shouldShowSenderName(int index) {
    if (index == 0) return true;
    
    final currentMessage = widget.messages[index];
    final previousMessage = widget.messages[index - 1];
    
    // Show sender name if different from previous message sender
    return currentMessage.senderId != previousMessage.senderId;
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ShimmerWidgets.listItemShimmer(context: context),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No messages yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation by sending a message',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChatInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send),
              color: Colors.white,
              iconSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  void _onMessageTap(Message message) {
    // Handle message tap (e.g., show details, copy text, etc.)
    print('Message tapped: ${message.id}');
  }

  void _onMessageLongPress(Message message) {
    // Handle message long press (e.g., show context menu)
    _showMessageContextMenu(message);
  }

  void _showMessageContextMenu(Message message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                // Copy message content
              },
            ),
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                // Reply to message
              },
            ),
            if (message.senderId.toString() == widget.currentUserId)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  // Delete message
                },
              ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    // Handle sending message
    print('Send message');
  }
}

/// Integration instructions:
/// 
/// 1. Replace existing message widgets with ModernMessageBubble:
///    - In CustomChatWidget: Replace _buildMessageItem with ModernMessageBubble
///    - In ChatMessagesWidget: Replace MessageBubble with ModernMessageBubble
///    - In any other chat widgets: Use ModernMessageBubble instead of custom implementations
/// 
/// 2. Update ListView.builder itemBuilder:
///    ```dart
///    itemBuilder: (context, index) {
///      final message = messages[index];
///      final isCurrentUser = message.senderId == currentUserId;
///      
///      return ModernMessageBubble(
///        message: message,
///        isCurrentUser: isCurrentUser,
///        showSenderName: !isCurrentUser, // For group chats
///        showTimestamp: true,
///        onTap: () => handleMessageTap(message),
///        onLongPress: () => handleMessageLongPress(message),
///      );
///    }
///    ```
/// 
/// 3. Benefits of using ModernMessageBubble:
///    - Consistent modern UI across all chat screens
///    - Proper light/dark theme support
///    - Smooth animations and transitions
///    - Support for all message types (text, image, video, audio, files)
///    - Professional error handling
///    - Accessibility features
///    - Touch interactions (tap, long press)
///    - Hero animations for media content
