import 'package:flutter/material.dart';
import 'screens/media_preview_screen.dart';
import 'screens/chat/create_group_screen.dart';
import 'screens/chat/create_private_chat_screen.dart';

class CustomRoutes {
  // Named routes for navigation
  static const String videoPreview = '/video-preview';
  static const String createGroup = '/create-group';
  static const String createPrivateChat = '/create-private-chat';

  // Route generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case videoPreview:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder:
              (_) => MediaPreviewScreen(
                attachmentUrl: args['url'],
                contentType: args['contentType'],
                fileName: args['fileName'],
              ),
        );

      case createGroup:
        return MaterialPageRoute(builder: (_) => const CreateGroupScreen());

      case createPrivateChat:
        return MaterialPageRoute(
          builder: (_) => const CreatePrivateChatScreen(),
        );

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
