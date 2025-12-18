import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';

/// A component that displays an error state with error icon, message,
/// retry button, and optional expandable details.
/// 
/// Used when an operation fails, providing the user with information
/// about what went wrong and an option to retry.
/// 
/// Performance optimized with const constructor support.
class ErrorStateView extends StatefulWidget {
  /// The error message to display.
  final String message;
  
  /// Optional detailed error information (e.g., stack trace).
  final String? details;
  
  /// Callback when the retry button is tapped.
  final VoidCallback onRetry;
  
  /// Whether to show the details section by default.
  final bool showDetails;
  
  /// Optional custom icon. Defaults to error_outline.
  final IconData? icon;
  
  /// Icon size. Defaults to 64.
  final double iconSize;

  /// Creates an error state view with the given parameters.
  /// 
  /// Use const constructor when possible for better performance.
  const ErrorStateView({
    super.key,
    required this.message,
    this.details,
    required this.onRetry,
    this.showDetails = false,
    this.icon,
    this.iconSize = 64,
  });

  @override
  State<ErrorStateView> createState() => _ErrorStateViewState();
}

class _ErrorStateViewState extends State<ErrorStateView> {
  late bool _isDetailsExpanded;

  @override
  void initState() {
    super.initState();
    _isDetailsExpanded = widget.showDetails;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = isDark ? const DarkAppColors() : const LightAppColors();
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error Icon
            Icon(
              widget.icon ?? Icons.error_outline,
              size: widget.iconSize,
              color: colors.error,
              semanticLabel: 'Error icon',
            ),
            
            const SizedBox(height: AppSpacing.xxl),
            
            // Error Message
            Text(
              widget.message,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: AppSpacing.xxl),
            
            // Retry Button
            Semantics(
              button: true,
              label: 'Retry loading',
              child: SizedBox(
                height: AppSpacing.minTouchTarget,
                child: ElevatedButton.icon(
                  onPressed: widget.onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
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
                ),
              ),
            ),
            
            // Expandable Details Section
            if (widget.details != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Semantics(
                button: true,
                label: _isDetailsExpanded ? 'Hide error details' : 'Show error details',
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isDetailsExpanded = !_isDetailsExpanded;
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isDetailsExpanded ? 'Hide details' : 'Show details',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      Icon(
                        _isDetailsExpanded 
                            ? Icons.keyboard_arrow_up 
                            : Icons.keyboard_arrow_down,
                        size: 16,
                        color: colors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              
              if (_isDetailsExpanded) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: colors.outline),
                  ),
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Text(
                      widget.details!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
