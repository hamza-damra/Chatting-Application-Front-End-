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
    setState(() {
      _isCreating = true;
    });

    // Store navigator before async operations
    final navigator = Navigator.of(context);

    try {
      // Get provider before async operation
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      AppLogger.i(
        'CreatePrivateChatScreen',
        'Creating private chat with user: ${user.fullName}',
      );

      final roomId = await chatProvider.createRoom(
        userIds: [user.id.toString()],
        name: user.fullName, // Use the user's name as the room name
        imageUrl: user.profilePicture, // Use the user's profile picture
        isGroup: false, // This is a private chat
      );

      // Check if widget is still mounted before using context
      if (!mounted) return;

      if (roomId != null) {
        AppLogger.i(
          'CreatePrivateChatScreen',
          'Room created successfully with ID: $roomId',
        );

        // Wait a moment for the room to be properly set up
        await Future.delayed(const Duration(milliseconds: 300));

        // Get the selected room (createRoom should have selected it)
        final selectedRoom = chatProvider.selectedRoom;

        if (selectedRoom != null && selectedRoom.id == roomId && mounted) {
          AppLogger.i(
            'CreatePrivateChatScreen',
            'Navigating to selected room: ${selectedRoom.name}',
          );

          try {
            // Convert types.Room to ChatRoom using the public method
            final chatRoom = chatProvider.convertRoomToChatRoom(selectedRoom);

            // Navigate to the chat screen with the newly created room
            navigator.pop(); // Close create chat screen
            navigator.push(
              MaterialPageRoute(
                builder: (context) => ChatScreen(chatRoom: chatRoom),
              ),
            );
            return; // Exit early on success
          } catch (e) {
            AppLogger.e(
              'CreatePrivateChatScreen',
              'Error converting selected room: $e',
            );
          }
        }

        // If we reach here, something went wrong but the room was created
        AppLogger.w(
          'CreatePrivateChatScreen',
          'Room created but navigation failed. Selected room: ${selectedRoom?.id}, Expected: $roomId',
        );

        if (mounted) {
          navigator.pop(true); // Just go back with success
        }
      } else {
        AppLogger.e('CreatePrivateChatScreen', 'Failed to create room');
        if (mounted) {
          navigator.pop(); // Just go back
        }
      }
    } catch (e) {
      AppLogger.e('CreatePrivateChatScreen', 'Error creating private chat: $e');
      if (mounted) {
        navigator.pop(); // Just go back
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
}
