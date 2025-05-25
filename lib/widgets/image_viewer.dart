import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import '../utils/url_utils.dart';

import '../core/services/token_service.dart';
import 'authenticated_image_provider.dart';
import 'shimmer_widgets.dart';

class ImageViewer extends StatelessWidget {
  final String imageUrl;
  final String? heroTag;
  final Function()? onClose;
  final bool skipNormalization;

  const ImageViewer({
    super.key,
    required this.imageUrl,
    this.heroTag,
    this.onClose,
    this.skipNormalization = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (onClose != null) {
              onClose!();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: Container(
        constraints: BoxConstraints.expand(
          height: MediaQuery.of(context).size.height,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Hero animation for smooth transition
            heroTag != null
                ? Hero(tag: heroTag!, child: _buildPhotoView())
                : _buildPhotoView(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoView() {
    // Log image URL for debugging
    debugPrint('ImageViewer: Loading image URL in viewer: $imageUrl');

    // Get the URL to display (normalize only if needed)
    final displayUrl =
        skipNormalization ? imageUrl : UrlUtils.normalizeImageUrl(imageUrl);

    if (!skipNormalization) {
      debugPrint('ImageViewer: Normalized URL: $displayUrl');
    }

    return Builder(
      builder: (context) {
        // Get token service for authenticated image loading (optional for backward compatibility)
        TokenService? tokenService;
        try {
          tokenService = Provider.of<TokenService>(context, listen: false);
        } catch (e) {
          debugPrint(
            'ImageViewer: TokenService not available, using basic image provider',
          );
        }

        return PhotoView(
          imageProvider:
              tokenService != null
                  ? AuthenticatedImageProvider(
                    displayUrl,
                    tokenService: tokenService,
                  )
                  : NetworkImage(displayUrl),
          minScale: PhotoViewComputedScale.contained * 0.8,
          maxScale: PhotoViewComputedScale.covered * 3.0,
          initialScale: PhotoViewComputedScale.contained,
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          enableRotation: true,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('ImageViewer: Error loading full image: $error');
            debugPrint(
              'ImageViewer: Failed to load image: $displayUrl, Error: $error',
            );
            return Container(
              color: Colors.black,
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                          size: 64,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Failed to load image',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${_getErrorMessage(error)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Retry loading the image by rebuilding the widget
                            Navigator.of(context).pushReplacement(
                              PageRouteBuilder(
                                opaque: false,
                                pageBuilder: (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                ) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: ImageViewer(
                                      imageUrl: imageUrl,
                                      heroTag: heroTag,
                                      skipNormalization: skipNormalization,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white24,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          loadingBuilder: (context, event) {
            return ShimmerWidgets.fullScreenImageShimmer();
          },
        );
      },
    );
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('404')) {
      return 'Image not found on server';
    } else if (error.toString().contains('403')) {
      return 'Access denied';
    } else if (error.toString().contains('timeout')) {
      return 'Connection timeout';
    } else if (error.toString().contains('network')) {
      return 'Network error';
    } else {
      return error.toString().length > 50
          ? '${error.toString().substring(0, 50)}...'
          : error.toString();
    }
  }
}
