import 'package:flutter/material.dart';
import '../utils/logger.dart';

/// Global navigation service that can be used from anywhere in the app
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  /// Get the current navigator state
  static NavigatorState? get navigator => navigatorKey.currentState;
  
  /// Get the current context
  static BuildContext? get context => navigatorKey.currentContext;
  
  /// Navigate to a named route
  static Future<T?> pushNamed<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) async {
    try {
      if (navigator == null) {
        AppLogger.w('NavigationService', 'Navigator not available');
        return null;
      }
      
      AppLogger.i('NavigationService', 'Navigating to: $routeName');
      return await navigator!.pushNamed<T>(routeName, arguments: arguments);
    } catch (e) {
      AppLogger.e('NavigationService', 'Error navigating to $routeName: $e');
      return null;
    }
  }
  
  /// Navigate to a named route and remove all previous routes
  static Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
    String routeName,
    RoutePredicate predicate, {
    Object? arguments,
  }) async {
    try {
      if (navigator == null) {
        AppLogger.w('NavigationService', 'Navigator not available');
        return null;
      }
      
      AppLogger.i('NavigationService', 'Navigating to: $routeName (clearing stack)');
      return await navigator!.pushNamedAndRemoveUntil<T>(
        routeName,
        predicate,
        arguments: arguments,
      );
    } catch (e) {
      AppLogger.e('NavigationService', 'Error navigating to $routeName: $e');
      return null;
    }
  }
  
  /// Navigate to a chat room by ID
  static Future<void> navigateToChatRoom(int roomId) async {
    try {
      if (navigator == null) {
        AppLogger.w('NavigationService', 'Navigator not available for chat navigation');
        return;
      }
      
      AppLogger.i('NavigationService', 'Navigating to chat room: $roomId');
      
      // Use the AppRouter pattern for chat rooms: '/chat/:id'
      await navigator!.pushNamed('/chat/$roomId');
    } catch (e) {
      AppLogger.e('NavigationService', 'Error navigating to chat room $roomId: $e');
    }
  }
  
  /// Navigate to the home screen (chat list)
  static Future<void> navigateToHome() async {
    try {
      if (navigator == null) {
        AppLogger.w('NavigationService', 'Navigator not available for home navigation');
        return;
      }
      
      AppLogger.i('NavigationService', 'Navigating to home screen');
      await navigator!.pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      AppLogger.e('NavigationService', 'Error navigating to home: $e');
    }
  }
  
  /// Pop the current route
  static void pop<T extends Object?>([T? result]) {
    try {
      if (navigator == null) {
        AppLogger.w('NavigationService', 'Navigator not available for pop');
        return;
      }
      
      if (navigator!.canPop()) {
        navigator!.pop<T>(result);
      } else {
        AppLogger.w('NavigationService', 'Cannot pop - no routes to pop');
      }
    } catch (e) {
      AppLogger.e('NavigationService', 'Error popping route: $e');
    }
  }
  
  /// Check if we can pop the current route
  static bool canPop() {
    return navigator?.canPop() ?? false;
  }
  
  /// Show a snack bar
  static void showSnackBar(String message, {Color? backgroundColor}) {
    try {
      final scaffoldMessenger = ScaffoldMessenger.of(context!);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
        ),
      );
    } catch (e) {
      AppLogger.e('NavigationService', 'Error showing snack bar: $e');
    }
  }
}
