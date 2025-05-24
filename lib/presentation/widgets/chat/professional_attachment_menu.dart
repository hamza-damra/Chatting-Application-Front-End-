import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Professional attachment menu widget with modern design matching the input field
class ProfessionalAttachmentMenu extends StatefulWidget {
  final VoidCallback? onPhotoPressed;
  final VoidCallback? onCameraPressed;
  final VoidCallback? onVideoPressed;
  final VoidCallback? onFilePressed;
  final bool isEnabled;
  final bool isUploading;

  const ProfessionalAttachmentMenu({
    super.key,
    this.onPhotoPressed,
    this.onCameraPressed,
    this.onVideoPressed,
    this.onFilePressed,
    this.isEnabled = true,
    this.isUploading = false,
  });

  @override
  State<ProfessionalAttachmentMenu> createState() =>
      _ProfessionalAttachmentMenuState();
}

class _ProfessionalAttachmentMenuState extends State<ProfessionalAttachmentMenu>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(
                  isDark ? 77 : 38,
                ), // 0.3 : 0.15 opacity
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
            border: Border.all(
              color: theme.colorScheme.outline.withAlpha(51), // 0.2 opacity
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAttachmentOption(
                context: context,
                icon: Icons.photo_library_rounded,
                label: 'Photo',
                color: const Color(0xFF4CAF50), // Green
                onPressed: widget.onPhotoPressed,
              ),
              _buildAttachmentOption(
                context: context,
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                color: const Color(0xFF2196F3), // Blue
                onPressed: widget.onCameraPressed,
              ),
              _buildAttachmentOption(
                context: context,
                icon: Icons.videocam_rounded,
                label: 'Video',
                color: const Color(0xFFFF5722), // Deep Orange
                onPressed: widget.onVideoPressed,
              ),
              _buildAttachmentOption(
                context: context,
                icon: Icons.insert_drive_file_rounded,
                label: 'File',
                color: const Color(0xFF9C27B0), // Purple
                onPressed: widget.onFilePressed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    final theme = Theme.of(context);
    final isEnabled =
        widget.isEnabled && onPressed != null && !widget.isUploading;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap:
                isEnabled
                    ? () {
                      HapticFeedback.lightImpact();
                      onPressed();
                    }
                    : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color:
                          isEnabled
                              ? color
                              : color.withAlpha(
                                102,
                              ), // 40% opacity when disabled
                      borderRadius: BorderRadius.circular(16),
                      boxShadow:
                          isEnabled
                              ? [
                                BoxShadow(
                                  color: color.withAlpha(77), // 30% opacity
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                              : null,
                    ),
                    child:
                        widget.isUploading
                            ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isUploading ? 'Uploading...' : label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          isEnabled
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
