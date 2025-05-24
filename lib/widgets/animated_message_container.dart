import 'package:flutter/material.dart';

/// A container that animates when a new message appears
/// This provides a subtle animation effect for new messages
class AnimatedMessageContainer extends StatefulWidget {
  final Widget child;
  final bool isNewMessage;
  final Alignment alignment;
  final BoxDecoration decoration;

  const AnimatedMessageContainer({
    super.key,
    required this.child,
    required this.isNewMessage,
    required this.alignment,
    required this.decoration,
  });

  @override
  State<AnimatedMessageContainer> createState() =>
      _AnimatedMessageContainerState();
}

class _AnimatedMessageContainerState extends State<AnimatedMessageContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Create a more pronounced scale animation
    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    // Create a fade-in animation
    _opacityAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Create a slide animation based on alignment
    final slideBegin = widget.alignment == Alignment.centerRight ? 20.0 : -20.0;
    _slideAnimation = Tween<double>(
      begin: slideBegin,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Start the animation if this is a new message
    if (widget.isNewMessage) {
      // Small delay for a more natural feel
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          _controller.forward();
        }
      });
    } else {
      // Set to completed state for existing messages
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedMessageContainer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the message becomes "new" (e.g., when sending), animate it
    if (widget.isNewMessage && !oldWidget.isNewMessage) {
      // Reset and play the animation
      _controller.reset();

      // Small delay for a more natural feel
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.translate(
            offset: Offset(_slideAnimation.value, 0),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              alignment:
                  widget.alignment == Alignment.centerRight
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
              child: Container(
                decoration: widget.decoration,
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}
