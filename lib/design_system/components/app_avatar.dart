import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';

/// Avatar size options.
enum AppAvatarSize {
  /// Small avatar (32px).
  small,

  /// Medium avatar (40px).
  medium,

  /// Large avatar (56px).
  large,

  /// Extra large avatar (80px).
  extraLarge,
}

/// A customizable avatar component with support for image,
/// initials fallback, and online status indicator.
/// 
/// Performance optimized:
/// - Uses cached_network_image for efficient image caching
/// - Shows shimmer placeholder during image loading
/// - Supports const constructor for better widget reuse
///
/// Requirements: 4.1, 6.1, 10.5
class AppAvatar extends StatelessWidget {
  /// The image URL to display.
  final String? imageUrl;

  /// The name to generate initials from (used as fallback).
  final String? name;

  /// Custom initials to display (takes precedence over name).
  final String? initials;

  /// The avatar size.
  final AppAvatarSize size;

  /// Whether to show online status indicator.
  final bool showOnlineIndicator;

  /// Whether the user is online.
  final bool isOnline;

  /// Custom background color for initials avatar.
  final Color? backgroundColor;

  /// Custom text color for initials.
  final Color? textColor;

  /// Callback when avatar is tapped.
  final VoidCallback? onTap;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  /// Custom image widget (takes precedence over imageUrl).
  final Widget? imageWidget;

  /// Creates an avatar with the given parameters.
  /// 
  /// Use const constructor when possible for better performance.
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.initials,
    this.size = AppAvatarSize.medium,
    this.showOnlineIndicator = false,
    this.isOnline = false,
    this.backgroundColor,
    this.textColor,
    this.onTap,
    this.semanticLabel,
    this.imageWidget,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? const DarkAppColors() : const LightAppColors();

    final avatarSize = _getSize();
    final fontSize = _getFontSize();
    final indicatorSize = _getIndicatorSize();

    // Generate initials from name if not provided
    final displayInitials = initials ?? _generateInitials(name);

    // Determine background color
    final effectiveBackgroundColor = backgroundColor ?? 
        _generateColorFromName(name, colors);

    Widget avatar = Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: effectiveBackgroundColor,
      ),
      child: ClipOval(
        child: _buildContent(colors, displayInitials, fontSize, avatarSize),
      ),
    );

    // Add online indicator if needed
    if (showOnlineIndicator) {
      avatar = Stack(
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: indicatorSize,
              height: indicatorSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline ? colors.online : colors.offline,
                border: Border.all(
                  color: colors.surface,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Wrap with GestureDetector if onTap provided
    if (onTap != null) {
      avatar = GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    // Wrap with Semantics for accessibility
    return Semantics(
      image: true,
      label: semanticLabel ?? name ?? 'Avatar',
      child: avatar,
    );
  }

  Widget _buildContent(AppColors colors, String? displayInitials, double fontSize, double avatarSize) {
    // Custom image widget takes precedence
    if (imageWidget != null) {
      return imageWidget!;
    }

    // Try to load image from URL using cached_network_image
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        width: avatarSize,
        height: avatarSize,
        // Use shimmer placeholder for smooth loading experience
        placeholder: (context, url) => _buildShimmerPlaceholder(colors, avatarSize),
        errorWidget: (context, url, error) => 
            _buildInitialsAvatar(colors, displayInitials, fontSize),
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 200),
        // Cache at 2x size for retina displays
        memCacheWidth: (avatarSize * 2).toInt(),
        memCacheHeight: (avatarSize * 2).toInt(),
      );
    }

    // Fall back to initials
    return _buildInitialsAvatar(colors, displayInitials, fontSize);
  }

  Widget _buildInitialsAvatar(AppColors colors, String? displayInitials, double fontSize) {
    return Center(
      child: Text(
        displayInitials ?? '?',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: textColor ?? colors.textOnPrimary,
        ),
      ),
    );
  }

  /// Builds a shimmer placeholder for loading state.
  /// Uses RepaintBoundary to isolate animation repaints.
  Widget _buildShimmerPlaceholder(AppColors colors, double avatarSize) {
    return RepaintBoundary(
      child: Shimmer.fromColors(
        baseColor: colors.shimmerBase,
        highlightColor: colors.shimmerHighlight,
        period: const Duration(milliseconds: 1500),
        child: Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            color: colors.shimmerBase,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  double _getSize() {
    switch (size) {
      case AppAvatarSize.small:
        return AppSpacing.avatarSm;
      case AppAvatarSize.medium:
        return AppSpacing.avatarMd;
      case AppAvatarSize.large:
        return AppSpacing.avatarLg;
      case AppAvatarSize.extraLarge:
        return AppSpacing.avatarXl;
    }
  }

  double _getFontSize() {
    switch (size) {
      case AppAvatarSize.small:
        return 12;
      case AppAvatarSize.medium:
        return 14;
      case AppAvatarSize.large:
        return 20;
      case AppAvatarSize.extraLarge:
        return 28;
    }
  }

  double _getIndicatorSize() {
    switch (size) {
      case AppAvatarSize.small:
        return 10;
      case AppAvatarSize.medium:
        return 12;
      case AppAvatarSize.large:
        return 14;
      case AppAvatarSize.extraLarge:
        return 18;
    }
  }

  String? _generateInitials(String? name) {
    if (name == null || name.isEmpty) return null;

    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return null;

    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length.clamp(0, 2)).toUpperCase();
    }

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Color _generateColorFromName(String? name, AppColors colors) {
    if (name == null || name.isEmpty) {
      return colors.primary;
    }

    // Generate a consistent color based on the name
    final hash = name.hashCode;
    final colorOptions = [
      colors.primary,
      colors.secondary,
      colors.success,
      colors.info,
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFFF97316), // Orange
      const Color(0xFF14B8A6), // Teal
    ];

    return colorOptions[hash.abs() % colorOptions.length];
  }
}
