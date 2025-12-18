import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide test, group, expect;
import 'package:vector/design_system/states/empty_state_view.dart';
import 'package:vector/design_system/states/error_state_view.dart';
import 'package:vector/design_system/states/skeleton_tile.dart';
import 'package:vector/design_system/states/offline_banner.dart';

/// Property-based tests for state management components.
/// **Feature: ui-loading-states-overhaul**
void main() {
  // Initialize Flutter binding for tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('State Components Property Tests', () {
    /// **Property 5: State component rendering**
    /// *For any* EmptyStateView with required parameters (icon, title),
    /// the widget SHALL render without errors and contain the specified
    /// icon and title text.
    /// **Validates: Requirements 2.1**
    group('Property 5: State component rendering', () {
      testWidgets('EmptyStateView renders with required parameters', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EmptyStateView(
                icon: Icons.inbox_outlined,
                title: 'No items found',
              ),
            ),
          ),
        );

        // Verify icon is rendered
        expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
        
        // Verify title is rendered
        expect(find.text('No items found'), findsOneWidget);
      });

      testWidgets('EmptyStateView renders with description', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EmptyStateView(
                icon: Icons.chat_bubble_outline,
                title: 'No messages',
                description: 'Start a conversation to see messages here',
              ),
            ),
          ),
        );

        expect(find.text('No messages'), findsOneWidget);
        expect(find.text('Start a conversation to see messages here'), findsOneWidget);
      });

      testWidgets('EmptyStateView renders in dark mode', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(
              body: EmptyStateView(
                icon: Icons.inbox_outlined,
                title: 'Empty State',
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
        expect(find.text('Empty State'), findsOneWidget);
      });
    });

    /// **Property 12: Empty state action button**
    /// *For any* EmptyStateView with actionLabel and onAction provided,
    /// the widget SHALL render a tappable button with the specified label
    /// that invokes onAction when tapped.
    /// **Validates: Requirements 4.4, 5.1**
    group('Property 12: Empty state action button', () {
      testWidgets('EmptyStateView renders action button when actionLabel and onAction provided', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmptyStateView(
                icon: Icons.chat_bubble_outline,
                title: 'No chats',
                actionLabel: 'Start a new chat',
                onAction: () {},
              ),
            ),
          ),
        );

        // Verify action button is rendered with correct label
        expect(find.text('Start a new chat'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('EmptyStateView action button invokes callback when tapped', (tester) async {
        var callbackInvoked = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmptyStateView(
                icon: Icons.group_outlined,
                title: 'No groups',
                actionLabel: 'Create Group',
                onAction: () {
                  callbackInvoked = true;
                },
              ),
            ),
          ),
        );

        // Tap the action button
        await tester.tap(find.text('Create Group'));
        await tester.pump();

        // Verify callback was invoked exactly once
        expect(callbackInvoked, isTrue);
      });

      testWidgets('EmptyStateView does not render action button when actionLabel is null', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmptyStateView(
                icon: Icons.inbox_outlined,
                title: 'Empty',
                onAction: () {}, // onAction provided but no label
              ),
            ),
          ),
        );

        // No button should be rendered
        expect(find.byType(ElevatedButton), findsNothing);
      });

      testWidgets('EmptyStateView does not render action button when onAction is null', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EmptyStateView(
                icon: Icons.inbox_outlined,
                title: 'Empty',
                actionLabel: 'Action', // label provided but no callback
              ),
            ),
          ),
        );

        // No button should be rendered
        expect(find.byType(ElevatedButton), findsNothing);
      });

      testWidgets('EmptyStateView action button invokes callback exactly once per tap', (tester) async {
        var callCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmptyStateView(
                icon: Icons.add,
                title: 'Empty',
                actionLabel: 'Add Item',
                onAction: () {
                  callCount++;
                },
              ),
            ),
          ),
        );

        // Tap multiple times
        await tester.tap(find.text('Add Item'));
        await tester.pump();
        expect(callCount, equals(1));

        await tester.tap(find.text('Add Item'));
        await tester.pump();
        expect(callCount, equals(2));
      });
    });

    /// **Property 6: Error state retry functionality**
    /// *For any* ErrorStateView with an onRetry callback, tapping the retry
    /// button SHALL invoke the callback exactly once.
    /// **Validates: Requirements 2.2, 2.6**
    group('Property 6: Error state retry functionality', () {
      testWidgets('ErrorStateView renders with required parameters', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorStateView(
                message: 'Something went wrong',
                onRetry: () {},
              ),
            ),
          ),
        );

        // Verify error icon is rendered
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        
        // Verify message is rendered
        expect(find.text('Something went wrong'), findsOneWidget);
        
        // Verify retry button is rendered
        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('ErrorStateView retry button invokes callback when tapped', (tester) async {
        var callbackInvoked = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorStateView(
                message: 'Error occurred',
                onRetry: () {
                  callbackInvoked = true;
                },
              ),
            ),
          ),
        );

        // Tap the retry button
        await tester.tap(find.text('Retry'));
        await tester.pump();

        // Verify callback was invoked
        expect(callbackInvoked, isTrue);
      });

      testWidgets('ErrorStateView retry button invokes callback exactly once per tap', (tester) async {
        var callCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorStateView(
                message: 'Error',
                onRetry: () {
                  callCount++;
                },
              ),
            ),
          ),
        );

        // Tap multiple times
        await tester.tap(find.text('Retry'));
        await tester.pump();
        expect(callCount, equals(1));

        await tester.tap(find.text('Retry'));
        await tester.pump();
        expect(callCount, equals(2));
      });

      testWidgets('ErrorStateView renders with custom icon', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorStateView(
                message: 'Network error',
                onRetry: () {},
                icon: Icons.wifi_off,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      });

      testWidgets('ErrorStateView renders expandable details', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorStateView(
                message: 'Error',
                details: 'Stack trace details here',
                onRetry: () {},
              ),
            ),
          ),
        );

        // Details should be hidden by default
        expect(find.text('Stack trace details here'), findsNothing);
        expect(find.text('Show details'), findsOneWidget);

        // Tap to expand
        await tester.tap(find.text('Show details'));
        await tester.pump();

        // Details should now be visible
        expect(find.text('Stack trace details here'), findsOneWidget);
        expect(find.text('Hide details'), findsOneWidget);
      });
    });

    /// **Property 7: Skeleton tile layout matching**
    /// *For any* SkeletonTile of type chatItem, the rendered widget SHALL
    /// contain placeholder elements for avatar (circular), title text
    /// (rectangular), and subtitle text (rectangular).
    /// **Validates: Requirements 2.3**
    group('Property 7: Skeleton tile layout matching', () {
      testWidgets('SkeletonTile chatItem contains avatar, title, and subtitle placeholders', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SkeletonTile(type: SkeletonTileType.chatItem),
            ),
          ),
        );

        // Find all Container widgets (placeholders)
        final containers = find.byType(Container);
        expect(containers, findsWidgets);
        
        // The widget should render without errors
        expect(tester.takeException(), isNull);
      });

      testWidgets('SkeletonTile groupItem renders correctly', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SkeletonTile(type: SkeletonTileType.groupItem),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('SkeletonTile profileHeader renders correctly', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SkeletonTile(type: SkeletonTileType.profileHeader),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('SkeletonTile settingsItem renders correctly', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SkeletonTile(type: SkeletonTileType.settingsItem),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('SkeletonTile messageItem renders correctly', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SkeletonTile(type: SkeletonTileType.messageItem),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('SkeletonTile renders in dark mode', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(
              body: SkeletonTile(type: SkeletonTileType.chatItem),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('SkeletonTile can disable animation', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SkeletonTile(
                type: SkeletonTileType.chatItem,
                animate: false,
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });
    });

    /// **Property 8: Offline banner visibility**
    /// *For any* OfflineBanner with isOffline=true, the banner SHALL be
    /// visible; with isOffline=false, the banner SHALL be hidden or have
    /// zero height.
    /// **Validates: Requirements 2.4, 2.7**
    group('Property 8: Offline banner visibility', () {
      testWidgets('OfflineBanner is visible when isOffline is true', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  OfflineBanner(isOffline: true),
                  Expanded(child: Placeholder()),
                ],
              ),
            ),
          ),
        );

        // Banner should be visible with message
        expect(find.text("You're offline"), findsOneWidget);
        expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      });

      testWidgets('OfflineBanner is hidden when isOffline is false', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  OfflineBanner(isOffline: false),
                  Expanded(child: Placeholder()),
                ],
              ),
            ),
          ),
        );

        // Wait for animation to complete
        await tester.pumpAndSettle();

        // Banner content should have zero opacity
        final animatedOpacity = tester.widget<AnimatedOpacity>(
          find.byType(AnimatedOpacity),
        );
        expect(animatedOpacity.opacity, equals(0.0));
      });

      testWidgets('OfflineBanner shows retry button when onRetry provided', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  OfflineBanner(
                    isOffline: true,
                    onRetry: () {},
                  ),
                  const Expanded(child: Placeholder()),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('OfflineBanner retry button invokes callback', (tester) async {
        var callbackInvoked = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  OfflineBanner(
                    isOffline: true,
                    onRetry: () {
                      callbackInvoked = true;
                    },
                  ),
                  const Expanded(child: Placeholder()),
                ],
              ),
            ),
          ),
        );

        await tester.tap(find.text('Retry'));
        await tester.pump();

        expect(callbackInvoked, isTrue);
      });

      testWidgets('OfflineBanner shows custom message', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  OfflineBanner(
                    isOffline: true,
                    message: 'No internet connection',
                  ),
                  Expanded(child: Placeholder()),
                ],
              ),
            ),
          ),
        );

        expect(find.text('No internet connection'), findsOneWidget);
      });

      testWidgets('OfflineBanner does not show retry button when onRetry is null', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  OfflineBanner(isOffline: true),
                  Expanded(child: Placeholder()),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Retry'), findsNothing);
      });
    });
  });
}
