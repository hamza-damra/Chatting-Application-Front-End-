import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatting_application/services/navigation_service.dart';

void main() {
  group('NavigationService', () {
    testWidgets('should have a global navigator key', (WidgetTester tester) async {
      expect(NavigationService.navigatorKey, isA<GlobalKey<NavigatorState>>());
    });

    testWidgets('should return null navigator when not initialized', (WidgetTester tester) async {
      expect(NavigationService.navigator, isNull);
      expect(NavigationService.context, isNull);
    });

    testWidgets('should provide navigator when MaterialApp is built with the key', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: NavigationService.navigatorKey,
          home: const Scaffold(
            body: Text('Test'),
          ),
        ),
      );

      expect(NavigationService.navigator, isNotNull);
      expect(NavigationService.context, isNotNull);
    });

    testWidgets('should handle navigation to chat room', (WidgetTester tester) async {
      bool routeCalled = false;
      String? calledRoute;

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: NavigationService.navigatorKey,
          home: const Scaffold(
            body: Text('Home'),
          ),
          onGenerateRoute: (settings) {
            routeCalled = true;
            calledRoute = settings.name;
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Text('Chat Room'),
              ),
            );
          },
        ),
      );

      // Test navigation to chat room
      await NavigationService.navigateToChatRoom(123);
      await tester.pumpAndSettle();

      expect(routeCalled, isTrue);
      expect(calledRoute, equals('/chat/123'));
    });

    testWidgets('should handle navigation to home', (WidgetTester tester) async {
      bool routeCalled = false;
      String? calledRoute;

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: NavigationService.navigatorKey,
          home: const Scaffold(
            body: Text('Current Screen'),
          ),
          onGenerateRoute: (settings) {
            routeCalled = true;
            calledRoute = settings.name;
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Text('Home'),
              ),
            );
          },
        ),
      );

      // Test navigation to home
      await NavigationService.navigateToHome();
      await tester.pumpAndSettle();

      expect(routeCalled, isTrue);
      expect(calledRoute, equals('/'));
    });

    testWidgets('should handle pushNamed correctly', (WidgetTester tester) async {
      bool routeCalled = false;
      String? calledRoute;

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: NavigationService.navigatorKey,
          home: const Scaffold(
            body: Text('Home'),
          ),
          onGenerateRoute: (settings) {
            routeCalled = true;
            calledRoute = settings.name;
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Text('Target Screen'),
              ),
            );
          },
        ),
      );

      // Test pushNamed
      await NavigationService.pushNamed('/test-route');
      await tester.pumpAndSettle();

      expect(routeCalled, isTrue);
      expect(calledRoute, equals('/test-route'));
    });
  });
}
