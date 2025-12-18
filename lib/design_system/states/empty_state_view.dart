import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';

/// A component that displays an empty state with icon, title, description,
/// and optional action button.
/// 
/// Used when a list or screen has no data to show, providing guidance
/// to the user on what to do next.
/// 
/// Performance optimized with const constructor support.
class EmptyStateView extends StatelessWidget {
  /// The icon to display at the top of the empty state.
  final IconData icon;
  
  /// The main title text.
  final String title;
  
  /// Optional description text below the title.
  final String? description;
  
  /// Optional label for the action button.
  final String? actionLabel;
  
  /// Optional callback when the action button is tapped.
  final VoidCallback? onAction;
  
  /// Optional custom icon widget to use instead of [icon].
  final Widget? customIcon;
  
  /// Icon size. Defaults to 64.
  final double iconSize;
  
  /// Icon color. If null, uses theme's secondary text color.
  final Color? iconColor;

  /// Creates an empty state view with the given parameters.
  /// 
  /// Use const constructor when possible for better performance.
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
    this.customIcon,
    this.iconSize = 64,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = isDark ? const DarkAppColors() : const LightAppColors();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
            // Icon
            customIcon ?? Icon(
              icon,
              size: iconSize,
              color: iconColor ?? colors.textTertiary,
              semanticLabel: 'Empty state icon',
            ),
            
            const SizedBox(height: AppSpacing.xxl),
            
            // Title
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Description
            if (description != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            // Action Button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                height: AppSpacing.minTouchTarget,
                child: ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxl,
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: Text(
                    actionLabel!,
                    semanticsLabel: actionLabel,
                  ),
                ),
              ),
            ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
