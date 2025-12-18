import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector/design_system/tokens/app_spacing.dart';
import 'package:vector/design_system/components/responsive_container.dart';
import 'package:vector/design_system/states/empty_state_view.dart';
import 'package:vector/design_system/states/error_state_view.dart';
import 'package:vector/design_system/components/app_button.dart';
import 'package:vector/design_system/components/app_text_field.dart';
import 'package:vector/design_system/components/app_list_tile.dart';

/// Property-based tests for responsive layouts.
/// **Feature: ui-loading-states-overhaul**
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Responsive Layout Property Tests', () {
    /// **Property 20: Responsive layout adaptation**
    /// *For any* screen rendered at width < 600px (mobile), 600-900px (tablet),
    /// and > 900px (desktop), the layout SHALL adapt without horizontal overflow.
    /// **Validates: Requirements 9.5**
    group('Property 20: Responsive layout adaptation', () {
      // Test breakpoint constants
      test('Breakpoint constants are correctly defined', () {
        expect(AppSpacing.breakpointMobile, equals(600.0));
        expect(AppSpacing.breakpointTablet, equals(900.0));
        expect(AppSpacing.breakpointDesktop, equals(1200.0));
      });

      // Test DeviceSize enum detection
      test('DeviceSize detection works correctly for mobile', () {
        expect(
          ResponsiveLayout.getDeviceSizeFromWidth(320),
          equals(DeviceSize.mobile),
        );
        expect(
          ResponsiveLayout.getDeviceSizeFromWidth(599),
          equals(DeviceSize.mobile),
        );
      });

      test('DeviceSize detection works correctly for tablet', () {
        expect(
          ResponsiveLayout.getDeviceSizeFromWidth(600),
          equals(DeviceSize.tablet),
        );
        expect(
          ResponsiveLayout.getDeviceSizeFromWidth(899),
          equals(DeviceSize.tablet),
        );
      });

      test('DeviceSize detection works correctly for desktop', () {
        expect(
          ResponsiveLayout.getDeviceSizeFromWidth(900),
          equals(DeviceSize.desktop),
        );
        expect(
          ResponsiveLayout.getDeviceSizeFromWidth(1920),
          equals(DeviceSize.desktop),
        );
      });


      // Test mobile layout (< 600px)
      testWidgets('Mobile layout (320px) renders without overflow', (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    const AppTextField(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Submit',
                      onPressed: () {},
                      expanded: true,
                    ),
                    const SizedBox(height: 16),
                    AppListTile(
                      title: 'Settings',
                      subtitle: 'Configure your preferences',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(AppTextField), findsOneWidget);
        expect(find.byType(AppButton), findsOneWidget);
      });

      testWidgets('Mobile layout (375px) renders without overflow', (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmptyStateView(
                icon: Icons.chat_bubble_outline,
                title: 'No chats yet',
                description: 'Start a conversation with someone',
                actionLabel: 'Start Chat',
                onAction: () {},
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('No chats yet'), findsOneWidget);
      });

      // Test tablet layout (600-900px)
      testWidgets('Tablet layout (768px) renders without overflow', (tester) async {
        tester.view.physicalSize = const Size(768, 1024);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    const AppTextField(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Submit',
                      onPressed: () {},
                      expanded: true,
                    ),
                    const SizedBox(height: 16),
                    ErrorStateView(
                      message: 'Something went wrong',
                      onRetry: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(AppTextField), findsOneWidget);
        expect(find.byType(ErrorStateView), findsOneWidget);
      });


      // Test desktop layout (> 900px)
      testWidgets('Desktop layout (1280px) renders without overflow', (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    const AppTextField(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Submit',
                      onPressed: () {},
                      expanded: true,
                    ),
                    const SizedBox(height: 16),
                    AppListTile(
                      title: 'Account Settings',
                      subtitle: 'Manage your account preferences and security',
                      leadingIcon: Icons.settings,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(AppTextField), findsOneWidget);
        expect(find.byType(AppButton), findsOneWidget);
      });

      testWidgets('Desktop layout (1920px) renders without overflow', (tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmptyStateView(
                icon: Icons.group_outlined,
                title: 'No groups yet',
                description: 'Create a new group or join an existing one',
                actionLabel: 'Create Group',
                onAction: () {},
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('No groups yet'), findsOneWidget);
      });

      // Test ResponsiveContainer
      testWidgets('ResponsiveContainer applies max width on desktop', (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResponsiveContainer(
                maxWidth: 600,
                child: Container(
                  color: Colors.blue,
                  height: 100,
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        final containerFinder = find.byType(ConstrainedBox);
        expect(containerFinder, findsOneWidget);
      });

      testWidgets('ResponsiveContainer uses full width on mobile', (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResponsiveContainer(
                centerContent: false,
                child: Container(
                  color: Colors.blue,
                  height: 100,
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });


      // Test ResponsiveBuilder
      testWidgets('ResponsiveBuilder shows mobile layout on small screens', (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResponsiveBuilder(
                mobile: (context) => const Text('Mobile Layout'),
                tablet: (context) => const Text('Tablet Layout'),
                desktop: (context) => const Text('Desktop Layout'),
              ),
            ),
          ),
        );

        expect(find.text('Mobile Layout'), findsOneWidget);
        expect(find.text('Tablet Layout'), findsNothing);
        expect(find.text('Desktop Layout'), findsNothing);
      });

      testWidgets('ResponsiveBuilder shows tablet layout on medium screens', (tester) async {
        tester.view.physicalSize = const Size(768, 1024);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResponsiveBuilder(
                mobile: (context) => const Text('Mobile Layout'),
                tablet: (context) => const Text('Tablet Layout'),
                desktop: (context) => const Text('Desktop Layout'),
              ),
            ),
          ),
        );

        expect(find.text('Mobile Layout'), findsNothing);
        expect(find.text('Tablet Layout'), findsOneWidget);
        expect(find.text('Desktop Layout'), findsNothing);
      });

      testWidgets('ResponsiveBuilder shows desktop layout on large screens', (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResponsiveBuilder(
                mobile: (context) => const Text('Mobile Layout'),
                tablet: (context) => const Text('Tablet Layout'),
                desktop: (context) => const Text('Desktop Layout'),
              ),
            ),
          ),
        );

        expect(find.text('Mobile Layout'), findsNothing);
        expect(find.text('Tablet Layout'), findsNothing);
        expect(find.text('Desktop Layout'), findsOneWidget);
      });

      // Test ResponsiveVisibility
      testWidgets('ResponsiveVisibility hides content on specified screen sizes', (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResponsiveVisibility(
                visibleOnMobile: false,
                visibleOnTablet: true,
                visibleOnDesktop: true,
                child: Text('Hidden on Mobile'),
              ),
            ),
          ),
        );

        expect(find.text('Hidden on Mobile'), findsNothing);
      });

      testWidgets('ResponsiveVisibility shows content on specified screen sizes', (tester) async {
        tester.view.physicalSize = const Size(768, 1024);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResponsiveVisibility(
                visibleOnMobile: false,
                visibleOnTablet: true,
                visibleOnDesktop: true,
                child: Text('Visible on Tablet'),
              ),
            ),
          ),
        );

        expect(find.text('Visible on Tablet'), findsOneWidget);
      });

      // Test ResponsiveRowColumn
      testWidgets('ResponsiveRowColumn uses column on mobile', (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResponsiveRowColumn(
                children: [
                  Text('Item 1'),
                  Text('Item 2'),
                ],
              ),
            ),
          ),
        );

        expect(find.byType(Column), findsOneWidget);
        expect(find.byType(Row), findsNothing);
      });

      testWidgets('ResponsiveRowColumn uses row on desktop', (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResponsiveRowColumn(
                children: [
                  Text('Item 1'),
                  Text('Item 2'),
                ],
              ),
            ),
          ),
        );

        expect(find.byType(Row), findsOneWidget);
      });
    });
  });
}
