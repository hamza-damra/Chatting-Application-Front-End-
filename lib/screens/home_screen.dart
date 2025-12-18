import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/chat_provider.dart';
import '../services/improved_file_upload_service.dart';
import '../services/screen_state_manager.dart';

import '../widgets/modern_bottom_navigation.dart';
import '../design_system/components/search_bar_widget.dart';
import '../design_system/components/app_speed_dial.dart';
import '../design_system/tokens/app_spacing.dart';
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

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  // Keys to force rebuild of list widgets when needed
  Key _privateChatListKey = UniqueKey();
  Key _groupChatListKey = UniqueKey();

  // State preservation for orientation changes
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Set initial screen state
    _updateScreenState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // Search query changed - can be used for filtering
    setState(() {});
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
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
    // Required for AutomaticKeepAliveClientMixin to preserve state
    super.build(context);

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final webSocketService = Provider.of<ImprovedFileUploadService>(
      context,
      listen: false,
    );
    final currentUserId =
        chatProvider
            .currentUserId; // Assuming currentUserId is stored in ChatProvider

    // Get responsive layout information
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= AppSpacing.breakpointTablet;

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

    // Build the main content with responsive constraints
    Widget buildResponsiveContent(Widget content) {
      if (isDesktop) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: content,
          ),
        );
      }
      return content;
    }

    return Scaffold(
      body: SafeArea(
        child:
            _currentIndex < 2
                ? buildResponsiveContent(
                  Column(
                    children: [
                      // Search bar for chat/group tabs
                      // Header Row
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              [
                                'Chats',
                                'Groups',
                                'Profile',
                                'Settings',
                              ][_currentIndex],
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (_currentIndex < 2)
                              Row(
                                children: [
                                  _buildHeaderActionButton(
                                    context,
                                    Icons.camera_alt,
                                    () {},
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  _buildHeaderActionButton(
                                    context,
                                    Icons.edit,
                                    _currentIndex == 0
                                        ? _goToCreatePrivateChat
                                        : _goToCreateGroupChat,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? AppSpacing.lg : 0,
                        ),
                        child: SearchBarWidget(
                          controller: _searchController,
                          hintText: 'Search',
                          isLoading: false,
                          onChanged: _onSearchChanged,
                          onClear: _clearSearch,
                          semanticLabel: 'Search',
                        ),
                      ),
                      // Chat/Group list
                      Expanded(child: screens[_currentIndex]),
                    ],
                  ),
                )
                : buildResponsiveContent(screens[_currentIndex]),
      ),
      floatingActionButton: _currentIndex < 2 ? _buildSpeedDial() : null,
      bottomNavigationBar: ModernBottomNavigation(
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
        items: const [
          ModernBottomNavItem(
            icon: Icons.chat_bubble_outline_rounded,
            activeIcon: Icons.chat_bubble_rounded,
            label: 'Chats',
          ),
          ModernBottomNavItem(
            icon: Icons.groups_outlined,
            activeIcon: Icons.groups_rounded,
            label: 'Groups',
          ),
          ModernBottomNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
          ),
          ModernBottomNavItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings_rounded,
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedDial() {
    final mediaQuery = MediaQuery.of(context);

    return AppSpeedDial(
      icon: Icons.add_rounded,
      activeIcon: Icons.close_rounded,
      semanticLabel: 'Create new chat or group',
      backdropOpacity: 0.6,
      // Respect safe areas - add extra margin for bottom navigation
      marginBottom: mediaQuery.padding.bottom + 80,
      children: [
        AppSpeedDialChild(
          icon: Icons.person_add_rounded,
          label: 'New Chat',
          onTap: () => _goToCreatePrivateChat(),
        ),
        AppSpeedDialChild(
          icon: Icons.group_add_rounded,
          label: 'New Group',
          onTap: () => _goToCreateGroupChat(),
        ),
      ],
    );
  }

  Widget _buildHeaderActionButton(
    BuildContext context,
    IconData icon,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: isDark ? Colors.white : Colors.black),
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
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
