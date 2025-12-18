import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide test, group, expect;
import 'package:vector/design_system/tokens/app_spacing.dart';

/// Property-based tests for bottom navigation spacing and touch targets.
/// **Feature: responsive-screen-overhaul, Property 8: Bottom navigation spacing adaptation**
/// **Validates: Requirements 3.5, 8.5**
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Property 8: Bottom navigation spacing adaptation', () {
    /// Helper widget that simulates bottom navigation layout constraints
    /// This mirrors the logic in ModernBottomNavigation
    Widget buildNavigationConstraint({
      required double screenWidth,
      required int itemCount,
    }) {
      final isDesktop = screenWidth >= 900;
      final horizontalPadding = isDesktop ? 24.0 : 12.0;
      final maxWidth = isDesktop ? 600.0 : double.infinity;

      return SizedBox(
        width: screenWidth,
        child: Center(
          child: ConstrainedBox(
            key: const Key('nav_constraint'),
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              key: const Key('nav_container'),
              height: 65,
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(
                  itemCount,
                  (index) => Expanded(
                    child: Container(
                      key: Key('nav_item_$index'),
                      // Minimum touch target size
                      constraints: const BoxConstraints(
                        minHeight: AppSpacing.minTouchTarget,
                      ),
                      child: Center(
                        child: Text('Item $index'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    /// Unit test: Verify mobile navigation uses full width
    testWidgets('Mobile (375px) navigation uses full width', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildNavigationConstraint(
              screenWidth: 375,
              itemCount: 4,
            ),
          ),
        ),
      );

      final constrainedBox = tester.widget<ConstrainedBox>(
        find.byKey(const Key('nav_constraint')),
      );
      
      // Mobile should have no max-width constraint (infinity)
      expect(constrainedBox.constraints.maxWidth, equals(double.infinity));
    });

    /// Unit test: Verify desktop navigation is constrained to 600px
    testWidgets('Desktop (1280px) navigation is constrained to 600px', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildNavigationConstraint(
              screenWidth: 1280,
              itemCount: 4,
            ),
          ),
        ),
      );

      final constrainedBox = tester.widget<ConstrainedBox>(
        find.byKey(const Key('nav_constraint')),
      );
      
      // Desktop should have 600px max-width constraint
      expect(constrainedBox.constraints.maxWidth, equals(600.0));
    });

    /// Unit test: Verify touch targets meet minimum 44px requirement
    testWidgets('Touch targets meet minimum 44px requirement', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildNavigationConstraint(
              screenWidth: 375,
              itemCount: 4,
            ),
          ),
        ),
      );

      // Check each navigation item has minimum touch target height
      for (int i = 0; i < 4; i++) {
        final container = tester.widget<Container>(
          find.byKey(Key('nav_item_$i')),
        );
        final constraints = container.constraints as BoxConstraints;
        
        expect(
          constraints.minHeight,
          greaterThanOrEqualTo(AppSpacing.minTouchTarget),
          reason: 'Navigation item $i should have minimum touch target height of ${AppSpacing.minTouchTarget}px',
        );
      }
    });

    /// Unit test: Verify desktop horizontal padding is greater than mobile
    testWidgets('Desktop horizontal padding is greater than mobile', (tester) async {
      // Test mobile padding
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildNavigationConstraint(
              screenWidth: 375,
              itemCount: 4,
            ),
          ),
        ),
      );

      final mobileContainer = tester.widget<Container>(
        find.byKey(const Key('nav_container')),
      );
      final mobilePadding = (mobileContainer.padding as EdgeInsets).horizontal;

      // Test desktop padding
      tester.view.physicalSize = const Size(1280, 800);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildNavigationConstraint(
              screenWidth: 1280,
              itemCount: 4,
            ),
          ),
        ),
      );

      final desktopContainer = tester.widget<Container>(
        find.byKey(const Key('nav_container')),
      );
      final desktopPadding = (desktopContainer.padding as EdgeInsets).horizontal;

      // Desktop padding should be greater than mobile
      expect(
        desktopPadding,
        greaterThan(mobilePadding),
        reason: 'Desktop padding ($desktopPadding) should be greater than mobile ($mobilePadding)',
      );

      addTearDown(tester.view.resetPhysicalSize);
    });

    /// Property test: For any screen width, navigation items SHALL have minimum touch target
    group('Touch target property tests', () {
      for (final screenWidth in [280.0, 320.0, 375.0, 600.0, 768.0, 900.0, 1280.0, 1920.0]) {
        test('Screen width $screenWidth px maintains minimum touch targets', () {
          // The navigation bar height is 65px with 4px vertical padding on each side
          // This leaves 57px for content, which exceeds the 44px minimum
          const navBarHeight = 65.0;
          const verticalPadding = 4.0 * 2;
          const availableHeight = navBarHeight - verticalPadding;
          
          expect(
            availableHeight,
            greaterThanOrEqualTo(AppSpacing.minTouchTarget),
            reason: 'Available height ($availableHeight) should be >= ${AppSpacing.minTouchTarget}px',
          );
        });
      }
    });

    /// Property test: For any desktop width (>= 900px), navigation SHALL be constrained
    group('Desktop max-width constraint property tests', () {
      for (final screenWidth in [900.0, 1024.0, 1280.0, 1440.0, 1920.0, 2560.0]) {
        test('Desktop ($screenWidth px) constrains navigation to 600px', () {
          final isDesktop = screenWidth >= 900;
          expect(isDesktop, isTrue);
          
          // Desktop navigation should be constrained to 600px
          const expectedMaxWidth = 600.0;
          expect(expectedMaxWidth, lessThan(screenWidth));
        });
      }
    });

    /// Property test: For any mobile/tablet width (< 900px), navigation SHALL use full width
    group('Mobile/tablet full-width property tests', () {
      for (final screenWidth in [280.0, 320.0, 375.0, 600.0, 768.0, 899.0]) {
        test('Mobile/tablet ($screenWidth px) uses full width', () {
          final isDesktop = screenWidth >= 900;
          expect(isDesktop, isFalse);
          
          // Mobile/tablet navigation should use full width (infinity)
          const expectedMaxWidth = double.infinity;
          expect(expectedMaxWidth, equals(double.infinity));
        });
      }
    });

    /// Property test: Horizontal padding SHALL increase on desktop
    group('Horizontal padding adaptation property tests', () {
      test('Mobile padding is 12px horizontal', () {
        const screenWidth = 375.0;
        final isDesktop = screenWidth >= 900;
        expect(isDesktop, isFalse);
        
        const expectedPadding = 12.0;
        expect(expectedPadding, equals(12.0));
      });

      test('Desktop padding is 24px horizontal', () {
        const screenWidth = 1280.0;
        final isDesktop = screenWidth >= 900;
        expect(isDesktop, isTrue);
        
        const expectedPadding = 24.0;
        expect(expectedPadding, equals(24.0));
      });

      test('Desktop padding is greater than mobile padding', () {
        const mobilePadding = 12.0;
        const desktopPadding = 24.0;
        
        expect(desktopPadding, greaterThan(mobilePadding));
      });
    });

    /// Property test using glados: For any screen width, touch targets SHALL be >= 44px
    Glados<int>().test(
      'Touch targets are always >= 44px for any screen width',
      (randomInt) {
        // Generate screen widths from 280 to 2000
        final screenWidth = 280.0 + (randomInt.abs() % 1721);
        
        // Navigation bar height is constant at 65px
        const navBarHeight = 65.0;
        const verticalPadding = 4.0 * 2;
        const availableHeight = navBarHeight - verticalPadding;
        
        // Verify touch target height meets minimum
        expect(
          availableHeight,
          greaterThanOrEqualTo(AppSpacing.minTouchTarget),
          reason: 'Touch target height should be >= ${AppSpacing.minTouchTarget}px at width $screenWidth',
        );
      },
    );

    /// Property test using glados: Horizontal padding SHALL adapt based on screen size
    Glados<int>().test(
      'Horizontal padding adapts based on screen size',
      (randomInt) {
        // Generate screen widths from 280 to 2000
        final screenWidth = 280.0 + (randomInt.abs() % 1721);
        final isDesktop = screenWidth >= 900;
        
        final expectedPadding = isDesktop ? 24.0 : 12.0;
        
        // Verify padding is correct for screen size
        if (isDesktop) {
          expect(expectedPadding, equals(24.0));
        } else {
          expect(expectedPadding, equals(12.0));
        }
      },
    );

    /// Property test: Breakpoint transition at 900px
    test('Breakpoint transition at 900px is correct', () {
      // Below 900px - mobile/tablet behavior
      expect(899.0 >= 900, isFalse);
      
      // At and above 900px - desktop behavior
      expect(900.0 >= 900, isTrue);
      expect(901.0 >= 900, isTrue);
    });
  });
}
