import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Collection of reusable shimmer loading widgets for different use cases
class ShimmerWidgets {
  /// Get theme-aware shimmer colors
  static Map<String, Color> _getShimmerColors(
    BuildContext? context, {
    Color? baseColor,
    Color? highlightColor,
  }) {
    if (baseColor != null && highlightColor != null) {
      return {'base': baseColor, 'highlight': highlightColor};
    }

    final isDark =
        context != null
            ? Theme.of(context).brightness == Brightness.dark
            : false;

    if (isDark) {
      return {'base': Colors.grey[800]!, 'highlight': Colors.grey[700]!};
    } else {
      return {'base': Colors.grey[300]!, 'highlight': Colors.grey[100]!};
    }
  }

  /// Get theme-aware container color
  static Color _getContainerColor(BuildContext? context) {
    final isDark =
        context != null
            ? Theme.of(context).brightness == Brightness.dark
            : false;
    return isDark ? Colors.grey[850]! : Colors.white;
  }

  /// Basic circular shimmer for replacing CircularProgressIndicator
  static Widget circularShimmer({
    double size = 40.0,
    Color? baseColor,
    Color? highlightColor,
    BuildContext? context,
  }) {
    final colors = _getShimmerColors(
      context,
      baseColor: baseColor,
      highlightColor: highlightColor,
    );

    return Shimmer.fromColors(
      baseColor: colors['base']!,
      highlightColor: colors['highlight']!,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _getContainerColor(context),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  /// Loading shimmer with text for auth/page loading
  static Widget authLoadingShimmer({
    Color? baseColor,
    Color? highlightColor,
    BuildContext? context,
  }) {
    final colors = _getShimmerColors(
      context,
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
    final containerColor = _getContainerColor(context);

    return Shimmer.fromColors(
      baseColor: colors['base']!,
      highlightColor: colors['highlight']!,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: containerColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 120,
            height: 16,
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  /// Button loading shimmer
  static Widget buttonShimmer({
    double width = 20.0,
    double height = 20.0,
    Color? baseColor,
    Color? highlightColor,
    BuildContext? context,
  }) {
    final colors = _getShimmerColors(
      context,
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
    final containerColor = _getContainerColor(context);

    return Shimmer.fromColors(
      baseColor: colors['base']!,
      highlightColor: colors['highlight']!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: containerColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  /// Image loading shimmer
  static Widget imageShimmer({
    double? width,
    double? height,
    BorderRadius? borderRadius,
    Color? baseColor,
    Color? highlightColor,
    BuildContext? context,
  }) {
    final colors = _getShimmerColors(
      context,
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
    final containerColor = _getContainerColor(context);

    return Shimmer.fromColors(
      baseColor: colors['base']!,
      highlightColor: colors['highlight']!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Chat image loading shimmer
  static Widget chatImageShimmer({
    double width = double.infinity,
    double height = 180,
    bool isCurrentUser = false,
    Color? primaryColor,
    BuildContext? context,
  }) {
    final containerColor = _getContainerColor(context);

    final baseColor =
        isCurrentUser
            ? (primaryColor?.withValues(alpha: 0.3) ??
                Colors.blue.withValues(alpha: 0.3))
            : _getShimmerColors(context)['base']!;
    final highlightColor =
        isCurrentUser
            ? (primaryColor?.withValues(alpha: 0.1) ??
                Colors.blue.withValues(alpha: 0.1))
            : _getShimmerColors(context)['highlight']!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.image,
          size: 40,
          color: containerColor.withValues(alpha: 0.54),
        ),
      ),
    );
  }

  /// List item shimmer for chat/user lists
  static Widget listItemShimmer({
    Color? baseColor,
    Color? highlightColor,
    BuildContext? context,
  }) {
    final colors = _getShimmerColors(
      context,
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
    final containerColor = _getContainerColor(context);
    final isDark =
        context != null
            ? Theme.of(context).brightness == Brightness.dark
            : false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDark
                  ? Colors.grey.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Shimmer.fromColors(
        baseColor: colors['base']!,
        highlightColor: colors['highlight']!,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Professional Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Name
                        Container(
                          width: 140,
                          height: 16,
                          decoration: BoxDecoration(
                            color: containerColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        // Timestamp
                        Container(
                          width: 40,
                          height: 12,
                          decoration: BoxDecoration(
                            color: containerColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Last message
                        Expanded(
                          child: Container(
                            height: 14,
                            decoration: BoxDecoration(
                              color: containerColor,
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Unread badge placeholder
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: containerColor,
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
        ),
      ),
    );
  }

  /// File loading shimmer
  static Widget fileLoadingShimmer({
    Color? baseColor,
    Color? highlightColor,
    BuildContext? context,
  }) {
    final colors = _getShimmerColors(
      context,
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
    final containerColor = _getContainerColor(context);

    return Shimmer.fromColors(
      baseColor: colors['base']!,
      highlightColor: colors['highlight']!,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.description,
              size: 40,
              color: containerColor.withValues(alpha: 0.54),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 150,
            height: 16,
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  /// Media preview shimmer
  static Widget mediaPreviewShimmer({
    Color? baseColor,
    Color? highlightColor,
    BuildContext? context,
  }) {
    final colors = _getShimmerColors(
      context,
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
    final containerColor = _getContainerColor(context);

    return Shimmer.fromColors(
      baseColor: colors['base']!,
      highlightColor: colors['highlight']!,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.play_circle_outline,
              size: 60,
              color: containerColor.withValues(alpha: 0.54),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 200,
            height: 8,
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 100,
            height: 16,
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  /// Full screen image loading shimmer (for image viewer)
  static Widget fullScreenImageShimmer({
    Color? baseColor,
    Color? highlightColor,
    BuildContext? context,
  }) {
    final colors = _getShimmerColors(
      context,
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
    final containerColor = _getContainerColor(context);

    return Container(
      color: Colors.black,
      child: Shimmer.fromColors(
        baseColor: colors['base']!,
        highlightColor: colors['highlight']!,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.image,
                size: 50,
                color: containerColor.withValues(alpha: 0.54),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 120,
              height: 16,
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Profile screen shimmer
  static Widget profileShimmer({
    Color? baseColor,
    Color? highlightColor,
    BuildContext? context,
  }) {
    final colors = _getShimmerColors(
      context,
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
    final containerColor = _getContainerColor(context);

    return Shimmer.fromColors(
      baseColor: colors['base']!,
      highlightColor: colors['highlight']!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Image
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: containerColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 24),

            // User Name
            Container(
              width: 200,
              height: 24,
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 8),

            // User Email
            Container(
              width: 160,
              height: 16,
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 32),

            // Profile Info Cards
            ...List.generate(
              3,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  width: double.infinity,
                  height: 72,
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Edit Profile Button
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Avatar shimmer for UserAvatar component
  static Widget avatarShimmer({
    double size = 40.0,
    Color? baseColor,
    Color? highlightColor,
    BuildContext? context,
  }) {
    final colors = _getShimmerColors(
      context,
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
    final containerColor = _getContainerColor(context);

    return Shimmer.fromColors(
      baseColor: colors['base']!,
      highlightColor: colors['highlight']!,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: containerColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  /// Profile info card shimmer
  static Widget profileInfoCardShimmer({
    Color? baseColor,
    Color? highlightColor,
    BuildContext? context,
  }) {
    final colors = _getShimmerColors(
      context,
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
    final containerColor = _getContainerColor(context);
    final isDark =
        context != null
            ? Theme.of(context).brightness == Brightness.dark
            : false;

    return Shimmer.fromColors(
      baseColor: colors['base']!,
      highlightColor: colors['highlight']!,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color:
                  isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon placeholder
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[600] : Colors.grey[400],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
