import 'package:flutter/material.dart';
import '../tokens/app_spacing.dart';

/// A utility class for showing responsive dialogs that adapt to screen size.
///
/// On mobile devices, dialogs use full width with standard margins.
/// On tablet and desktop, dialogs are constrained to a maximum width of 400px.
class ResponsiveDialog {
  /// Shows a responsive alert dialog that adapts to screen size.
  ///
  /// On tablet/desktop (width >= 600px), the dialog is constrained to 400px max width.
  /// On mobile, the dialog uses standard Material dialog sizing.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget title,
    Widget? content,
    List<Widget>? actions,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
    Offset? anchorPoint,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= AppSpacing.breakpointMobile;

    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      anchorPoint: anchorPoint,
      builder: (context) {
        Widget dialog = AlertDialog(
          title: title,
          content: content,
          actions: actions,
        );

        // Constrain dialog width on larger screens
        if (isLargeScreen) {
          dialog = ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: ResponsiveMaxWidths.dialog,
            ),
            child: dialog,
          );
        }

        return dialog;
      },
    );
  }

  /// Shows a responsive confirmation dialog with Yes/No or custom actions.
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    String? message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);

    return show<bool>(
      context: context,
      title: Text(title),
      content: message != null ? Text(message) : null,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: confirmColor ??
                (isDestructive ? theme.colorScheme.error : null),
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }

  /// Shows a responsive custom dialog with full control over content.
  ///
  /// The dialog is constrained to 400px max width on tablet/desktop.
  static Future<T?> showCustom<T>({
    required BuildContext context,
    required Widget Function(BuildContext context) builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= AppSpacing.breakpointMobile;

    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      builder: (context) {
        Widget dialog = builder(context);

        // Constrain dialog width on larger screens
        if (isLargeScreen) {
          dialog = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: ResponsiveMaxWidths.dialog,
              ),
              child: dialog,
            ),
          );
        }

        return dialog;
      },
    );
  }
}

/// A widget that wraps content in a responsive dialog container.
///
/// Use this when building custom dialog content that needs responsive constraints.
class ResponsiveDialogContainer extends StatelessWidget {
  /// The child widget to display inside the dialog.
  final Widget child;

  /// Maximum width for the dialog on large screens.
  final double maxWidth;

  /// Padding around the dialog content.
  final EdgeInsets? padding;

  /// Background color for the dialog.
  final Color? backgroundColor;

  /// Border radius for the dialog.
  final BorderRadius? borderRadius;

  const ResponsiveDialogContainer({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveMaxWidths.dialog,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= AppSpacing.breakpointMobile;

    Widget content = Material(
      color: backgroundColor ?? theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
      borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSpacing.xxl),
        child: child,
      ),
    );

    if (isLargeScreen) {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: content,
      );
    }

    return Center(child: content);
  }
}


/// A utility class for showing adaptive bottom sheets that become dialogs on desktop.
///
/// On mobile devices, shows a standard bottom sheet.
/// On tablet and desktop (width >= 600px), shows a centered dialog instead.
class AdaptiveBottomSheet {
  /// Shows an adaptive bottom sheet that becomes a dialog on larger screens.
  ///
  /// On mobile: Shows a standard modal bottom sheet
  /// On tablet/desktop: Shows a centered dialog constrained to 400px max width
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget Function(BuildContext context) builder,
    bool isDismissible = true,
    bool enableDrag = true,
    bool useRootNavigator = false,
    bool isScrollControlled = false,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    Color? barrierColor,
    RouteSettings? routeSettings,
    AnimationController? transitionAnimationController,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= AppSpacing.breakpointMobile;

    if (isLargeScreen) {
      // Show as dialog on tablet/desktop
      return showDialog<T>(
        context: context,
        barrierDismissible: isDismissible,
        barrierColor: barrierColor,
        useRootNavigator: useRootNavigator,
        routeSettings: routeSettings,
        builder: (context) {
          final dialogTheme = Theme.of(context).dialogTheme;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: ResponsiveMaxWidths.dialog,
              ),
              child: Material(
                color: backgroundColor ?? dialogTheme.backgroundColor ?? Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                clipBehavior: Clip.antiAlias,
                elevation: elevation ?? 24.0,
                child: builder(context),
              ),
            ),
          );
        },
      );
    } else {
      // Show as bottom sheet on mobile
      return showModalBottomSheet<T>(
        context: context,
        builder: builder,
        isDismissible: isDismissible,
        enableDrag: enableDrag,
        useRootNavigator: useRootNavigator,
        isScrollControlled: isScrollControlled,
        backgroundColor: backgroundColor,
        elevation: elevation,
        shape: shape ?? const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg),
          ),
        ),
        clipBehavior: clipBehavior,
        constraints: constraints,
        barrierColor: barrierColor,
        routeSettings: routeSettings,
        transitionAnimationController: transitionAnimationController,
      );
    }
  }

  /// Shows an adaptive action sheet with a list of actions.
  ///
  /// On mobile: Shows as a bottom sheet with action tiles
  /// On tablet/desktop: Shows as a dialog with action buttons
  static Future<T?> showActions<T>({
    required BuildContext context,
    required List<AdaptiveSheetAction<T>> actions,
    String? title,
    String? message,
    bool isDismissible = true,
    Widget? cancelAction,
  }) {
    final theme = Theme.of(context);

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.xxl,
              AppSpacing.xxl,
              AppSpacing.sm,
            ),
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        if (message != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.sm,
              AppSpacing.xxl,
              AppSpacing.lg,
            ),
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
        const Divider(height: 1),
        ...actions.map((action) => _buildActionTile(context, action)),
        if (cancelAction != null) ...[
          const Divider(height: 1),
          cancelAction,
        ],
        // Add safe area padding for bottom sheets on mobile
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ],
    );

    return show<T>(
      context: context,
      isDismissible: isDismissible,
      builder: (context) => content,
    );
  }

  static Widget _buildActionTile<T>(
    BuildContext context,
    AdaptiveSheetAction<T> action,
  ) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        Navigator.of(context).pop(action.value);
        action.onPressed?.call();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            if (action.icon != null) ...[
              Icon(
                action.icon,
                color: action.isDestructive
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurface,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.lg),
            ],
            Expanded(
              child: Text(
                action.label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: action.isDestructive
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurface,
                  fontWeight: action.isDestructive ? FontWeight.w600 : null,
                ),
              ),
            ),
            if (action.trailing != null) action.trailing!,
          ],
        ),
      ),
    );
  }
}

/// Represents an action in an adaptive action sheet.
class AdaptiveSheetAction<T> {
  /// The label text for the action.
  final String label;

  /// Optional icon to display before the label.
  final IconData? icon;

  /// The value to return when this action is selected.
  final T? value;

  /// Callback when the action is pressed.
  final VoidCallback? onPressed;

  /// Whether this action is destructive (shown in red).
  final bool isDestructive;

  /// Optional trailing widget.
  final Widget? trailing;

  const AdaptiveSheetAction({
    required this.label,
    this.icon,
    this.value,
    this.onPressed,
    this.isDestructive = false,
    this.trailing,
  });
}
