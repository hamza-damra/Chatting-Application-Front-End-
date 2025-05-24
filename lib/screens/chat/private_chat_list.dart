import 'package:chatting_application/models/chat_room.dart';
import 'package:chatting_application/providers/chat_provider.dart';
import 'package:chatting_application/providers/api_auth_provider.dart';
import 'package:chatting_application/services/improved_file_upload_service.dart';
import 'package:chatting_application/screens/chat/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/shimmer_widgets.dart';

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

class _PrivateChatListState extends State<PrivateChatList> {
  List<ChatRoom> _privateChatRooms = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadPrivateChats();
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
          return _buildChatRoomItem(room);
        },
      ),
    );
  }

  Widget _buildChatRoomItem(ChatRoom room) {
    final unreadCount = widget.chatProvider.getUnreadCount(room.id.toString());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            room.name?.substring(0, 1).toUpperCase() ?? '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          room.name ?? 'Private Chat',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          room.description ?? 'No description',
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
                      ChangeNotifierProvider.value(value: widget.chatProvider),
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
      ),
    );
  }
}
