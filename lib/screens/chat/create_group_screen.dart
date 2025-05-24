import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/chat_provider.dart';
import '../../providers/api_auth_provider.dart';
import '../../widgets/user_avatar.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final _groupImageController = TextEditingController();
  final Set<UserModel> _selectedUsers = {};
  bool _isCreating = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupImageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final authProvider = Provider.of<ApiAuthProvider>(context);
    final theme = Theme.of(context);

    // Filter out the current user from the list
    final availableUsers =
        chatProvider.users
            .where((user) => user.id != authProvider.user?.id)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
        actions: [
          TextButton(
            onPressed:
                _selectedUsers.isEmpty || _isCreating
                    ? null
                    : () => _createGroup(context),
            child:
                _isCreating
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Create'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Group info form
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _groupNameController,
                    decoration: const InputDecoration(
                      labelText: 'Group Name',
                      hintText: 'Enter a name for your group',
                      prefixIcon: Icon(Icons.group),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a group name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _groupImageController,
                    decoration: const InputDecoration(
                      labelText: 'Group Image URL (Optional)',
                      hintText: 'Enter an image URL for your group',
                      prefixIcon: Icon(Icons.image),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Selected users count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text('Select Participants', style: theme.textTheme.titleMedium),
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
                    : availableUsers.isEmpty
                    ? Center(
                      child: Text(
                        'No users available',
                        style: theme.textTheme.bodyLarge,
                      ),
                    )
                    : ListView.builder(
                      itemCount: availableUsers.length,
                      itemBuilder: (context, index) {
                        final user = availableUsers[index];
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

  Future<void> _createGroup(BuildContext context) async {
    // Create a method-level function to safely use context after async operations
    void safelyUseContext(Function(BuildContext ctx) action) {
      if (mounted) {
        action(context);
      }
    }

    if (_formKey.currentState!.validate() && _selectedUsers.isNotEmpty) {
      setState(() {
        _isCreating = true;
      });

      try {
        // Get provider before async operation
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);

        // Store error message before async operation
        final errorMessageProvider =
            chatProvider.error ?? 'Failed to create group';

        // Get user IDs of selected users
        final userIds =
            _selectedUsers.map((user) => user.id.toString()).toList();

        // Get form values before async operation
        final groupName = _groupNameController.text.trim();
        final groupImageUrl =
            _groupImageController.text.trim().isNotEmpty
                ? _groupImageController.text.trim()
                : null;

        // Create the group
        final roomId = await chatProvider.createRoom(
          userIds: userIds,
          name: groupName,
          imageUrl: groupImageUrl,
          isGroup: true,
        );

        // Use the safe context method
        if (roomId != null) {
          safelyUseContext((ctx) => Navigator.of(ctx).pop(true));
        } else {
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
}
