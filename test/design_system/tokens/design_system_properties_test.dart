import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide test, group, expect;
import 'package:vector/design_system/tokens/app_colors.dart';
import 'package:vector/design_system/tokens/app_spacing.dart';
import 'package:vector/design_system/tokens/app_typography.dart';

/// Property-based tests for design system tokens.
/// **Feature: ui-loading-states-overhaul**
void main() {
  // Initialize Flutter binding for tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Design System Property Tests', () {
    /// **Property 1: Design system color tokens completeness**
    /// *For any* theme mode (light or dark), the AppColors implementation
    /// SHALL provide non-null Color values for all required tokens.
    /// **Validates: Requirements 1.1**
    group('Property 1: Design system color tokens completeness', () {
      test('LightAppColors provides all required color tokens', () {
        const colors = LightAppColors();

        // Background colors
        expect(colors.background, isA<Color>());
        expect(colors.surface, isA<Color>());
        expect(colors.surfaceElevated, isA<Color>());
        expect(colors.surfaceHighest, isA<Color>());

        // Text colors
        expect(colors.textPrimary, isA<Color>());
        expect(colors.textSecondary, isA<Color>());
        expect(colors.textTertiary, isA<Color>());
        expect(colors.textOnPrimary, isA<Color>());

        // Brand colors
        expect(colors.primary, isA<Color>());
        expect(colors.primaryLight, isA<Color>());
        expect(colors.secondary, isA<Color>());

        // Semantic colors
        expect(colors.success, isA<Color>());
        expect(colors.warning, isA<Color>());
        expect(colors.error, isA<Color>());
        expect(colors.info, isA<Color>());

        // Border/Outline colors
        expect(colors.outline, isA<Color>());
        expect(colors.outlineVariant, isA<Color>());
        expect(colors.divider, isA<Color>());

        // Shimmer colors
        expect(colors.shimmerBase, isA<Color>());
        expect(colors.shimmerHighlight, isA<Color>());
      });

      test('DarkAppColors provides all required color tokens', () {
        const colors = DarkAppColors();

        // Background colors
        expect(colors.background, isA<Color>());
        expect(colors.surface, isA<Color>());
        expect(colors.surfaceElevated, isA<Color>());
        expect(colors.surfaceHighest, isA<Color>());

        // Text colors
        expect(colors.textPrimary, isA<Color>());
        expect(colors.textSecondary, isA<Color>());
        expect(colors.textTertiary, isA<Color>());
        expect(colors.textOnPrimary, isA<Color>());

        // Brand colors
        expect(colors.primary, isA<Color>());
        expect(colors.primaryLight, isA<Color>());
        expect(colors.secondary, isA<Color>());

        // Semantic colors
        expect(colors.success, isA<Color>());
        expect(colors.warning, isA<Color>());
        expect(colors.error, isA<Color>());
        expect(colors.info, isA<Color>());

        // Border/Outline colors
        expect(colors.outline, isA<Color>());
        expect(colors.outlineVariant, isA<Color>());
        expect(colors.divider, isA<Color>());

        // Shimmer colors
        expect(colors.shimmerBase, isA<Color>());
        expect(colors.shimmerHighlight, isA<Color>());
      });
    });

    /// **Property 2: Typography scale completeness**
    /// *For any* AppTypography implementation, all text styles SHALL have
    /// defined fontSize and fontWeight properties.
    /// **Validates: Requirements 1.2**
    group('Property 2: Typography scale completeness', () {
      test('TestAppTypography provides all text styles with fontSize and fontWeight', () {
        // Using TestAppTypography to avoid Google Fonts asset loading issues in tests
        final typography = TestAppTypography(textColor: Colors.black);

        // Verify all styles exist and have required properties
        for (final style in typography.allStyles) {
          expect(style.fontSize, isNotNull,
              reason: 'All text styles must have a fontSize');
          expect(style.fontSize, greaterThan(0),
              reason: 'fontSize must be positive');
          expect(style.fontWeight, isNotNull,
              reason: 'All text styles must have a fontWeight');
        }
      });

      test('Typography uses provided text color for all styles', () {
        const testColor = Color(0xFF123456);
        final typography = TestAppTypography(textColor: testColor);

        // All styles should use the provided color
        for (final style in typography.allStyles) {
          expect(style.color, equals(testColor));
        }
      });

      test('Typography has correct number of styles (12)', () {
        final typography = TestAppTypography(textColor: Colors.black);
        expect(typography.allStyles.length, equals(12));
      });

      Glados<int>().test(
        'Typography works with any valid color value',
        (colorValue) {
          // Constrain to valid color range
          final clampedValue = colorValue.abs() % 0xFFFFFFFF;
          final color = Color(clampedValue | 0xFF000000); // Ensure alpha is set
          final typography = TestAppTypography(textColor: color);

          // All styles should use the provided color
          for (final style in typography.allStyles) {
            expect(style.color, equals(color));
          }
        },
      );
    });

    /// **Property 3: Spacing system consistency**
    /// *For any* spacing value in AppSpacing, the value SHALL be a multiple
    /// of 4.0 (the base unit).
    /// **Validates: Requirements 1.3**
    group('Property 3: Spacing system consistency', () {
      test('All base spacing values are multiples of 4', () {
        for (final spacing in AppSpacing.allBaseSpacings) {
          expect(
            AppSpacing.isValidSpacing(spacing),
            isTrue,
            reason: 'Spacing value $spacing should be a multiple of 4',
          );
        }
      });

      test('Semantic spacing values are multiples of 4', () {
        final semanticSpacings = [
          AppSpacing.cardPadding,
          AppSpacing.listItemPadding,
          AppSpacing.sectionSpacing,
          AppSpacing.screenPadding,
          AppSpacing.inputPadding,
          AppSpacing.buttonPadding,
          AppSpacing.iconPadding,
        ];

        for (final spacing in semanticSpacings) {
          expect(
            AppSpacing.isValidSpacing(spacing),
            isTrue,
            reason: 'Semantic spacing value $spacing should be a multiple of 4',
          );
        }
      });

      Glados<int>().test(
        'isValidSpacing correctly validates multiples of 4',
        (multiplier) {
          // Only test reasonable multipliers to avoid overflow
          if (multiplier.abs() > 1000) return;

          final value = multiplier * 4.0;
          expect(
            AppSpacing.isValidSpacing(value),
            isTrue,
            reason: '$value should be valid (multiple of 4)',
          );
        },
      );
    });

    /// **Property 4: Dark theme surface differentiation**
    /// *For any* dark theme configuration, the surface colors SHALL NOT be
    /// pure black (#000000) and SHALL have distinct luminance values.
    /// **Validates: Requirements 1.5**
    group('Property 4: Dark theme surface differentiation', () {
      test('Dark theme surfaces are not pure black', () {
        const colors = DarkAppColors();

        // None of the surface colors should be pure black
        expect(colors.background, isNot(equals(const Color(0xFF000000))),
            reason: 'background should not be pure black');
        expect(colors.surface, isNot(equals(const Color(0xFF000000))),
            reason: 'surface should not be pure black');
        expect(colors.surfaceElevated, isNot(equals(const Color(0xFF000000))),
            reason: 'surfaceElevated should not be pure black');
        expect(colors.surfaceHighest, isNot(equals(const Color(0xFF000000))),
            reason: 'surfaceHighest should not be pure black');
      });

      test('Dark theme surfaces have distinct luminance values creating hierarchy', () {
        const colors = DarkAppColors();

        final backgroundLuminance = colors.background.computeLuminance();
        final surfaceLuminance = colors.surface.computeLuminance();
        final surfaceElevatedLuminance = colors.surfaceElevated.computeLuminance();
        final surfaceHighestLuminance = colors.surfaceHighest.computeLuminance();

        // Each elevated surface should be lighter (higher luminance) than the one below
        expect(surfaceLuminance, greaterThan(backgroundLuminance),
            reason: 'surface should be lighter than background');
        expect(surfaceElevatedLuminance, greaterThan(surfaceLuminance),
            reason: 'surfaceElevated should be lighter than surface');
        expect(surfaceHighestLuminance, greaterThan(surfaceElevatedLuminance),
            reason: 'surfaceHighest should be lighter than surfaceElevated');
      });

      test('All dark theme surface luminance values are distinct', () {
        const colors = DarkAppColors();

        final luminances = {
          colors.background.computeLuminance(),
          colors.surface.computeLuminance(),
          colors.surfaceElevated.computeLuminance(),
          colors.surfaceHighest.computeLuminance(),
        };

        // All 4 luminance values should be unique
        expect(luminances.length, equals(4),
            reason: 'All surface colors should have distinct luminance values');
      });
    });
  });
}
