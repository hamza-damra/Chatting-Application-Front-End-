import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/chat_provider.dart';
import '../../providers/api_auth_provider.dart';
import '../../widgets/user_avatar.dart';
import '../../utils/logger.dart';
import 'chat_screen.dart';

class CreatePrivateChatScreen extends StatefulWidget {
  const CreatePrivateChatScreen({super.key});

  @override
  State<CreatePrivateChatScreen> createState() =>
      _CreatePrivateChatScreenState();
}

class _CreatePrivateChatScreenState extends State<CreatePrivateChatScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isCreating = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final authProvider = Provider.of<ApiAuthProvider>(context);
    final theme = Theme.of(context);

    // Filter out the current user from the list
    final allUsers =
        chatProvider.users
            .where((user) => user.id != authProvider.user?.id)
            .toList();

    // Apply search filter if there's a query
    final filteredUsers =
        _searchQuery.isEmpty
            ? allUsers
            : allUsers.where((user) {
              final fullName = user.fullName.toLowerCase();
              final username = user.username.toLowerCase();
              final query = _searchQuery.toLowerCase();
              return fullName.contains(query) || username.contains(query);
            }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('New Chat')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // User list
          Expanded(
            child:
                chatProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredUsers.isEmpty
                    ? Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'No users available'
                            : 'No users found',
                        style: theme.textTheme.bodyLarge,
                      ),
                    )
                    : ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];

                        return ListTile(
                          leading: UserAvatar(
                            imageUrl: user.profilePicture,
                            name: user.fullName,
                            size: 40,
                          ),
                          title: Text(user.fullName),
                          subtitle: Text(user.username),
                          onTap:
                              _isCreating
                                  ? null
                                  : () => _createPrivateChat(context, user),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Future<void> _createPrivateChat(BuildContext context, UserModel user) async {
    // Create a method-level function to safely use context after async operations
    void safelyUseContext(Function(BuildContext ctx) action) {
      if (mounted) {
        action(context);
      }
    }

    setState(() {
      _isCreating = true;
    });

    try {
      // Get provider before async operation
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      // Store error message before async operation
      final errorMessageProvider =
          chatProvider.error ?? 'Failed to create chat';

      // Create the private chat
      final roomId = await chatProvider.createRoom(
        userIds: [user.id.toString()],
        name: user.fullName, // Use the user's name as the room name
        imageUrl: user.profilePicture, // Use the user's profile picture
        isGroup: false, // This is a private chat
      );

      // Check if widget is still mounted before using context
      if (!mounted) return;

      if (roomId != null) {
        // Try to find the newly created room
        try {
          // Wait a moment to ensure the room list is updated
          await Future.delayed(const Duration(milliseconds: 300));

          // Find the room in the updated list
          final newRoom = chatProvider.rooms.firstWhere(
            (room) => room.id == roomId,
            orElse: () => throw Exception('Room not found in list'),
          );

          // Convert types.Room to ChatRoom using the public method
          final chatRoom = chatProvider.convertRoomToChatRoom(newRoom);

          // Navigate to the chat screen with the newly created room
          // Use Navigator.pushReplacement instead of pop + push
          safelyUseContext((ctx) {
            Navigator.pushReplacement(
              ctx,
              MaterialPageRoute(
                builder: (context) => ChatScreen(chatRoom: chatRoom),
              ),
            );
          });
        } catch (e) {
          AppLogger.e(
            'CreatePrivateChatScreen',
            'Error finding or navigating to new room: $e',
          );
          // Room was created but not found in the list or navigation failed
          // Just return to previous screen
          safelyUseContext((ctx) => Navigator.of(ctx).pop(true));
        }
      } else {
        // Show error message
        safelyUseContext(
          (ctx) => ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(errorMessageProvider),
              backgroundColor: Colors.red,
            ),
          ),
        );
      }
    } catch (e) {
      // Use the safe context method for error handling
      final errorMessage = 'Error: $e';
      safelyUseContext(
        (ctx) => ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
}
