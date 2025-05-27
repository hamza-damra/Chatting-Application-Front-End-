import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  final String userName;
  final String userId;

  const TypingIndicator({super.key, required this.userName, this.userId = ''});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _animations = List.generate(
      3,
      (index) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.2,
            0.6 + index * 0.2,
            curve: Curves.easeInOut,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Theme-aware colors for modern design
    final backgroundColor =
        isDark
            ? const Color(0xFF2D2D2D) // More visible background in dark mode
            : theme.colorScheme.surfaceContainerLowest;

    final textColor = theme.colorScheme.onSurfaceVariant;
    final dotColor = theme.colorScheme.primary.withAlpha(179); // 70% opacity

    return Tooltip(
      message:
          widget.userId.isNotEmpty
              ? 'User ID: ${widget.userId}'
              : 'Unknown user',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isDark
                    ? const Color(
                      0xFF404040,
                    ) // More visible border in dark mode
                    : theme.colorScheme.outline.withAlpha(
                      77,
                    ), // 30% opacity in light mode
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isDark
                      ? Colors.black.withAlpha(51) // 20% opacity for dark mode
                      : Colors.black.withAlpha(
                        26,
                      ), // 10% opacity for light mode
              blurRadius: isDark ? 6 : 4,
              offset: const Offset(0, 1),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.userName} is typing',
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(width: 12),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Row(
                  children: List.generate(
                    3,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Transform.translate(
                        offset: Offset(0, -4 * _animations[index].value),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
