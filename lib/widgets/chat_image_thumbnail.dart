import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../utils/url_utils.dart';
import '../core/services/token_service.dart';
import 'image_viewer.dart';
import 'authenticated_image_provider.dart';

/// A thumbnail image widget that displays chat images and opens the full viewer when tapped
class ChatImageThumbnail extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String heroTag;
  final bool isCurrentUser;

  const ChatImageThumbnail({
    super.key,
    required this.imageUrl,
    this.width,
    this.height = 150,
    this.fit = BoxFit.cover,
    required this.heroTag,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    // Log image URL for debugging
    debugPrint('ChatImageThumbnail: Loading image URL: $imageUrl');

    // Normalize the image URL using UrlUtils
    final normalizedUrl = UrlUtils.normalizeImageUrl(imageUrl);
    debugPrint('ChatImageThumbnail: Normalized URL: $normalizedUrl');

    // Get token service for authenticated image loading (optional for backward compatibility)
    TokenService? tokenService;
    try {
      tokenService = Provider.of<TokenService>(context, listen: false);
    } catch (e) {
      debugPrint(
        'ChatImageThumbnail: TokenService not available, falling back to CachedNetworkImage',
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (context, animation, secondaryAnimation) {
              return FadeTransition(
                opacity: animation,
                // Pass the already normalized URL to avoid double normalization
                child: ImageViewer(
                  imageUrl: normalizedUrl,
                  heroTag: heroTag,
                  skipNormalization:
                      true, // Skip normalization since we already did it
                ),
              );
            },
          ),
        );
      },
      child: Hero(
        tag: heroTag,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                tokenService != null
                    ? AuthenticatedImage(
                      imageUrl: normalizedUrl,
                      tokenService: tokenService,
                      width: width,
                      height: height,
                      fit: fit,
                      placeholder: _buildModernLoadingPlaceholder(),
                      errorWidget: Container(
                        color: Colors.grey[300],
                        width: width,
                        height: height,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.broken_image,
                                color: Colors.grey[600],
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Text(
                                  'Image not available',
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              if (imageUrl.length > 20)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'URL: ${imageUrl.substring(0, 20)}...',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    )
                    : CachedNetworkImage(
                      imageUrl: normalizedUrl,
                      fit: fit,
                      width: width,
                      height: height,
                      placeholder:
                          (context, url) => _buildModernLoadingPlaceholder(),
                      errorWidget:
                          (context, url, error) => Container(
                            color: Colors.grey[300],
                            width: width,
                            height: height,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    color: Colors.grey[600],
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      'Image not available',
                                      style: TextStyle(
                                        color: Colors.grey[800],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  if (imageUrl.length > 20)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'URL: ${imageUrl.substring(0, 20)}...',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 10,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                    ),
          ),
        ),
      ),
    );
  }

  // Build modern loading placeholder with shimmer effect
  Widget _buildModernLoadingPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shimmer effect
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1500),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey[300]!,
                      Colors.grey[200]!,
                      Colors.grey[100]!,
                      Colors.grey[200]!,
                      Colors.grey[300]!,
                    ],
                    stops: [
                      0.0,
                      0.25 + value * 0.25,
                      0.5 + value * 0.25,
                      0.75 + value * 0.25,
                      1.0,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            },
          ),

          // Image icon
          Icon(Icons.image, size: 48, color: Colors.grey[500]),

          // Loading indicator
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(128),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCurrentUser ? Colors.white : Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
