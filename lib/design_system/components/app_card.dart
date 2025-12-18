import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';

/// A customizable card component with consistent elevation,
/// border radius, and padding. Supports tap interaction with ripple effect.
///
/// Requirements: 1.4
class AppCard extends StatelessWidget {
  /// The card content.
  final Widget child;

  /// Callback when card is tapped.
  final VoidCallback? onTap;

  /// Callback when card is long pressed.
  final VoidCallback? onLongPress;

  /// Custom padding for the card content.
  final EdgeInsetsGeometry? padding;

  /// Custom margin around the card.
  final EdgeInsetsGeometry? margin;

  /// Custom border radius.
  final BorderRadius? borderRadius;

  /// Custom elevation (0-4 scale).
  final double elevation;

  /// Whether to show a border.
  final bool showBorder;

  /// Custom background color.
  final Color? backgroundColor;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.margin,
    this.borderRadius,
    this.elevation = 0,
    this.showBorder = true,
    this.backgroundColor,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? const DarkAppColors() : const LightAppColors();

    final effectiveBorderRadius = borderRadius ?? 
        BorderRadius.circular(AppSpacing.radiusMd);
    final effectivePadding = padding ?? 
        const EdgeInsets.all(AppSpacing.cardPadding);
    final effectiveBackgroundColor = backgroundColor ?? colors.surface;

    Widget cardContent = Container(
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: effectiveBorderRadius,
        border: showBorder
            ? Border.all(color: colors.outline, width: 1)
            : null,
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05 * elevation),
                  blurRadius: 4 * elevation,
                  offset: Offset(0, 2 * elevation),
                ),
              ]
            : null,
      ),
      child: child,
    );

    // Wrap with InkWell for tap interaction if callbacks provided
    if (onTap != null || onLongPress != null) {
      cardContent = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: effectiveBorderRadius,
          splashColor: colors.primary.withValues(alpha: 0.1),
          highlightColor: colors.primary.withValues(alpha: 0.05),
          child: cardContent,
        ),
      );
    }

    // Apply margin if provided
    if (margin != null) {
      cardContent = Padding(
        padding: margin!,
        child: cardContent,
      );
    }

    // Wrap with Semantics for accessibility
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: cardContent,
    );
  }
}
