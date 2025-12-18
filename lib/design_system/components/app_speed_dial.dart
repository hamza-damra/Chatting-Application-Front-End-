import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';

/// An enhanced Speed Dial FAB component that uses design system tokens
/// and provides smooth animations with backdrop effects.
///
/// Features:
/// - Theme-consistent colors from design system
/// - Smooth open/close animations with easing curves
/// - Backdrop dim/blur effect when open
/// - Visible labels and tooltips for action items
/// - Safe area awareness
class AppSpeedDial extends StatefulWidget {
  /// The list of action items to display when the FAB is expanded.
  final List<AppSpeedDialChild> children;

  /// Icon to display when the FAB is closed.
  final IconData icon;

  /// Icon to display when the FAB is open.
  final IconData activeIcon;

  /// Callback when the FAB is opened.
  final VoidCallback? onOpen;

  /// Callback when the FAB is closed.
  final VoidCallback? onClose;

  /// Whether to use blur effect for backdrop (default: false for performance).
  final bool useBlurBackdrop;

  /// Opacity of the backdrop overlay (0.0 to 1.0).
  final double backdropOpacity;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  /// Whether the FAB is visible.
  final bool visible;

  /// Spacing from the edge of the screen.
  final double? marginEnd;
  final double? marginBottom;

  const AppSpeedDial({
    super.key,
    required this.children,
    this.icon = Icons.add_rounded,
    this.activeIcon = Icons.close_rounded,
    this.onOpen,
    this.onClose,
    this.useBlurBackdrop = false,
    this.backdropOpacity = 0.5,
    this.semanticLabel,
    this.visible = true,
    this.marginEnd,
    this.marginBottom,
  });

  @override
  State<AppSpeedDial> createState() => _AppSpeedDialState();
}

class _AppSpeedDialState extends State<AppSpeedDial>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<bool> _isDialOpen = ValueNotifier(false);

  @override
  void dispose() {
    _isDialOpen.dispose();
    super.dispose();
  }

  AppColors _getColors(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const DarkAppColors()
        : const LightAppColors();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getColors(context);
    final theme = Theme.of(context);

    return Semantics(
      label: widget.semanticLabel ?? 'Quick actions menu',
      button: true,
      child: SpeedDial(
        icon: widget.icon,
        activeIcon: widget.activeIcon,
        visible: widget.visible,
        openCloseDial: _isDialOpen,

        // Theme-consistent colors
        backgroundColor: colors.primary,
        foregroundColor: colors.textOnPrimary,
        activeBackgroundColor: colors.error,
        activeForegroundColor: colors.textOnPrimary,

        // Shape and elevation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.lg),
        ),
        elevation: 6,
        buttonSize: const Size(56, 56),
        childrenButtonSize: const Size(48, 48),

        // Smooth animations with easing curves
        animationCurve: Curves.easeInOutCubic,
        animationDuration: const Duration(milliseconds: 250),

        // Backdrop effect
        overlayColor: colors.background,
        overlayOpacity: widget.backdropOpacity,
        renderOverlay: true,

        // Spacing and positioning
        spacing: AppSpacing.md,
        spaceBetweenChildren: AppSpacing.sm,
        childMargin: EdgeInsets.only(right: AppSpacing.xs),
        
        // Safe area margins
        switchLabelPosition: false,

        // Tooltip for main button
        tooltip: 'Open quick actions',

        // Callbacks
        onOpen: () {
          _isDialOpen.value = true;
          widget.onOpen?.call();
        },
        onClose: () {
          _isDialOpen.value = false;
          widget.onClose?.call();
        },

        // Child action items
        children: widget.children.map((child) {
          return SpeedDialChild(
            child: Icon(
              child.icon,
              color: colors.textOnPrimary,
              size: 22,
              semanticLabel: child.label,
            ),
            backgroundColor: child.backgroundColor ?? colors.primary,
            foregroundColor: colors.textOnPrimary,
            label: child.label,
            labelWidget: child.labelWidget ??
                _buildLabel(
                  context,
                  child.label,
                  colors,
                  theme,
                ),
            labelBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.md),
            ),
            elevation: 4,
            onTap: child.onTap,
            visible: child.visible,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLabel(
    BuildContext context,
    String label,
    AppColors colors,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A child action item for the AppSpeedDial.
class AppSpeedDialChild {
  /// The icon to display for this action.
  final IconData icon;

  /// The label text for this action (used for tooltip and label).
  final String label;

  /// Callback when this action is tapped.
  final VoidCallback? onTap;

  /// Optional custom background color (defaults to primary).
  final Color? backgroundColor;

  /// Optional custom label widget (overrides default label).
  final Widget? labelWidget;

  /// Whether this action is visible.
  final bool visible;

  const AppSpeedDialChild({
    required this.icon,
    required this.label,
    this.onTap,
    this.backgroundColor,
    this.labelWidget,
    this.visible = true,
  });
}
