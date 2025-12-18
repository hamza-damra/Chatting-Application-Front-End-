import 'package:flutter/material.dart';
import 'async_state.dart';
import 'empty_state_view.dart';
import 'error_state_view.dart';
import 'skeleton_tile.dart';

/// A convenience widget that handles all async states with sensible defaults.
/// 
/// Provides a declarative way to build UI based on the current [AsyncState].
/// Each state type can have a custom builder, or will use sensible defaults.
class AsyncStateBuilder<T> extends StatelessWidget {
  /// The current async state to render.
  final AsyncState<T> state;
  
  /// Builder for the loaded state with data.
  final Widget Function(T data) onLoaded;
  
  /// Optional builder for the loading state.
  /// Defaults to a centered CircularProgressIndicator.
  final Widget Function()? onLoading;
  
  /// Optional builder for the error state.
  /// Defaults to [ErrorStateView].
  final Widget Function(String message, VoidCallback? onRetry)? onError;
  
  /// Optional builder for the empty state.
  /// Defaults to [EmptyStateView].
  final Widget Function(String? message, VoidCallback? onAction)? onEmpty;
  
  /// Optional skeleton tile type to use for loading state.
  /// If provided, will show skeleton tiles instead of default loading indicator.
  final SkeletonTileType? skeletonType;
  
  /// Number of skeleton tiles to show when loading.
  final int skeletonCount;
  
  /// Default empty state icon.
  final IconData emptyIcon;
  
  /// Default empty state title.
  final String emptyTitle;
  
  /// Default empty state action label.
  final String? emptyActionLabel;

  const AsyncStateBuilder({
    super.key,
    required this.state,
    required this.onLoaded,
    this.onLoading,
    this.onError,
    this.onEmpty,
    this.skeletonType,
    this.skeletonCount = 5,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyTitle = 'No items found',
    this.emptyActionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      AsyncLoading() => _buildLoading(context),
      AsyncLoaded(:final data) => onLoaded(data),
      AsyncError(:final message, :final onRetry) => _buildError(context, message, onRetry),
      AsyncEmpty(:final message, :final onAction) => _buildEmpty(context, message, onAction),
    };
  }

  Widget _buildLoading(BuildContext context) {
    if (onLoading != null) {
      return onLoading!();
    }
    
    if (skeletonType != null) {
      return ListView.builder(
        itemCount: skeletonCount,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) => SkeletonTile(type: skeletonType!),
      );
    }
    
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildError(BuildContext context, String message, VoidCallback? onRetry) {
    if (onError != null) {
      return onError!(message, onRetry);
    }
    
    return ErrorStateView(
      message: message,
      onRetry: onRetry ?? () {},
    );
  }

  Widget _buildEmpty(BuildContext context, String? message, VoidCallback? onAction) {
    if (onEmpty != null) {
      return onEmpty!(message, onAction);
    }
    
    return EmptyStateView(
      icon: emptyIcon,
      title: emptyTitle,
      description: message,
      actionLabel: emptyActionLabel,
      onAction: onAction,
    );
  }
}
