import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final Color? backgroundColor;

  const UserAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 40.0,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return imageUrl != null && imageUrl!.isNotEmpty
        ? CachedNetworkImage(
          imageUrl: imageUrl!,
          imageBuilder:
              (context, imageProvider) => CircleAvatar(
                radius: size / 2,
                backgroundImage: imageProvider,
              ),
          placeholder:
              (context, url) => CircleAvatar(
                radius: size / 2,
                backgroundColor:
                    backgroundColor ?? theme.colorScheme.primary.withAlpha(51),
                child: Center(
                  child: SizedBox(
                    width: size / 3,
                    height: size / 3,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
          errorWidget: (context, url, error) => _buildInitialsAvatar(theme),
        )
        : _buildInitialsAvatar(theme);
  }

  Widget _buildInitialsAvatar(ThemeData theme) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: backgroundColor ?? theme.colorScheme.primary,
      child: Text(
        _getInitials(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size / 3,
        ),
      ),
    );
  }

  String _getInitials() {
    final nameParts = name.split(' ');
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      return name[0].toUpperCase();
    } else {
      return '?';
    }
  }
}
