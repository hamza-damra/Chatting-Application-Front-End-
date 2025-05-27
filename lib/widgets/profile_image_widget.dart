import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../core/services/token_service.dart';
import '../providers/api_auth_provider.dart';
import '../utils/logger.dart';

/// A modern profile image widget that uses the new direct GET endpoints
/// for displaying user profile images with proper authentication and fallbacks
class ProfileImageWidget extends StatelessWidget {
  final int? userId;
  final double size;
  final String? fallbackAsset;
  final String? userName;
  final Color? backgroundColor;
  final Color? textColor;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;

  const ProfileImageWidget({
    super.key,
    this.userId,
    this.size = 50.0,
    this.fallbackAsset,
    this.userName,
    this.backgroundColor,
    this.textColor,
    this.showBorder = true,
    this.borderColor,
    this.borderWidth = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokenService = Provider.of<TokenService>(context, listen: false);
    final authProvider = Provider.of<ApiAuthProvider>(context, listen: false);

    // Determine if this is the current user
    final currentUserId = authProvider.user?.id;
    final isCurrentUser =
        userId != null && currentUserId != null && userId == currentUserId;

    // Generate the appropriate image URL - use /me endpoint for current user
    final imageUrl =
        userId == null || isCurrentUser
            ? ApiConfig.getCurrentUserProfileImageUrl()
            : ApiConfig.getUserProfileImageUrl(userId!);

    // Debug logging
    AppLogger.d('ProfileImageWidget', 'Requesting profile image:');
    AppLogger.d('ProfileImageWidget', '  userId: $userId');
    AppLogger.d('ProfileImageWidget', '  currentUserId: $currentUserId');
    AppLogger.d('ProfileImageWidget', '  isCurrentUser: $isCurrentUser');
    AppLogger.d('ProfileImageWidget', '  imageUrl: $imageUrl');

    // Get auth headers
    final authHeaders =
        tokenService.accessToken != null
            ? ApiConfig.getAuthHeaders(tokenService.accessToken!)
            : <String, String>{};

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border:
            showBorder
                ? Border.all(
                  color:
                      borderColor ??
                      theme.colorScheme.outline.withValues(alpha: 0.3),
                  width: borderWidth,
                )
                : null,
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          httpHeaders: authHeaders,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildLoadingWidget(theme),
          errorWidget: (context, url, error) {
            // Enhanced error logging
            if (error.toString().contains('404')) {
              AppLogger.i(
                'ProfileImageWidget',
                'Profile image not found (404) for userId: $userId - user may not have uploaded a profile image yet',
              );
            } else {
              AppLogger.w(
                'ProfileImageWidget',
                'Error loading profile image for userId: $userId - $error',
              );
            }
            return _buildFallbackWidget(theme);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(ThemeData theme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? theme.colorScheme.primaryContainer,
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.4,
          height: size * 0.4,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              textColor ?? theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackWidget(ThemeData theme) {
    // Try to use fallback asset first
    if (fallbackAsset != null) {
      return Image.asset(
        fallbackAsset!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildInitialsWidget(theme);
        },
      );
    }

    // Fall back to initials widget
    return _buildInitialsWidget(theme);
  }

  Widget _buildInitialsWidget(ThemeData theme) {
    final initials = _getInitials();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? theme.colorScheme.primaryContainer,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: textColor ?? theme.colorScheme.onPrimaryContainer,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getInitials() {
    if (userName != null && userName!.isNotEmpty) {
      final words = userName!.trim().split(' ');
      if (words.length >= 2) {
        return '${words[0][0]}${words[1][0]}'.toUpperCase();
      } else if (words.isNotEmpty) {
        return words[0][0].toUpperCase();
      }
    }
    return '?';
  }
}

/// A specialized profile image widget for chat contexts
class ChatProfileImageWidget extends StatelessWidget {
  final int userId;
  final String userName;
  final double size;
  final bool isOnline;

  const ChatProfileImageWidget({
    super.key,
    required this.userId,
    required this.userName,
    this.size = 40.0,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        ProfileImageWidget(
          userId: userId,
          userName: userName,
          size: size,
          backgroundColor: theme.colorScheme.primary,
          textColor: theme.colorScheme.onPrimary,
        ),
        if (isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.surface, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

/// A profile image widget with edit functionality
class EditableProfileImageWidget extends StatelessWidget {
  final int? userId;
  final String? userName;
  final double size;
  final VoidCallback? onTap;
  final bool showEditIcon;

  const EditableProfileImageWidget({
    super.key,
    this.userId,
    this.userName,
    this.size = 120.0,
    this.onTap,
    this.showEditIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          child: ProfileImageWidget(
            userId: userId,
            userName: userName,
            size: size,
            backgroundColor: theme.colorScheme.primary,
            textColor: theme.colorScheme.onPrimary,
            borderWidth: 2,
          ),
        ),
        if (showEditIcon && onTap != null)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: size * 0.25,
                height: size * 0.25,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: theme.colorScheme.onPrimary,
                  size: size * 0.12,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
