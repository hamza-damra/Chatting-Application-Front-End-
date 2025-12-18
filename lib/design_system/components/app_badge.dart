import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';

/// Badge type options for different styling.
enum AppBadgeType {
  /// Primary badge (default).
  primary,

  /// Secondary badge.
  secondary,

  /// Success badge (green).
  success,

  /// Warning badge (yellow/orange).
  warning,

  /// Error/danger badge (red).
  error,

  /// Info badge (blue).
  info,

  /// Neutral badge (gray).
  neutral,
}

/// Badge size options.
enum AppBadgeSize {
  /// Small badge.
  small,

  /// Medium badge (default).
  medium,

  /// Large badge.
  large,
}

/// A customizable badge component for displaying counts or status indicators.
/// Supports count display with 99+ truncation and different colors.
///
/// Requirements: 4.1
class AppBadge extends StatelessWidget {
  /// The count to display. If null, shows as a dot indicator.
  final int? count;

  /// Custom text to display (takes precedence over count).
  final String? text;

  /// The badge type for color styling.
  final AppBadgeType type;

  /// The badge size.
  final AppBadgeSize size;

  /// Whether to show as a dot indicator (ignores count/text).
  final bool showAsDot;

  /// Maximum count before showing "99+".
  final int maxCount;

  /// Custom background color (overrides type color).
  final Color? backgroundColor;

  /// Custom text color.
  final Color? textColor;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  const AppBadge({
    super.key,
    this.count,
    this.text,
    this.type = AppBadgeType.primary,
    this.size = AppBadgeSize.medium,
    this.showAsDot = false,
    this.maxCount = 99,
    this.backgroundColor,
    this.textColor,
    this.semanticLabel,
  });

  /// Creates a badge that shows as a simple dot indicator.
  const AppBadge.dot({
    super.key,
    this.type = AppBadgeType.primary,
    this.backgroundColor,
    this.semanticLabel,
  })  : count = null,
        text = null,
        size = AppBadgeSize.small,
        showAsDot = true,
        maxCount = 99,
        textColor = null;

  /// Creates a badge for displaying unread count.
  const AppBadge.count({
    super.key,
    required int this.count,
    this.type = AppBadgeType.primary,
    this.size = AppBadgeSize.medium,
    this.maxCount = 99,
    this.backgroundColor,
    this.textColor,
    this.semanticLabel,
  })  : text = null,
        showAsDot = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? const DarkAppColors() : const LightAppColors();

    final effectiveBackgroundColor = backgroundColor ?? _getBackgroundColor(colors);
    final effectiveTextColor = textColor ?? _getTextColor(colors);

    // Show as dot indicator
    if (showAsDot) {
      final dotSize = _getDotSize();
      return Semantics(
        label: semanticLabel ?? 'Notification indicator',
        child: Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: effectiveBackgroundColor,
          ),
        ),
      );
    }

    // Don't show badge if count is 0 or negative and no text
    if (count != null && count! <= 0 && text == null) {
      return const SizedBox.shrink();
    }

    // Determine display text
    final displayText = text ?? _formatCount(count);
    if (displayText == null) {
      return const SizedBox.shrink();
    }

    final minSize = _getMinSize();
    final fontSize = _getFontSize();
    final horizontalPadding = _getHorizontalPadding();

    return Semantics(
      label: semanticLabel ?? (count != null ? '$count items' : displayText),
      child: Container(
        constraints: BoxConstraints(
          minWidth: minSize,
          minHeight: minSize,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: effectiveBackgroundColor,
          borderRadius: BorderRadius.circular(minSize / 2),
        ),
        child: Center(
          child: Text(
            displayText,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: effectiveTextColor,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  String? _formatCount(int? count) {
    if (count == null) return null;
    if (count <= 0) return null;
    if (count > maxCount) return '$maxCount+';
    return count.toString();
  }

  double _getDotSize() {
    switch (size) {
      case AppBadgeSize.small:
        return 8;
      case AppBadgeSize.medium:
        return 10;
      case AppBadgeSize.large:
        return 12;
    }
  }

  double _getMinSize() {
    switch (size) {
      case AppBadgeSize.small:
        return 16;
      case AppBadgeSize.medium:
        return 20;
      case AppBadgeSize.large:
        return 24;
    }
  }

  double _getFontSize() {
    switch (size) {
      case AppBadgeSize.small:
        return 10;
      case AppBadgeSize.medium:
        return 11;
      case AppBadgeSize.large:
        return 13;
    }
  }

  double _getHorizontalPadding() {
    switch (size) {
      case AppBadgeSize.small:
        return 4;
      case AppBadgeSize.medium:
        return 6;
      case AppBadgeSize.large:
        return 8;
    }
  }

  Color _getBackgroundColor(AppColors colors) {
    switch (type) {
      case AppBadgeType.primary:
        return colors.primary;
      case AppBadgeType.secondary:
        return colors.secondary;
      case AppBadgeType.success:
        return colors.success;
      case AppBadgeType.warning:
        return colors.warning;
      case AppBadgeType.error:
        return colors.error;
      case AppBadgeType.info:
        return colors.info;
      case AppBadgeType.neutral:
        return colors.textTertiary;
    }
  }

  Color _getTextColor(AppColors colors) {
    switch (type) {
      case AppBadgeType.warning:
        // Warning typically needs dark text for contrast
        return colors.textPrimary;
      default:
        return colors.textOnPrimary;
    }
  }
}
