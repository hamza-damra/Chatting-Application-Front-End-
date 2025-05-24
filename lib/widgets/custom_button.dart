import 'package:flutter/material.dart';
import 'shimmer_widgets.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? color;
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.color,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      height: height,
      child:
          isOutlined
              ? OutlinedButton(
                onPressed: isLoading ? null : onPressed,
                style: OutlinedButton.styleFrom(
                  padding: padding,
                  side: BorderSide(color: color ?? theme.colorScheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                ),
                child: _buildButtonContent(theme),
              )
              : ElevatedButton(
                onPressed: isLoading ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  padding: padding,
                  backgroundColor: color ?? theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                ),
                child: _buildButtonContent(theme),
              ),
    );
  }

  Widget _buildButtonContent(ThemeData theme) {
    return isLoading
        ? ShimmerWidgets.buttonShimmer(
          width: 20,
          height: 20,
          baseColor:
              isOutlined
                  ? theme.colorScheme.primary.withOpacity(0.3)
                  : Colors.white.withOpacity(0.3),
          highlightColor:
              isOutlined
                  ? theme.colorScheme.primary.withOpacity(0.7)
                  : Colors.white.withOpacity(0.7),
        )
        : Text(
          text,
          style: TextStyle(
            color: isOutlined ? theme.colorScheme.primary : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        );
  }
}
