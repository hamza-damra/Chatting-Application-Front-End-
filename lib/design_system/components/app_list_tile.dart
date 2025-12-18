import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';

/// Trailing widget type for AppListTile.
enum AppListTileTrailing {
  /// No trailing widget.
  none,

  /// Chevron icon for navigation items.
  chevron,

  /// Switch toggle for boolean settings.
  toggle,

  /// Custom widget (use trailingWidget parameter).
  custom,
}

/// A customizable list tile component with support for leading icon/avatar,
/// title, subtitle, and various trailing widgets.
///
/// Requirements: 7.2
class AppListTile extends StatelessWidget {
  /// The title text.
  final String title;

  /// Optional subtitle text.
  final String? subtitle;

  /// Leading icon.
  final IconData? leadingIcon;

  /// Leading widget (takes precedence over leadingIcon).
  final Widget? leadingWidget;

  /// Trailing widget type.
  final AppListTileTrailing trailing;

  /// Custom trailing widget (used when trailing is AppListTileTrailing.custom).
  final Widget? trailingWidget;

  /// Toggle value (used when trailing is AppListTileTrailing.toggle).
  final bool? toggleValue;

  /// Callback when toggle changes (used when trailing is AppListTileTrailing.toggle).
  final ValueChanged<bool>? onToggleChanged;

  /// Callback when tile is tapped.
  final VoidCallback? onTap;

  /// Whether the tile is enabled.
  final bool enabled;

  /// Custom padding.
  final EdgeInsetsGeometry? padding;

  /// Whether to show a divider below the tile.
  final bool showDivider;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  /// Leading icon color override.
  final Color? leadingIconColor;

  /// Whether this is a destructive action (uses error color).
  final bool isDestructive;

  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.leadingWidget,
    this.trailing = AppListTileTrailing.none,
    this.trailingWidget,
    this.toggleValue,
    this.onToggleChanged,
    this.onTap,
    this.enabled = true,
    this.padding,
    this.showDivider = false,
    this.semanticLabel,
    this.leadingIconColor,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? const DarkAppColors() : const LightAppColors();

    final effectivePadding = padding ??
        const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        );
    
    // Ensure minimum touch target height for accessibility
    const minHeight = AppSpacing.minTouchTarget;

    final titleColor = !enabled
        ? colors.textTertiary
        : (isDestructive ? colors.error : colors.textPrimary);
    final subtitleColor = colors.textSecondary;
    final iconColor = !enabled
        ? colors.textTertiary
        : (leadingIconColor ?? (isDestructive ? colors.error : colors.textSecondary));

    Widget content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding: effectivePadding,
        child: Row(
        children: [
          // Leading widget or icon
          if (leadingWidget != null) ...[
            leadingWidget!,
            const SizedBox(width: AppSpacing.lg),
          ] else if (leadingIcon != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                leadingIcon,
                color: iconColor,
                size: AppSpacing.iconLg,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
          ],

          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: titleColor,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 14,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Trailing widget
          _buildTrailing(colors),
        ],
        ),
      ),
    );

    // Wrap with InkWell for tap interaction
    if (onTap != null && enabled) {
      content = InkWell(
        onTap: onTap,
        splashColor: colors.primary.withValues(alpha: 0.1),
        highlightColor: colors.primary.withValues(alpha: 0.05),
        child: content,
      );
    }

    // Add divider if needed
    if (showDivider) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          content,
          Divider(
            height: 1,
            thickness: 1,
            color: colors.divider,
            indent: leadingIcon != null || leadingWidget != null
                ? AppSpacing.lg + 40 + AppSpacing.lg
                : AppSpacing.lg,
            endIndent: AppSpacing.lg,
          ),
        ],
      );
    }

    // Wrap with Semantics for accessibility
    return Semantics(
      button: onTap != null,
      enabled: enabled,
      label: semanticLabel ?? title,
      child: content,
    );
  }

  Widget _buildTrailing(AppColors colors) {
    switch (trailing) {
      case AppListTileTrailing.none:
        return const SizedBox.shrink();

      case AppListTileTrailing.chevron:
        return Icon(
          Icons.chevron_right,
          color: enabled ? colors.textTertiary : colors.textTertiary.withValues(alpha: 0.5),
          size: AppSpacing.iconLg,
        );

      case AppListTileTrailing.toggle:
        return Semantics(
          toggled: toggleValue ?? false,
          label: '$title toggle',
          child: Switch(
            value: toggleValue ?? false,
            onChanged: enabled ? onToggleChanged : null,
            activeThumbColor: colors.primary,
            activeTrackColor: colors.primary.withValues(alpha: 0.5),
            inactiveThumbColor: colors.textTertiary,
            inactiveTrackColor: colors.outline,
          ),
        );

      case AppListTileTrailing.custom:
        return trailingWidget ?? const SizedBox.shrink();
    }
  }
}
