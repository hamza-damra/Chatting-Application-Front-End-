import 'package:flutter/material.dart';
import '../../presentation/screens/chat/chat_list_screen.dart';
import '../../presentation/screens/chat/chat_room_screen.dart';
import '../../presentation/screens/users/user_list_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/profile_screen.dart';
import '../../screens/chat/create_group_screen.dart';
// Import other screens as needed

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Dynamic route for individual chat rooms
    // The route pattern is '/chat/:id'
    if (settings.name != null && settings.name!.startsWith('/chat/')) {
      final chatRoomId = settings.name!.substring(6); // Remove '/chat/'
      return MaterialPageRoute(
        builder: (_) => ChatRoomScreen(chatRoomId: chatRoomId),
      );
    }

    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const ChatListScreen());

      case '/chat':
        return MaterialPageRoute(builder: (_) => const ChatListScreen());

      case '/users':
        return MaterialPageRoute(builder: (_) => const UserListScreen());

      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      case '/create-group':
        return MaterialPageRoute(builder: (_) => const CreateGroupScreen());

      // Add more routes as needed

      default:
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                body: Center(
                  child: Text('No route defined for ${settings.name}'),
                ),
              ),
        );
    }
  }
}
