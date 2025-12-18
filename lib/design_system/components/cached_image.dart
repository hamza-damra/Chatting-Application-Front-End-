import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../tokens/app_colors.dart';

/// A cached network image component with shimmer placeholder.
/// 
/// Uses cached_network_image for efficient image caching and
/// displays a shimmer animation while loading.
/// 
/// Requirements: 10.5
class CachedImage extends StatelessWidget {
  /// The URL of the image to load.
  final String? imageUrl;

  /// Width of the image container.
  final double? width;

  /// Height of the image container.
  final double? height;

  /// How the image should be inscribed into the box.
  final BoxFit fit;

  /// Border radius for the image.
  final BorderRadius? borderRadius;

  /// Placeholder widget to show while loading (defaults to shimmer).
  final Widget? placeholder;

  /// Error widget to show when image fails to load.
  final Widget? errorWidget;

  /// Whether to use a circular shape.
  final bool isCircular;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  /// Creates a cached image with shimmer placeholder.
  /// 
  /// Use const constructor when possible for better performance.
  const CachedImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.isCircular = false,
    this.semanticLabel,
  });

  /// Creates a circular cached image (for avatars).
  const CachedImage.circular({
    super.key,
    this.imageUrl,
    required double size,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.semanticLabel,
  })  : width = size,
        height = size,
        isCircular = true,
        borderRadius = null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? const DarkAppColors() : const LightAppColors();

    // If no URL provided, show error widget
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildContainer(
        colors: colors,
        child: errorWidget ?? _buildDefaultErrorWidget(colors),
      );
    }

    return Semantics(
      image: true,
      label: semanticLabel ?? 'Image',
      child: _buildContainer(
        colors: colors,
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: width,
          height: height,
          fit: fit,
          placeholder: (context, url) => placeholder ?? _buildShimmerPlaceholder(colors),
          errorWidget: (context, url, error) => errorWidget ?? _buildDefaultErrorWidget(colors),
          fadeInDuration: const Duration(milliseconds: 200),
          fadeOutDuration: const Duration(milliseconds: 200),
          memCacheWidth: width != null ? (width! * 2).toInt() : null,
          memCacheHeight: height != null ? (height! * 2).toInt() : null,
        ),
      ),
    );
  }

  Widget _buildContainer({
    required AppColors colors,
    required Widget child,
  }) {
    if (isCircular) {
      return ClipOval(
        child: SizedBox(
          width: width,
          height: height,
          child: child,
        ),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: SizedBox(
          width: width,
          height: height,
          child: child,
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: child,
    );
  }

  Widget _buildShimmerPlaceholder(AppColors colors) {
    return Shimmer.fromColors(
      baseColor: colors.shimmerBase,
      highlightColor: colors.shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        color: colors.shimmerBase,
      ),
    );
  }

  Widget _buildDefaultErrorWidget(AppColors colors) {
    return Container(
      width: width,
      height: height,
      color: colors.surfaceElevated,
      child: Icon(
        Icons.broken_image_outlined,
        color: colors.textTertiary,
        size: _getErrorIconSize(),
      ),
    );
  }

  double _getErrorIconSize() {
    if (width != null && height != null) {
      final minDimension = width! < height! ? width! : height!;
      return (minDimension * 0.4).clamp(16.0, 48.0);
    }
    return 24.0;
  }
}

/// A cached avatar image with shimmer placeholder.
/// 
/// Optimized for avatar use cases with circular shape and
/// initials fallback support.
class CachedAvatarImage extends StatelessWidget {
  /// The URL of the avatar image.
  final String? imageUrl;

  /// Size of the avatar.
  final double size;

  /// Name to generate initials from (used as fallback).
  final String? name;

  /// Custom initials to display (takes precedence over name).
  final String? initials;

  /// Background color for initials fallback.
  final Color? backgroundColor;

  /// Text color for initials.
  final Color? textColor;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  /// Creates a cached avatar image.
  const CachedAvatarImage({
    super.key,
    this.imageUrl,
    required this.size,
    this.name,
    this.initials,
    this.backgroundColor,
    this.textColor,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? const DarkAppColors() : const LightAppColors();

    // Generate initials from name if not provided
    final displayInitials = initials ?? _generateInitials(name);
    final effectiveBackgroundColor = backgroundColor ?? 
        _generateColorFromName(name, colors);

    // If no URL provided, show initials
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildInitialsAvatar(colors, displayInitials, effectiveBackgroundColor);
    }

    return Semantics(
      image: true,
      label: semanticLabel ?? name ?? 'Avatar',
      child: ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: CachedNetworkImage(
            imageUrl: imageUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder: (context, url) => _buildShimmerPlaceholder(colors),
            errorWidget: (context, url, error) => 
                _buildInitialsAvatar(colors, displayInitials, effectiveBackgroundColor),
            fadeInDuration: const Duration(milliseconds: 200),
            fadeOutDuration: const Duration(milliseconds: 200),
            memCacheWidth: (size * 2).toInt(),
            memCacheHeight: (size * 2).toInt(),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerPlaceholder(AppColors colors) {
    return Shimmer.fromColors(
      baseColor: colors.shimmerBase,
      highlightColor: colors.shimmerHighlight,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.shimmerBase,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(AppColors colors, String? displayInitials, Color bgColor) {
    final fontSize = size * 0.4;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          displayInitials ?? '?',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: textColor ?? colors.textOnPrimary,
          ),
        ),
      ),
    );
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
