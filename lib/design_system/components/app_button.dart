import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';

/// Button variants for AppButton.
enum AppButtonVariant {
  /// Filled button with primary background color.
  filled,

  /// Outlined button with border and transparent background.
  outlined,

  /// Text button with no background or border.
  text,
}

/// Button size options.
enum AppButtonSize {
  small,
  medium,
  large,
}

/// A customizable button component that supports loading state,
/// multiple variants, and destructive styling.
///
/// Requirements: 3.6, 7.4
class AppButton extends StatelessWidget {
  /// The button label text.
  final String label;

  /// Callback when button is pressed. Null disables the button.
  final VoidCallback? onPressed;

  /// The button variant (filled, outlined, or text).
  final AppButtonVariant variant;

  /// The button size.
  final AppButtonSize size;

  /// Whether the button is in loading state.
  final bool isLoading;

  /// Whether to use destructive (red) styling for logout/delete actions.
  final bool isDestructive;

  /// Optional icon to display before the label.
  final IconData? icon;

  /// Whether the button should expand to fill available width.
  final bool expanded;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isDestructive = false,
    this.icon,
    this.expanded = false,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? const DarkAppColors() : const LightAppColors();

    final buttonHeight = _getHeight();
    final horizontalPadding = _getHorizontalPadding();
    final fontSize = _getFontSize();
    final iconSize = _getIconSize();

    // Determine colors based on variant and destructive state
    final backgroundColor = _getBackgroundColor(colors);
    final foregroundColor = _getForegroundColor(colors);
    final borderColor = _getBorderColor(colors);

    // Disable button when loading or onPressed is null
    final isEnabled = onPressed != null && !isLoading;

    Widget buttonChild = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ] else if (icon != null) ...[
          Icon(icon, size: iconSize, color: foregroundColor),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: foregroundColor,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );

    Widget button;

    switch (variant) {
      case AppButtonVariant.filled:
        button = ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            disabledBackgroundColor: backgroundColor.withValues(alpha: 0.5),
            disabledForegroundColor: foregroundColor.withValues(alpha: 0.5),
            minimumSize: Size(
              expanded ? double.infinity : 0,
              buttonHeight,
            ),
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            elevation: 0,
          ),
          child: buttonChild,
        );
        break;

      case AppButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: isEnabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: foregroundColor,
            disabledForegroundColor: foregroundColor.withValues(alpha: 0.5),
            minimumSize: Size(
              expanded ? double.infinity : 0,
              buttonHeight,
            ),
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            side: BorderSide(
              color: isEnabled ? borderColor : borderColor.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: buttonChild,
        );
        break;

      case AppButtonVariant.text:
        button = TextButton(
          onPressed: isEnabled ? onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: foregroundColor,
            disabledForegroundColor: foregroundColor.withValues(alpha: 0.5),
            minimumSize: Size(
              expanded ? double.infinity : 0,
              buttonHeight,
            ),
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
          child: buttonChild,
        );
        break;
    }

    // Wrap with Semantics for accessibility
    return Semantics(
      button: true,
      enabled: isEnabled,
      label: semanticLabel ?? label,
      child: button,
    );
  }

  double _getHeight() {
    switch (size) {
      case AppButtonSize.small:
        return AppSpacing.minTouchTarget; // 44.0 - minimum touch target for accessibility
      case AppButtonSize.medium:
        return AppSpacing.minTouchTarget; // 44.0
      case AppButtonSize.large:
        return 52.0;
    }
  }

  double _getHorizontalPadding() {
    switch (size) {
      case AppButtonSize.small:
        return AppSpacing.md;
      case AppButtonSize.medium:
        return AppSpacing.lg;
      case AppButtonSize.large:
        return AppSpacing.xl;
    }
  }

  double _getFontSize() {
    switch (size) {
      case AppButtonSize.small:
        return 13.0;
      case AppButtonSize.medium:
        return 14.0;
      case AppButtonSize.large:
        return 16.0;
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return 16.0;
      case AppButtonSize.medium:
        return 18.0;
      case AppButtonSize.large:
        return 20.0;
    }
  }

  Color _getBackgroundColor(AppColors colors) {
    if (isDestructive) {
      return colors.error;
    }
    switch (variant) {
      case AppButtonVariant.filled:
        return colors.primary;
      case AppButtonVariant.outlined:
      case AppButtonVariant.text:
        return Colors.transparent;
    }
  }

  Color _getForegroundColor(AppColors colors) {
    if (isDestructive) {
      switch (variant) {
        case AppButtonVariant.filled:
          return colors.textOnPrimary;
        case AppButtonVariant.outlined:
        case AppButtonVariant.text:
          return colors.error;
      }
    }
    switch (variant) {
      case AppButtonVariant.filled:
        return colors.textOnPrimary;
      case AppButtonVariant.outlined:
      case AppButtonVariant.text:
        return colors.primary;
    }
  }

  Color _getBorderColor(AppColors colors) {
    if (isDestructive) {
      return colors.error;
    }
    return colors.primary;
  }
}
