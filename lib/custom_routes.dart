import 'package:flutter/material.dart';
import 'screens/media_preview_screen.dart';

class CustomRoutes {
  // Named routes for navigation
  static const String videoPreview = '/video-preview';

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
