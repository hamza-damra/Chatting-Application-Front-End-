import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../presentation/blocs/chat/chat_bloc.dart';
import '../../../presentation/blocs/chat/chat_event.dart';
import '../../../presentation/blocs/chat/chat_state.dart';
import '../../../presentation/widgets/chat/chat_list_item.dart';
import '../../../core/constants/app_theme.dart';
import '../../../widgets/shimmer_widgets.dart';
import '../../../providers/chat_provider.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    // Load chat rooms
    context.read<ChatBloc>().add(LoadChatRooms());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showOptions(context);
            },
          ),
        ],
      ),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state is ChatRoomsLoaded) {
            // Sync unread counts with ChatProvider when rooms are loaded
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final chatProvider = Provider.of<ChatProvider>(
                context,
                listen: false,
              );
              chatProvider.syncUnreadCountsFromChatRooms(state.chatRooms);
            });

            if (state.chatRooms.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.chatRooms.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final chatRoom = state.chatRooms[index];
                return ChatListItem(
                  chatRoom: chatRoom,
                  currentUserId: state.currentUserId,
                  onTap: () {
                    Navigator.pushNamed(context, '/chat/${chatRoom.id}');
                  },
                );
              },
            );
          } else if (state is ChatFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 60,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load chats',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.error,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ChatBloc>().add(LoadChatRooms());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: 6, // Show 6 shimmer items
            itemBuilder: (context, index) => ShimmerWidgets.listItemShimmer(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showNewChatOptions(context);
        },
        child: const Icon(Icons.chat),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No chats yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation by tapping the button below',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/settings');
                },
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/profile');
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement help functionality
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNewChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('New Private Chat'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/users');
                },
              ),
              ListTile(
                leading: const Icon(Icons.group_add),
                title: const Text('New Group Chat'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/create-group');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
