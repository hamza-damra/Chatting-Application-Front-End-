import 'package:chatting_application/models/chat_room.dart';
import 'package:chatting_application/providers/chat_provider.dart';
import 'package:chatting_application/providers/api_auth_provider.dart';
import 'package:chatting_application/services/improved_file_upload_service.dart';
import 'package:chatting_application/screens/chat/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/shimmer_widgets.dart';

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

class _GroupChatListState extends State<GroupChatList> {
  List<ChatRoom> _groupChatRooms = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadGroupChats();
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
          return _buildChatRoomItem(room);
        },
      ),
    );
  }

  Widget _buildChatRoomItem(ChatRoom room) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final unreadCount = chatProvider.getUnreadCount(room.id.toString());
        final apiAuthProvider = Provider.of<ApiAuthProvider>(
          context,
          listen: false,
        );

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                room.name?.substring(0, 1).toUpperCase() ?? 'G',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              room.name ?? 'Group Chat',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${room.participantIds.length} members${room.description != null ? ' • ${room.description}' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing:
                unreadCount > 0
                    ? Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                    : const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Mark room as read via WebSocket for real-time updates (non-blocking)
              chatProvider.markRoomAsRead(room.id.toString());

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
                _loadGroupChats();
              });
            },
          ),
        );
      },
    );
  }
}
