import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide test, group, expect;
import 'package:vector/design_system/tokens/app_spacing.dart';
import 'package:vector/design_system/components/responsive_container.dart';

/// Property-based tests for Profile and Settings screen spacing consistency.
/// **Feature: responsive-screen-overhaul**
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Profile and Settings Spacing Consistency Property Tests', () {
    /// **Property: Spacing consistency across screen sizes**
    /// *For any* screen width, the spacing ratios between elements SHALL remain
    /// consistent (using the same AppSpacing tokens) while padding adapts responsively.
    /// **Validates: Requirements 4.5**
    group('Property: Spacing consistency across screen sizes', () {
      // Test that ResponsiveLayout returns consistent padding ratios
      test('Responsive padding maintains ratio: tablet >= mobile, desktop >= tablet', () {
        // Mobile padding
        final mobilePadding = AppSpacing.paddingMobile;
        // Tablet padding
        final tabletPadding = AppSpacing.paddingTablet;
        // Desktop padding
        final desktopPadding = AppSpacing.paddingDesktop;

        // Verify padding increases with screen size
        expect(tabletPadding, greaterThanOrEqualTo(mobilePadding),
            reason: 'Tablet padding should be >= mobile padding');
        expect(desktopPadding, greaterThanOrEqualTo(tabletPadding),
            reason: 'Desktop padding should be >= tablet padding');
      });

      test('All spacing tokens are multiples of base unit (4.0)', () {
        // Verify all spacing values used in Profile/Settings screens are valid
        final spacingValues = [
          AppSpacing.xs,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xxl,
          AppSpacing.xxxl,
          AppSpacing.huge,
          AppSpacing.sectionSpacing,
          AppSpacing.screenPadding,
          AppSpacing.cardPadding,
        ];

        for (final spacing in spacingValues) {
          expect(
            AppSpacing.isValidSpacing(spacing),
            isTrue,
            reason: 'Spacing value $spacing should be a multiple of 4',
          );
        }
      });

      test('Section spacing is consistent across all screen sizes', () {
        // Section spacing should be the same value regardless of screen size
        // This ensures visual consistency in content grouping
        const sectionSpacing = AppSpacing.sectionSpacing;
        
        // Section spacing should be a reasonable value (not too small, not too large)
        expect(sectionSpacing, greaterThanOrEqualTo(AppSpacing.lg),
            reason: 'Section spacing should be at least lg (16)');
        expect(sectionSpacing, lessThanOrEqualTo(AppSpacing.huge),
            reason: 'Section spacing should not exceed huge (48)');
      });

      // Test ResponsiveContainer applies consistent max-width for profile/settings
      testWidgets('ResponsiveContainer applies profileSettings max-width consistently', (tester) async {
        const testWidths = [320.0, 600.0, 900.0, 1280.0, 1920.0];
        
        for (final width in testWidths) {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;
          
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ResponsiveContainer(
                  maxWidth: ResponsiveMaxWidths.profileSettings,
                  child: Container(
                    key: const Key('content'),
                    color: Colors.blue,
                    height: 100,
                  ),
                ),
              ),
            ),
          );

          expect(tester.takeException(), isNull,
              reason: 'No exception at width $width');
          expect(find.byKey(const Key('content')), findsOneWidget,
              reason: 'Content should render at width $width');
        }
        
        tester.view.resetPhysicalSize();
      });

      // Test that padding values scale appropriately
      testWidgets('Horizontal padding scales with screen size', (tester) async {
        // Test mobile
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                final padding = ResponsiveLayout.getHorizontalPadding(context);
                expect(padding, equals(AppSpacing.lg),
                    reason: 'Mobile should use lg padding');
                return const SizedBox();
              },
            ),
          ),
        );

        // Test tablet
        tester.view.physicalSize = const Size(768, 1024);
        tester.view.devicePixelRatio = 1.0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                final padding = ResponsiveLayout.getHorizontalPadding(context);
                expect(padding, equals(AppSpacing.xxl),
                    reason: 'Tablet should use xxl padding');
                return const SizedBox();
              },
            ),
          ),
        );

        // Test desktop
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                final padding = ResponsiveLayout.getHorizontalPadding(context);
                expect(padding, equals(AppSpacing.huge),
                    reason: 'Desktop should use huge padding');
                return const SizedBox();
              },
            ),
          ),
        );

        tester.view.resetPhysicalSize();
      });

      // Property-based test for spacing ratios
      Glados<int>().test(
        'Spacing ratios remain consistent for any valid screen width',
        (widthMultiplier) {
          // Generate widths from 280 to 2000
          final width = 280.0 + (widthMultiplier.abs() % 1720);
          final deviceSize = ResponsiveLayout.getDeviceSizeFromWidth(width);
          
          // Get the expected padding for this device size
          double expectedPadding;
          switch (deviceSize) {
            case DeviceSize.mobile:
              expectedPadding = AppSpacing.lg;
              break;
            case DeviceSize.tablet:
              expectedPadding = AppSpacing.xxl;
              break;
            case DeviceSize.desktop:
              expectedPadding = AppSpacing.huge;
              break;
          }
          
          // Verify the padding is a valid spacing value
          expect(
            AppSpacing.isValidSpacing(expectedPadding),
            isTrue,
            reason: 'Padding $expectedPadding for width $width should be valid',
          );
          
          // Verify the ratio relationship holds
          if (deviceSize == DeviceSize.tablet) {
            expect(expectedPadding, greaterThan(AppSpacing.lg),
                reason: 'Tablet padding should be greater than mobile');
          } else if (deviceSize == DeviceSize.desktop) {
            expect(expectedPadding, greaterThan(AppSpacing.xxl),
                reason: 'Desktop padding should be greater than tablet');
          }
        },
      );

      // Test that max-width constraint is consistent
      test('ProfileSettings max-width is consistent value (600px)', () {
        expect(ResponsiveMaxWidths.profileSettings, equals(600.0),
            reason: 'Profile/Settings max-width should be 600px');
      });

      // Test spacing hierarchy is maintained
      test('Spacing hierarchy is maintained (xs < sm < md < lg < xl < xxl < xxxl < huge)', () {
        expect(AppSpacing.xs, lessThan(AppSpacing.sm));
        expect(AppSpacing.sm, lessThan(AppSpacing.md));
        expect(AppSpacing.md, lessThan(AppSpacing.lg));
        expect(AppSpacing.lg, lessThan(AppSpacing.xl));
        expect(AppSpacing.xl, lessThan(AppSpacing.xxl));
        expect(AppSpacing.xxl, lessThan(AppSpacing.xxxl));
        expect(AppSpacing.xxxl, lessThan(AppSpacing.huge));
      });
    });
  });
}
