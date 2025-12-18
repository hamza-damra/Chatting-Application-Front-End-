import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';

/// An animated banner component that displays connectivity status
/// at the top of screens when the device is offline.
/// 
/// Integrates with ConnectivityService to show/hide based on
/// network status.
class OfflineBanner extends StatelessWidget {
  /// Whether the device is currently offline.
  final bool isOffline;
  
  /// Optional callback when the retry button is tapped.
  final VoidCallback? onRetry;
  
  /// Custom message to display. Defaults to "You're offline".
  final String? message;
  
  /// Animation duration for show/hide transitions.
  final Duration animationDuration;

  const OfflineBanner({
    super.key,
    required this.isOffline,
    this.onRetry,
    this.message,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = isDark ? const DarkAppColors() : const LightAppColors();
    
    return AnimatedContainer(
      duration: animationDuration,
      curve: Curves.easeInOut,
      height: isOffline ? null : 0,
      child: AnimatedOpacity(
        duration: animationDuration,
        opacity: isOffline ? 1.0 : 0.0,
        child: Material(
          color: colors.error.withValues(alpha: 0.9),
          child: SafeArea(
            bottom: false,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: isOffline ? AppSpacing.sm : 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.wifi_off,
                    size: AppSpacing.iconSm,
                    color: colors.textOnPrimary,
                    semanticLabel: 'No internet connection',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      message ?? "You're offline",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textOnPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    Semantics(
                      button: true,
                      label: 'Retry connection',
                      child: GestureDetector(
                        onTap: onRetry,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: colors.textOnPrimary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                          ),
                          child: Text(
                            'Retry',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.textOnPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A wrapper widget that automatically shows/hides the OfflineBanner
/// based on connectivity status from a stream.
class ConnectivityAwareOfflineBanner extends StatelessWidget {
  /// Stream of connectivity status (true = online, false = offline).
  final Stream<bool> connectivityStream;
  
  /// Initial connectivity status.
  final bool initialIsOnline;
  
  /// Optional callback when retry is tapped.
  final VoidCallback? onRetry;

  const ConnectivityAwareOfflineBanner({
    super.key,
    required this.connectivityStream,
    this.initialIsOnline = true,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: connectivityStream,
      initialData: initialIsOnline,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;
        return OfflineBanner(
          isOffline: !isOnline,
          onRetry: onRetry,
        );
      },
    );
  }
}
