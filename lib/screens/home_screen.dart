import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';

import '../providers/chat_provider.dart';
import '../services/improved_file_upload_service.dart';
import '../widgets/search_chat_delegate.dart';
import 'chat/create_group_screen.dart';
import 'chat/create_private_chat_screen.dart';
import 'chat/group_chat_list.dart';
import 'chat/private_chat_list.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'chat/chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final webSocketService = Provider.of<ImprovedFileUploadService>(
      context,
      listen: false,
    );
    final currentUserId =
        chatProvider
            .currentUserId; // Assuming currentUserId is stored in ChatProvider

    final screens = <Widget>[
      PrivateChatList(
        chatProvider: chatProvider,
        webSocketService: webSocketService,
        currentUserId: currentUserId,
      ),
      GroupChatList(
        chatProvider: chatProvider,
        webSocketService: webSocketService,
        currentUserId: currentUserId,
      ),
      const ProfileScreen(),
      const SettingsScreen(),
    ];
    final titles = ['Chats', 'Groups', 'Profile', 'Settings'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        actions: [
          if (_currentIndex < 2)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: SearchChatDelegate(
                    chatRooms:
                        _currentIndex == 0
                            ? chatProvider.privateChatRooms
                            : chatProvider.groupChatRooms,
                    chatProvider: chatProvider,
                    currentUserId: currentUserId,
                  ),
                );
              },
            ),
          if (_currentIndex < 2)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh chat rooms',
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                try {
                  await chatProvider.refreshRooms();
                  if (!mounted) return;
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Chat rooms refreshed')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error refreshing: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
        ],
      ),
      body: screens[_currentIndex],
      floatingActionButton: _currentIndex < 2 ? _buildSpeedDial() : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined),
            activeIcon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  SpeedDial _buildSpeedDial() {
    final theme = Theme.of(context);
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      backgroundColor: theme.colorScheme.primaryContainer,
      foregroundColor: theme.colorScheme.onPrimaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      overlayOpacity: 0.4,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.person),
          label: 'New Chat',
          onTap: () => _goToCreatePrivateChat(),
        ),
        SpeedDialChild(
          child: const Icon(Icons.group),
          label: 'New Group',
          onTap: () => _goToCreateGroupChat(),
        ),
      ],
    );
  }

  Future<void> _goToCreatePrivateChat() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreatePrivateChatScreen()),
    );
    if (!mounted) return;
    // Refresh rooms in case user returns without creating a chat
    await chatProvider.refreshRooms();
  }

  Future<void> _goToCreateGroupChat() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final webSocketService = Provider.of<ImprovedFileUploadService>(
      context,
      listen: false,
    );

    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
    );

    if (created == true && mounted) {
      // Refresh the rooms to make sure we have the latest data
      await chatProvider.refreshRooms();
      if (!mounted) return;

      // Get the most recently created group (should be the last one in the list)
      final groups = chatProvider.groupChatRooms;
      if (groups.isNotEmpty) {
        final latestGroup = groups.last;

        // Navigate directly to the chat screen for this group
        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => MultiProvider(
                    providers: [
                      ChangeNotifierProvider.value(value: chatProvider),
                      Provider.value(value: webSocketService),
                    ],
                    child: ChatScreen(chatRoom: latestGroup),
                  ),
            ),
          );
          if (!mounted) return;
        }
      } else {
        // Fallback if for some reason we can't find the group
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group chat created successfully')),
        );
      }
    }
  }
}
