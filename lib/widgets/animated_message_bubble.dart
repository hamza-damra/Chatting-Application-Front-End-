import 'package:flutter/material.dart';

/// A new animated message bubble with modern design and smooth animations
class AnimatedMessageBubble extends StatefulWidget {
  final Widget child;
  final bool isNewMessage;
  final bool isCurrentUser;
  final BoxDecoration decoration;

  const AnimatedMessageBubble({
    super.key,
    required this.child,
    required this.isNewMessage,
    required this.isCurrentUser,
    required this.decoration,
  });

  @override
  State<AnimatedMessageBubble> createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<AnimatedMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _slideAnimation = Tween<Offset>(
      begin:
          widget.isCurrentUser ? const Offset(0.3, 0) : const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    if (widget.isNewMessage) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _controller.forward();
        }
      });
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isNewMessage != oldWidget.isNewMessage ||
        widget.isCurrentUser != oldWidget.isCurrentUser) {
      _controller.reset();

      _slideAnimation = Tween<Offset>(
        begin:
            widget.isCurrentUser ? const Offset(0.3, 0) : const Offset(-0.3, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
      );

      if (widget.isNewMessage) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _controller.forward();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alignment =
        widget.isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          alignment: alignment,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: widget.decoration,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
