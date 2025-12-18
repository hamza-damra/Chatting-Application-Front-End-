import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/chat_provider.dart';
import '../../providers/api_auth_provider.dart';
import '../../widgets/user_avatar.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../design_system/components/responsive_container.dart';
import 'chat_screen.dart';

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
  void initState() {
    super.initState();
    // Listen to group name changes to update the create button
    _groupNameController.addListener(() {
      setState(() {
        // This will trigger a rebuild and update the button state
      });
    });
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupImageController.dispose();
    super.dispose();
  }

  /// Check if the group can be created
  bool _canCreateGroup() {
    return _selectedUsers.length >= 2 &&
        _groupNameController.text.trim().isNotEmpty &&
        !_isCreating;
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
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: ResponsiveMaxWidths.createGroup,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // Custom header row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Create Group',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _isCreating
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : TextButton(
                          onPressed:
                              _canCreateGroup()
                                  ? () => _createGroup(context)
                                  : null,
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: Text(
                            'Create',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color:
                                  _canCreateGroup()
                                      ? theme.colorScheme.primary
                                      : Colors.grey,
                            ),
                          ),
                        ),
                  ],
                ),
              ),
              // Group info form
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveLayout.getHorizontalPadding(context),
                  vertical: AppSpacing.lg,
                ),
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
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveLayout.getHorizontalPadding(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Select Participants',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text('${_selectedUsers.length} selected'),
                          backgroundColor:
                              _selectedUsers.length >= 2
                                  ? theme.colorScheme.primary.withAlpha(26)
                                  : Colors.grey.withAlpha(26),
                          labelStyle: TextStyle(
                            color:
                                _selectedUsers.length >= 2
                                    ? theme.colorScheme.primary
                                    : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    if (_selectedUsers.length < 2)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Select at least 2 participants to create a group',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
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
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveLayout.getHorizontalPadding(
                              context,
                            ),
                          ),
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
        ),
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

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedUsers.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select at least 2 participants to create a group',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
      final userIds = _selectedUsers.map((user) => user.id.toString()).toList();

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
        // Try to find the newly created room and navigate to it
        try {
          // Wait a moment to ensure the room list is updated
          await Future.delayed(const Duration(milliseconds: 500));

          // Find the room in the updated list
          final newRoom = chatProvider.rooms.firstWhere(
            (room) => room.id == roomId,
            orElse: () => throw Exception('Room not found in list'),
          );

          // Convert types.Room to ChatRoom using the public method
          final chatRoom = chatProvider.convertRoomToChatRoom(newRoom);

          // Navigate to the chat screen with the newly created room
          safelyUseContext((ctx) {
            Navigator.of(
              ctx,
            ).pop(true); // Close create group screen with success indicator
            Navigator.of(ctx).push(
              MaterialPageRoute(
                builder: (context) => ChatScreen(chatRoom: chatRoom),
              ),
            );
          });
        } catch (e) {
          // If navigation fails, just return with success
          safelyUseContext((ctx) {
            Navigator.of(ctx).pop(true); // Return success indicator
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(
                content: Text('Group created successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          });
        }
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
