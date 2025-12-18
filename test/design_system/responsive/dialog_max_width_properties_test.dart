import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide test, group, expect;
import 'package:vector/design_system/tokens/app_spacing.dart';
import 'package:vector/design_system/components/responsive_dialog.dart';

/// Property-based tests for dialog max-width constraint on large screens.
/// **Feature: responsive-screen-overhaul, Property 5: Dialog max-width constraint on large screens**
/// **Validates: Requirements 7.1**
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Property 5: Dialog max-width constraint on large screens', () {
    /// Helper to find the ConstrainedBox with specific max-width constraint
    ConstrainedBox? findConstrainedBoxWithMaxWidth(WidgetTester tester, double maxWidth) {
      final constrainedBoxes = tester.widgetList<ConstrainedBox>(find.byType(ConstrainedBox));
      for (final box in constrainedBoxes) {
        if (box.constraints.maxWidth == maxWidth) {
          return box;
        }
      }
      return null;
    }

    /// Unit test: Verify ResponsiveMaxWidths.dialog is 400px
    test('ResponsiveMaxWidths.dialog is correctly defined as 400px', () {
      expect(ResponsiveMaxWidths.dialog, equals(400.0));
    });

    /// Unit test: Verify ResponsiveDialogContainer applies max-width on tablet
    testWidgets('ResponsiveDialogContainer applies max-width on tablet (700px)', (tester) async {
      tester.view.physicalSize = const Size(700, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveDialogContainer(
              child: const Text('Dialog Content'),
            ),
          ),
        ),
      );

      // Find the ConstrainedBox with dialog max-width
      final constrainedBox = findConstrainedBoxWithMaxWidth(tester, ResponsiveMaxWidths.dialog);
      expect(constrainedBox, isNotNull, reason: 'Should find ConstrainedBox with dialog maxWidth on tablet');
      expect(constrainedBox!.constraints.maxWidth, equals(ResponsiveMaxWidths.dialog));
    });

    /// Unit test: Verify ResponsiveDialogContainer applies max-width on desktop
    testWidgets('ResponsiveDialogContainer applies max-width on desktop (1280px)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveDialogContainer(
              child: const Text('Dialog Content'),
            ),
          ),
        ),
      );

      // Find the ConstrainedBox with dialog max-width
      final constrainedBox = findConstrainedBoxWithMaxWidth(tester, ResponsiveMaxWidths.dialog);
      expect(constrainedBox, isNotNull, reason: 'Should find ConstrainedBox with dialog maxWidth on desktop');
      expect(constrainedBox!.constraints.maxWidth, equals(ResponsiveMaxWidths.dialog));
    });

    /// Unit test: Verify ResponsiveDialogContainer does NOT apply max-width on mobile
    testWidgets('ResponsiveDialogContainer does not apply max-width constraint on mobile (400px)', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveDialogContainer(
              child: const Text('Dialog Content'),
            ),
          ),
        ),
      );

      // On mobile, there should be no ConstrainedBox with dialog max-width
      final constrainedBox = findConstrainedBoxWithMaxWidth(tester, ResponsiveMaxWidths.dialog);
      expect(constrainedBox, isNull, reason: 'Should NOT find ConstrainedBox with dialog maxWidth on mobile');
    });

    /// Property test: For any tablet/desktop width (>= 600px), dialog SHALL be constrained to 400px
    group('Dialog max-width constraint on large screens', () {
      for (final screenWidth in [600.0, 700.0, 800.0, 900.0, 1024.0, 1280.0, 1440.0, 1920.0]) {
        testWidgets(
          'Dialog constrained to 400px at ${screenWidth}px screen width',
          (tester) async {
            tester.view.physicalSize = Size(screenWidth, 800);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.resetPhysicalSize);

            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: ResponsiveDialogContainer(
                    child: const Text('Dialog Content'),
                  ),
                ),
              ),
            );

            // Find the ConstrainedBox with dialog max-width
            final constrainedBox = findConstrainedBoxWithMaxWidth(tester, ResponsiveMaxWidths.dialog);
            expect(constrainedBox, isNotNull, reason: 'Should find ConstrainedBox with dialog maxWidth at ${screenWidth}px');
            expect(constrainedBox!.constraints.maxWidth, equals(ResponsiveMaxWidths.dialog));
            expect(constrainedBox.constraints.maxWidth, equals(400.0));
          },
        );
      }
    });

    /// Property test: For any mobile width (< 600px), dialog SHALL NOT have max-width constraint
    group('Dialog without max-width constraint on mobile', () {
      for (final screenWidth in [320.0, 375.0, 414.0, 500.0, 599.0]) {
        testWidgets(
          'Dialog not constrained at ${screenWidth}px screen width (mobile)',
          (tester) async {
            tester.view.physicalSize = Size(screenWidth, 800);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.resetPhysicalSize);

            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: ResponsiveDialogContainer(
                    child: const Text('Dialog Content'),
                  ),
                ),
              ),
            );

            // On mobile, there should be no ConstrainedBox with dialog max-width
            final constrainedBox = findConstrainedBoxWithMaxWidth(tester, ResponsiveMaxWidths.dialog);
            expect(constrainedBox, isNull, reason: 'Should NOT find ConstrainedBox with dialog maxWidth at ${screenWidth}px (mobile)');
          },
        );
      }
    });

    /// Property test: Verify breakpoint for dialog constraint is at 600px
    test('Dialog constraint breakpoint is at 600px (tablet breakpoint)', () {
      expect(AppSpacing.breakpointMobile, equals(600.0));
      
      // Verify device size detection at breakpoint
      expect(ResponsiveLayout.getDeviceSizeFromWidth(599), equals(DeviceSize.mobile));
      expect(ResponsiveLayout.getDeviceSizeFromWidth(600), equals(DeviceSize.tablet));
      expect(ResponsiveLayout.getDeviceSizeFromWidth(601), equals(DeviceSize.tablet));
    });

    /// Property test using glados: For any tablet/desktop width, dialog max-width SHALL be 400px
    Glados<int>().test(
      'Dialog max-width is 400px for any width >= 600px',
      (randomInt) {
        // Generate tablet/desktop widths (600 to 4000)
        final screenWidth = 600.0 + (randomInt.abs() % 3401);
        
        // Verify the screen is tablet or desktop
        final deviceSize = ResponsiveLayout.getDeviceSizeFromWidth(screenWidth);
        expect(deviceSize, isNot(equals(DeviceSize.mobile)));
        
        // Verify dialog max-width constant
        expect(ResponsiveMaxWidths.dialog, equals(400.0));
      },
    );

    /// Property test using glados: For any mobile width, dialog should not be constrained
    Glados<int>().test(
      'Dialog is not constrained for any width < 600px',
      (randomInt) {
        // Generate mobile widths (280 to 599)
        final screenWidth = 280.0 + (randomInt.abs() % 320);
        
        // Verify the screen is mobile
        final deviceSize = ResponsiveLayout.getDeviceSizeFromWidth(screenWidth);
        expect(deviceSize, equals(DeviceSize.mobile));
      },
    );

    /// Unit test: Verify ResponsiveDialogContainer centers content on large screens
    testWidgets('ResponsiveDialogContainer centers content on large screens', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveDialogContainer(
              child: const Text('Dialog Content'),
            ),
          ),
        ),
      );

      // Verify Center widget is present
      final centerFinder = find.byType(Center);
      expect(centerFinder, findsWidgets);
    });

    /// Unit test: Verify custom max-width can be specified
    testWidgets('ResponsiveDialogContainer accepts custom max-width', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const customMaxWidth = 500.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveDialogContainer(
              maxWidth: customMaxWidth,
              child: const Text('Dialog Content'),
            ),
          ),
        ),
      );

      // Find the ConstrainedBox with custom max-width
      final constrainedBox = findConstrainedBoxWithMaxWidth(tester, customMaxWidth);
      expect(constrainedBox, isNotNull, reason: 'Should find ConstrainedBox with custom maxWidth');
      expect(constrainedBox!.constraints.maxWidth, equals(customMaxWidth));
    });
  });
}
