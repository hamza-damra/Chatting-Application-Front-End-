import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';

import '../providers/chat_provider.dart';
import '../services/improved_file_upload_service.dart';
import '../services/screen_state_manager.dart';
import '../widgets/search_chat_delegate.dart';
import 'chat/create_group_screen.dart';
import 'chat/create_private_chat_screen.dart';
import 'chat/group_chat_list.dart';
import 'chat/private_chat_list.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Keys to force rebuild of list widgets when needed
  Key _privateChatListKey = UniqueKey();
  Key _groupChatListKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    // Set initial screen state
    _updateScreenState();
  }

  void _updateScreenState() {
    final screenStateManager = ScreenStateManager.instance;
    switch (_currentIndex) {
      case 0:
        screenStateManager.updateCurrentScreen(
          ScreenStateManager.privateChatListScreen,
        );
        break;
      case 1:
        screenStateManager.updateCurrentScreen(
          ScreenStateManager.groupChatListScreen,
        );
        break;
      case 2:
        screenStateManager.updateCurrentScreen(
          ScreenStateManager.profileScreen,
        );
        break;
      case 3:
        screenStateManager.updateCurrentScreen(
          ScreenStateManager.settingsScreen,
        );
        break;
    }
  }

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
        key: _privateChatListKey,
        chatProvider: chatProvider,
        webSocketService: webSocketService,
        currentUserId: currentUserId,
      ),
      GroupChatList(
        key: _groupChatListKey,
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
        onTap: (i) {
          setState(() {
            _currentIndex = i;
            // Refresh the list when switching to chat tabs
            if (i == 0) {
              _privateChatListKey = UniqueKey();
            } else if (i == 1) {
              _groupChatListKey = UniqueKey();
            }
          });
          _updateScreenState();
        },
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
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreatePrivateChatScreen()),
    );
    if (!mounted) return;

    // Refresh rooms if a chat was created or user returns
    await chatProvider.refreshRooms();

    // If we're on the private chat tab, trigger a refresh of the list
    if (_currentIndex == 0 && created == true) {
      // Force rebuild of private chat list by changing its key
      setState(() {
        _privateChatListKey = UniqueKey();
      });
    }
  }

  Future<void> _goToCreateGroupChat() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
    );

    if (!mounted) return;

    // Refresh rooms if a group was created or user returns
    await chatProvider.refreshRooms();

    // If we're on the group chat tab, trigger a refresh of the list
    if (_currentIndex == 1 && created == true) {
      // Force rebuild of group chat list by changing its key
      setState(() {
        _groupChatListKey = UniqueKey();
      });
    }
  }
}
