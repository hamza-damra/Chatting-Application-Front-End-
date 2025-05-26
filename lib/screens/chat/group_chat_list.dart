import 'package:chatting_application/models/chat_room.dart';
import 'package:chatting_application/providers/chat_provider.dart';
import 'package:chatting_application/providers/api_auth_provider.dart';
import 'package:chatting_application/services/improved_file_upload_service.dart';
import 'package:chatting_application/screens/chat/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/shimmer_widgets.dart';
import '../../widgets/modern_chat_list_item.dart';

class GroupChatList extends StatefulWidget {
  final ChatProvider chatProvider;
  final ImprovedFileUploadService webSocketService;
  final int currentUserId;

  const GroupChatList({
    super.key,
    required this.chatProvider,
    required this.webSocketService,
    required this.currentUserId,
  });

  @override
  State<GroupChatList> createState() => _GroupChatListState();
}

class _GroupChatListState extends State<GroupChatList>
    with TickerProviderStateMixin {
  List<ChatRoom> _groupChatRooms = [];
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
    _loadGroupChats();
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
          _groupChatRooms.removeWhere((r) => r.id == roomId);
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
        _groupChatRooms.removeWhere((r) => r.id == roomId);
      });
    }
  }

  Future<void> _loadGroupChats() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Force refresh from server to ensure we have the latest data
      final groupChatRooms = await widget.chatProvider.getGroupChatRooms();

      if (!mounted) return;

      setState(() {
        _groupChatRooms = groupChatRooms;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to load group chats: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return ListView.builder(
        itemCount: 8, // Show 8 shimmer items
        itemBuilder: (context, index) => ShimmerWidgets.listItemShimmer(),
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
              'Error loading group chats',
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
              onPressed: _loadGroupChats,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_groupChatRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group, color: Colors.grey, size: 48),
            const SizedBox(height: 16),
            Text(
              'No group chats yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new group or join an existing one',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGroupChats,
      child: ListView.builder(
        itemCount: _groupChatRooms.length,
        itemBuilder: (context, index) {
          final room = _groupChatRooms[index];
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
          // This will automatically remove groups the user has left
          _loadGroupChats();
        });
      },
      onLongPress:
          () => _showChatRoomContextMenu(context, room, widget.chatProvider),
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

  /// Show context menu for chat room actions
  void _showChatRoomContextMenu(
    BuildContext context,
    ChatRoom room,
    ChatProvider chatProvider,
  ) {
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
                // Header with group info
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
                          room.name?.substring(0, 1).toUpperCase() ?? 'G',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              room.name ?? 'Group Chat',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${room.participantIds.length} members',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // Leave Group option
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.red),
                  title: const Text('Leave Group'),
                  subtitle: const Text(
                    'You will no longer receive messages and the group will be removed from your list',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showLeaveGroupConfirmation(context, room, chatProvider);
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

  /// Show confirmation dialog for leaving a group
  void _showLeaveGroupConfirmation(
    BuildContext context,
    ChatRoom room,
    ChatProvider chatProvider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Leave Group'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Are you sure you want to leave "${room.name}"?'),
                const SizedBox(height: 8),
                const Text(
                  'You will no longer receive messages from this group and cannot rejoin unless added by another member.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
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
                  _performLeaveGroup(room, chatProvider);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Leave Group'),
              ),
            ],
          ),
    );
  }

  /// Perform leave group action
  Future<void> _performLeaveGroup(
    ChatRoom room,
    ChatProvider chatProvider,
  ) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await chatProvider.leaveGroup(room.id);

      // Hide loading indicator
      if (mounted) Navigator.of(context).pop();

      if (success) {
        // Animate removal and then remove from list
        await _animateRoomRemoval(room.id);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Left "${room.name}" successfully'),
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
              content: Text(chatProvider.error ?? 'Failed to leave group'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () => _performLeaveGroup(room, chatProvider),
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
