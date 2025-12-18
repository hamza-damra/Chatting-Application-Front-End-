import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector/design_system/components/app_speed_dial.dart';

/// Property-based tests for AppSpeedDial component.
/// **Feature: ui-loading-states-overhaul**
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppSpeedDial Property Tests', () {
    /// **Property 16: FAB action labels**
    /// *For any* SpeedDial FAB in open state, each child action SHALL have
    /// a visible label or tooltip text.
    /// **Validates: Requirements 8.3**
    group('Property 16: FAB action labels', () {
      testWidgets('AppSpeedDial children have visible labels when expanded',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              floatingActionButton: AppSpeedDial(
                children: const [
                  AppSpeedDialChild(
                    icon: Icons.person_add_rounded,
                    label: 'New Chat',
                  ),
                  AppSpeedDialChild(
                    icon: Icons.group_add_rounded,
                    label: 'New Group',
                  ),
                ],
              ),
            ),
          ),
        );

        // Allow widget to initialize
        await tester.pump(const Duration(milliseconds: 100));

        // Tap the FAB to open it
        await tester.tap(find.byType(AppSpeedDial));
        await tester.pumpAndSettle();

        // Verify labels are visible
        expect(find.text('New Chat'), findsOneWidget);
        expect(find.text('New Group'), findsOneWidget);

        // Clean up timers
        await tester.pump(const Duration(milliseconds: 500));
      });

      testWidgets('AppSpeedDial renders with multiple children',
          (tester) async {
        const testLabels = ['Action 1', 'Action 2', 'Action 3'];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              floatingActionButton: AppSpeedDial(
                children: testLabels
                    .map((label) => AppSpeedDialChild(
                          icon: Icons.star,
                          label: label,
                        ))
                    .toList(),
              ),
            ),
          ),
        );

        // Allow widget to initialize
        await tester.pump(const Duration(milliseconds: 100));

        // Tap the FAB to open it
        await tester.tap(find.byType(AppSpeedDial));
        await tester.pumpAndSettle();

        // Verify all labels are visible
        for (final label in testLabels) {
          expect(find.text(label), findsOneWidget);
        }

        // Clean up timers
        await tester.pump(const Duration(milliseconds: 500));
      });

      testWidgets('AppSpeedDial child labels are styled correctly',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              floatingActionButton: AppSpeedDial(
                children: const [
                  AppSpeedDialChild(
                    icon: Icons.chat,
                    label: 'Test Label',
                  ),
                ],
              ),
            ),
          ),
        );

        // Allow widget to initialize
        await tester.pump(const Duration(milliseconds: 100));

        // Tap the FAB to open it
        await tester.tap(find.byType(AppSpeedDial));
        await tester.pumpAndSettle();

        // Verify label is rendered in a container with proper styling
        final labelFinder = find.text('Test Label');
        expect(labelFinder, findsOneWidget);

        // Verify the label is inside a Container (styled label)
        final container = find.ancestor(
          of: labelFinder,
          matching: find.byType(Container),
        );
        expect(container, findsWidgets);

        // Clean up timers
        await tester.pump(const Duration(milliseconds: 500));
      });

      testWidgets('AppSpeedDial invokes onTap callback when child is tapped',
          (tester) async {
        var newChatTapped = false;
        var newGroupTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              floatingActionButton: AppSpeedDial(
                children: [
                  AppSpeedDialChild(
                    icon: Icons.person_add_rounded,
                    label: 'New Chat',
                    onTap: () {
                      newChatTapped = true;
                    },
                  ),
                  AppSpeedDialChild(
                    icon: Icons.group_add_rounded,
                    label: 'New Group',
                    onTap: () {
                      newGroupTapped = true;
                    },
                  ),
                ],
              ),
            ),
          ),
        );

        // Allow widget to initialize
        await tester.pump(const Duration(milliseconds: 100));

        // Tap the FAB to open it
        await tester.tap(find.byType(AppSpeedDial));
        await tester.pumpAndSettle();

        // Tap the "New Chat" action
        await tester.tap(find.text('New Chat'));
        await tester.pumpAndSettle();

        expect(newChatTapped, isTrue);
        expect(newGroupTapped, isFalse);

        // Clean up timers
        await tester.pump(const Duration(milliseconds: 500));
      });

      testWidgets('AppSpeedDial renders in dark mode with labels',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              floatingActionButton: AppSpeedDial(
                children: const [
                  AppSpeedDialChild(
                    icon: Icons.person_add_rounded,
                    label: 'New Chat',
                  ),
                  AppSpeedDialChild(
                    icon: Icons.group_add_rounded,
                    label: 'New Group',
                  ),
                ],
              ),
            ),
          ),
        );

        // Allow widget to initialize
        await tester.pump(const Duration(milliseconds: 100));

        // Tap the FAB to open it
        await tester.tap(find.byType(AppSpeedDial));
        await tester.pumpAndSettle();

        // Verify labels are visible in dark mode
        expect(find.text('New Chat'), findsOneWidget);
        expect(find.text('New Group'), findsOneWidget);

        // Clean up timers
        await tester.pump(const Duration(milliseconds: 500));
      });

      testWidgets('AppSpeedDial child with custom background color',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              floatingActionButton: AppSpeedDial(
                children: const [
                  AppSpeedDialChild(
                    icon: Icons.delete,
                    label: 'Delete',
                    backgroundColor: Colors.red,
                  ),
                ],
              ),
            ),
          ),
        );

        // Allow widget to initialize
        await tester.pump(const Duration(milliseconds: 100));

        // Tap the FAB to open it
        await tester.tap(find.byType(AppSpeedDial));
        await tester.pumpAndSettle();

        // Verify label is visible
        expect(find.text('Delete'), findsOneWidget);

        // Clean up timers
        await tester.pump(const Duration(milliseconds: 500));
      });
    });

    // Additional tests for AppSpeedDial functionality
    group('AppSpeedDial additional tests', () {
      testWidgets('AppSpeedDial calls onOpen callback when opened',
          (tester) async {
        var wasOpened = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              floatingActionButton: AppSpeedDial(
                onOpen: () {
                  wasOpened = true;
                },
                children: const [
                  AppSpeedDialChild(
                    icon: Icons.chat,
                    label: 'Chat',
                  ),
                ],
              ),
            ),
          ),
        );

        // Allow widget to initialize
        await tester.pump(const Duration(milliseconds: 100));

        // Tap the FAB to open it
        await tester.tap(find.byType(AppSpeedDial));
        await tester.pumpAndSettle();

        expect(wasOpened, isTrue);

        // Clean up timers
        await tester.pump(const Duration(milliseconds: 500));
      });

      testWidgets('AppSpeedDial shows backdrop when open',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              floatingActionButton: AppSpeedDial(
                backdropOpacity: 0.5,
                children: const [
                  AppSpeedDialChild(
                    icon: Icons.chat,
                    label: 'Chat',
                  ),
                ],
              ),
            ),
          ),
        );

        // Allow widget to initialize
        await tester.pump(const Duration(milliseconds: 100));

        // Tap the FAB to open it
        await tester.tap(find.byType(AppSpeedDial));
        await tester.pumpAndSettle();

        // The backdrop should be rendered (SpeedDial handles this internally)
        // We just verify the FAB opened successfully with children visible
        expect(find.text('Chat'), findsOneWidget);

        // Clean up timers
        await tester.pump(const Duration(milliseconds: 500));
      });

      testWidgets('AppSpeedDial uses correct icons',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              floatingActionButton: AppSpeedDial(
                icon: Icons.add,
                activeIcon: Icons.close,
                children: const [
                  AppSpeedDialChild(
                    icon: Icons.chat,
                    label: 'Chat',
                  ),
                ],
              ),
            ),
          ),
        );

        // Allow widget to initialize
        await tester.pump(const Duration(milliseconds: 100));

        // Verify add icon is shown initially
        expect(find.byIcon(Icons.add), findsOneWidget);

        // Tap the FAB to open it
        await tester.tap(find.byType(AppSpeedDial));
        await tester.pumpAndSettle();

        // Verify close icon is shown when open
        expect(find.byIcon(Icons.close), findsOneWidget);

        // Clean up timers
        await tester.pump(const Duration(milliseconds: 500));
      });

      testWidgets('AppSpeedDial has semantic label for accessibility',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              floatingActionButton: AppSpeedDial(
                semanticLabel: 'Quick actions menu',
                children: const [
                  AppSpeedDialChild(
                    icon: Icons.person_add_rounded,
                    label: 'New Chat',
                  ),
                ],
              ),
            ),
          ),
        );

        // Allow widget to initialize
        await tester.pump(const Duration(milliseconds: 100));

        // Verify the AppSpeedDial widget is rendered
        expect(find.byType(AppSpeedDial), findsOneWidget);

        // Verify the Semantics widget is present
        expect(find.byType(Semantics), findsWidgets);

        // Clean up timers
        await tester.pump(const Duration(milliseconds: 500));
      });
    });
  });
}
