import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';

/// Types of skeleton tiles available for different UI contexts.
enum SkeletonTileType {
  /// Chat list item with avatar, name, message preview, timestamp, and badge.
  chatItem,
  
  /// Group list item with group avatar, name, member count, and message.
  groupItem,
  
  /// Profile header with large avatar and user info.
  profileHeader,
  
  /// Settings list item with icon, title, and trailing widget.
  settingsItem,
  
  /// Message item in chat view.
  messageItem,
}

/// A shimmer-animated placeholder component that mimics the layout
/// of actual content while data is loading.
/// 
/// Provides different skeleton layouts for various UI contexts.
/// 
/// Performance optimized:
/// - Uses RepaintBoundary to isolate shimmer animations
/// - Supports const constructor for static content
/// - Minimizes widget rebuilds
/// 
/// Requirements: 10.3
class SkeletonTile extends StatelessWidget {
  /// The type of skeleton tile to render.
  final SkeletonTileType type;
  
  /// Whether to animate the shimmer effect.
  final bool animate;

  /// Creates a skeleton tile with the given type.
  /// 
  /// Use const constructor when possible for better performance.
  const SkeletonTile({
    super.key,
    required this.type,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = isDark ? const DarkAppColors() : const LightAppColors();
    
    Widget content;
    
    switch (type) {
      case SkeletonTileType.chatItem:
        content = _buildChatItemSkeleton(colors);
      case SkeletonTileType.groupItem:
        content = _buildGroupItemSkeleton(colors);
      case SkeletonTileType.profileHeader:
        content = _buildProfileHeaderSkeleton(colors);
      case SkeletonTileType.settingsItem:
        content = _buildSettingsItemSkeleton(colors);
      case SkeletonTileType.messageItem:
        content = _buildMessageItemSkeleton(colors);
    }
    
    if (!animate) {
      return content;
    }
    
    // Wrap shimmer in RepaintBoundary to isolate animation repaints
    // This prevents the shimmer animation from causing unnecessary
    // repaints in parent widgets, improving performance.
    return RepaintBoundary(
      child: Shimmer.fromColors(
        baseColor: colors.shimmerBase,
        highlightColor: colors.shimmerHighlight,
        period: const Duration(milliseconds: 1500), // Slightly slower for smoother animation
        child: content,
      ),
    );
  }

  Widget _buildChatItemSkeleton(AppColors colors) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colors.outline, width: 0.5),
      ),
      child: Row(
        children: [
          // Avatar placeholder (circular)
          Container(
            width: AppSpacing.avatarMd,
            height: AppSpacing.avatarMd,
            decoration: BoxDecoration(
              color: colors.shimmerBase,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title placeholder (rectangular)
                    Container(
                      width: 120,
                      height: 14,
                      decoration: BoxDecoration(
                        color: colors.shimmerBase,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                      ),
                    ),
                    // Timestamp placeholder
                    Container(
                      width: 40,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colors.shimmerBase,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    // Subtitle placeholder (rectangular)
                    Expanded(
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: colors.shimmerBase,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Badge placeholder
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: colors.shimmerBase,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupItemSkeleton(AppColors colors) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          // Group avatar placeholder
          Container(
            width: AppSpacing.avatarMd,
            height: AppSpacing.avatarMd,
            decoration: BoxDecoration(
              color: colors.shimmerBase,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group name
                Container(
                  width: 140,
                  height: 14,
                  decoration: BoxDecoration(
                    color: colors.shimmerBase,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                // Member count
                Container(
                  width: 80,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colors.shimmerBase,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Last message
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors.shimmerBase,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  ),
                ),
              ],
            ),
          ),
          // Timestamp
          Container(
            width: 40,
            height: 10,
            decoration: BoxDecoration(
              color: colors.shimmerBase,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeaderSkeleton(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          // Large avatar
          Container(
            width: AppSpacing.avatarXl,
            height: AppSpacing.avatarXl,
            decoration: BoxDecoration(
              color: colors.shimmerBase,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Name
          Container(
            width: 160,
            height: 20,
            decoration: BoxDecoration(
              color: colors.shimmerBase,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Email/Status
          Container(
            width: 200,
            height: 14,
            decoration: BoxDecoration(
              color: colors.shimmerBase,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          // Info cards
          ...List.generate(3, (index) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: colors.shimmerBase,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSettingsItemSkeleton(AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          // Icon placeholder
          Container(
            width: AppSpacing.iconLg,
            height: AppSpacing.iconLg,
            decoration: BoxDecoration(
              color: colors.shimmerBase,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          // Title
          Expanded(
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: colors.shimmerBase,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          // Trailing (chevron/switch)
          Container(
            width: AppSpacing.iconMd,
            height: AppSpacing.iconMd,
            decoration: BoxDecoration(
              color: colors.shimmerBase,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItemSkeleton(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar
          Container(
            width: AppSpacing.avatarSm,
            height: AppSpacing.avatarSm,
            decoration: BoxDecoration(
              color: colors.shimmerBase,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Message bubble
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.shimmerBase,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors.shimmerHighlight,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors.shimmerHighlight,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Expanded(flex: 1, child: SizedBox()),
        ],
      ),
    );
  }
}
