import 'package:vector/models/chat_room.dart';
import 'package:vector/providers/chat_provider.dart';
import 'package:vector/providers/api_auth_provider.dart';
import 'package:vector/services/improved_file_upload_service.dart';
import 'package:vector/screens/chat/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/shimmer_widgets.dart';
import '../../widgets/modern_chat_list_item.dart';

class PrivateChatList extends StatefulWidget {
  final ChatProvider chatProvider;
  final ImprovedFileUploadService webSocketService;
  final int currentUserId;

  const PrivateChatList({
    super.key,
    required this.chatProvider,
    required this.webSocketService,
    required this.currentUserId,
  });

  @override
  State<PrivateChatList> createState() => _PrivateChatListState();
}

class _PrivateChatListState extends State<PrivateChatList>
    with TickerProviderStateMixin {
  List<ChatRoom> _privateChatRooms = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // Animation controllers for smooth removal
  final Map<int, AnimationController> _animationControllers = {};
  final Map<int, Animation<double>> _slideAnimations = {};
  final Map<int, Animation<double>> _fadeAnimations = {};

  @override
  void initState() {
    super.initState();
    _loadPrivateChats();
  }

  @override
  void dispose() {
    // Dispose all animation controllers
    for (final controller in _animationControllers.values) {
      controller.dispose();
    }
    _animationControllers.clear();
    _slideAnimations.clear();
    _fadeAnimations.clear();
    super.dispose();
  }

  /// Create animation controller for a room
  void _createAnimationController(int roomId) {
    if (_animationControllers.containsKey(roomId)) return;

    final controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    final slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

    final fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

    _animationControllers[roomId] = controller;
    _slideAnimations[roomId] = slideAnimation;
    _fadeAnimations[roomId] = fadeAnimation;

    // Start with the item visible
    controller.value = 0.0;
  }

  /// Animate room removal
  Future<void> _animateRoomRemoval(int roomId) async {
    final controller = _animationControllers[roomId];
    if (controller != null) {
      await controller.forward();

      // Remove from list after animation completes
      if (mounted) {
        setState(() {
          _privateChatRooms.removeWhere((r) => r.id == roomId);
        });

        // Clean up animation controller
        controller.dispose();
        _animationControllers.remove(roomId);
        _slideAnimations.remove(roomId);
        _fadeAnimations.remove(roomId);
      }
    } else {
      // Fallback: remove immediately if no animation controller
      setState(() {
        _privateChatRooms.removeWhere((r) => r.id == roomId);
      });
    }
  }

  Future<void> _loadPrivateChats() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Force refresh from server to ensure we have the latest data
      final privateChatRooms = await widget.chatProvider.getPrivateChatRooms();

      if (mounted) {
        setState(() {
          _privateChatRooms = privateChatRooms;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to load private chats: $e';
        });
      }
    }
  }

  // Public method to refresh the list from parent widget
  void refreshList() {
    _loadPrivateChats();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return ListView.builder(
        itemCount: 8, // Show 8 shimmer items
        itemBuilder:
            (context, index) =>
                ShimmerWidgets.listItemShimmer(context: context),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading private chats',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPrivateChats,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_privateChatRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 48),
            const SizedBox(height: 16),
            Text(
              'No private chats yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation with someone',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPrivateChats,
      child: ListView.builder(
        itemCount: _privateChatRooms.length,
        itemBuilder: (context, index) {
          final room = _privateChatRooms[index];
          // Create animation controller for this room if it doesn't exist
          _createAnimationController(room.id);
          return _buildChatRoomItem(room);
        },
      ),
    );
  }

  Widget _buildChatRoomItem(ChatRoom room) {
    // Get animations for this room
    final slideAnimation = _slideAnimations[room.id];
    final fadeAnimation = _fadeAnimations[room.id];

    // Create the modern chat list item
    final modernChatItem = ModernChatListItem(
      chatRoom: room,
      currentUserId: widget.currentUserId,
      onTap: () {
        // Mark room as read via WebSocket for real-time updates (non-blocking)
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        chatProvider.markRoomAsRead(room.id.toString());

        final apiAuthProvider = Provider.of<ApiAuthProvider>(
          context,
          listen: false,
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => MultiProvider(
                  providers: [
                    ChangeNotifierProvider.value(value: chatProvider),
                    Provider.value(value: widget.webSocketService),
                    ChangeNotifierProvider.value(value: apiAuthProvider),
                  ],
                  child: ChatScreen(chatRoom: room),
                ),
          ),
        ).then((_) {
          // Refresh the list when returning from chat screen
          _loadPrivateChats();
        });
      },
      onLongPress: () => _showPrivateChatContextMenu(context, room),
    );

    // Return animated version if animations are available
    if (slideAnimation != null && fadeAnimation != null) {
      return AnimatedBuilder(
        animation: slideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(slideAnimation.value * 300, 0), // Slide to the right
            child: Opacity(opacity: fadeAnimation.value, child: modernChatItem),
          );
        },
      );
    }

    // Fallback to non-animated version
    return modernChatItem;
  }

  /// Show context menu for private chat actions
  void _showPrivateChatContextMenu(BuildContext context, ChatRoom room) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with chat info
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          room
                              .getDisplayName(
                                widget.currentUserId,
                                widget.chatProvider.getUserNameById,
                              )
                              .substring(0, 1)
                              .toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              room.getDisplayName(
                                widget.currentUserId,
                                widget.chatProvider.getUserNameById,
                              ),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              'Private conversation',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // Mark as Read option
                ListTile(
                  leading: const Icon(
                    Icons.mark_email_read,
                    color: Colors.blue,
                  ),
                  title: const Text('Mark as Read'),
                  subtitle: const Text('Clear unread message count'),
                  onTap: () {
                    Navigator.pop(context);
                    _markChatAsRead(room);
                  },
                ),

                // Delete User option
                ListTile(
                  leading: const Icon(Icons.person_remove, color: Colors.red),
                  title: const Text('Delete User'),
                  subtitle: const Text(
                    'Permanently delete this user from the system',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteUserConfirmation(context, room);
                  },
                ),

                // Cancel option
                ListTile(
                  leading: const Icon(
                    Icons.cancel_outlined,
                    color: Colors.grey,
                  ),
                  title: const Text('Cancel'),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
    );
  }

  /// Mark chat as read
  void _markChatAsRead(ChatRoom room) {
    final chatProvider = widget.chatProvider;
    chatProvider.markRoomAsRead(room.id.toString());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Marked "${room.getDisplayName(widget.currentUserId, widget.chatProvider.getUserNameById)}" as read',
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// Show confirmation dialog for deleting user
  void _showDeleteUserConfirmation(BuildContext context, ChatRoom room) {
    // Get the other user in the private chat (excluding current user)
    final currentUserId = widget.chatProvider.currentUserId;
    final otherUserId = room.participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => -1,
    );

    if (otherUserId == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Could not identify user to delete'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete User'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to permanently delete "${room.getDisplayName(widget.currentUserId, widget.chatProvider.getUserNameById)}"?',
                ),
                const SizedBox(height: 8),
                const Text(
                  'This action cannot be undone. The user will be removed from the system and all their data will be deleted.',
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _performDeleteUser(room, otherUserId);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete User'),
              ),
            ],
          ),
    );
  }

  /// Perform delete user action with animation
  Future<void> _performDeleteUser(ChatRoom room, int userId) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await widget.chatProvider.deleteUser(userId);

      // Hide loading indicator
      if (mounted) Navigator.of(context).pop();

      if (success) {
        // Animate removal and then remove from list
        await _animateRoomRemoval(room.id);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'User "${room.getDisplayName(widget.currentUserId, widget.chatProvider.getUserNameById)}" deleted successfully',
              ),
              backgroundColor: Colors.green,
              action: SnackBarAction(label: 'OK', onPressed: () {}),
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.chatProvider.error ?? 'Failed to delete user',
              ),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () => _performDeleteUser(room, userId),
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Hide loading indicator
      if (mounted) Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
