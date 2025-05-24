import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/chat_provider.dart';
import '../../providers/api_auth_provider.dart';
import '../../widgets/user_avatar.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class AddParticipantsScreen extends StatefulWidget {
  final types.Room room;

  const AddParticipantsScreen({super.key, required this.room});

  @override
  State<AddParticipantsScreen> createState() => _AddParticipantsScreenState();
}

class _AddParticipantsScreenState extends State<AddParticipantsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<UserModel> _selectedUsers = {};
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addParticipants(BuildContext context) async {
    // Create a method-level function to safely use context after async operations
    void safelyUseContext(Function(BuildContext ctx) action) {
      if (mounted) {
        action(context);
      }
    }

    if (_selectedUsers.isEmpty) {
      return;
    }

    setState(() {
      _isAdding = true;
    });

    try {
      // Get provider before async operation
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      // Get room ID
      final roomId = int.parse(widget.room.id);

      // Add each selected user
      bool allSucceeded = true;
      String errorMessage = '';

      for (final user in _selectedUsers) {
        final success = await chatProvider.addParticipant(
          roomId: roomId,
          userId: user.id,
        );

        if (!success) {
          allSucceeded = false;
          errorMessage = chatProvider.error ?? 'Failed to add ${user.fullName}';
          break;
        }
      }

      // Show result
      safelyUseContext((ctx) {
        if (allSucceeded) {
          // Return to previous screen with success
          Navigator.pop(ctx, true);

          // Show success message
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text('Participants added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Show error message
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      });
    } catch (e) {
      safelyUseContext((ctx) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final authProvider = Provider.of<ApiAuthProvider>(context);
    final theme = Theme.of(context);

    // Get current room participants
    final currentParticipantIds =
        widget.room.users.map((user) => user.id).toSet();

    // Filter out the current user and existing participants from the list
    final availableUsers =
        chatProvider.users
            .where(
              (user) =>
                  user.id != authProvider.user?.id &&
                  !currentParticipantIds.contains(user.id.toString()),
            )
            .toList();

    // Apply search filter if there's a query
    final filteredUsers =
        _searchQuery.isEmpty
            ? availableUsers
            : availableUsers.where((user) {
              final fullName = user.fullName.toLowerCase();
              final username = user.username.toLowerCase();
              final query = _searchQuery.toLowerCase();
              return fullName.contains(query) || username.contains(query);
            }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Participants'),
        actions: [
          TextButton(
            onPressed:
                _selectedUsers.isEmpty || _isAdding
                    ? null
                    : () => _addParticipants(context),
            child:
                _isAdding
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Add'),
          ),
        ],
      ),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
            ),
          ),

          // Selected users count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text('Select Users', style: theme.textTheme.titleMedium),
                const SizedBox(width: 8),
                Chip(
                  label: Text('${_selectedUsers.length} selected'),
                  backgroundColor:
                      _selectedUsers.isNotEmpty
                          ? theme.colorScheme.primary.withAlpha(26)
                          : Colors.grey.withAlpha(26),
                  labelStyle: TextStyle(
                    color:
                        _selectedUsers.isNotEmpty
                            ? theme.colorScheme.primary
                            : Colors.grey,
                  ),
                ),
              ],
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
                            ? 'No users available to add'
                            : 'No users found',
                        style: theme.textTheme.bodyLarge,
                      ),
                    )
                    : ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        final isSelected = _selectedUsers.contains(user);

                        return ListTile(
                          leading: UserAvatar(
                            imageUrl: user.profilePicture,
                            name: user.fullName,
                            size: 40,
                          ),
                          title: Text(user.fullName),
                          subtitle: Text(user.username),
                          trailing:
                              isSelected
                                  ? Icon(
                                    Icons.check_circle,
                                    color: theme.colorScheme.primary,
                                  )
                                  : const Icon(
                                    Icons.circle_outlined,
                                    color: Colors.grey,
                                  ),
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedUsers.remove(user);
                              } else {
                                _selectedUsers.add(user);
                              }
                            });
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
