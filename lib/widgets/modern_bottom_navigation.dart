import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ModernBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<ModernBottomNavItem> items;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double? elevation;

  const ModernBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.elevation,
  });

  @override
  State<ModernBottomNavigation> createState() => _ModernBottomNavigationState();
}

class _ModernBottomNavigationState extends State<ModernBottomNavigation>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ModernBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomNavTheme = theme.bottomNavigationBarTheme;

    final backgroundColor =
        widget.backgroundColor ??
        bottomNavTheme.backgroundColor ??
        theme.colorScheme.surface;

    final selectedColor =
        widget.selectedItemColor ??
        bottomNavTheme.selectedItemColor ??
        theme.colorScheme.primary;

    final unselectedColor =
        widget.unselectedItemColor ??
        bottomNavTheme.unselectedItemColor ??
        theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Material(
      elevation: widget.elevation ?? 12,
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [backgroundColor.withValues(alpha: 0.95), backgroundColor],
          ),
          border: Border(
            top: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Container(
            height: 65,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children:
                  widget.items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isSelected = index == widget.currentIndex;

                    return Expanded(
                      child: _ModernBottomNavItem(
                        item: item,
                        isSelected: isSelected,
                        selectedColor: selectedColor,
                        unselectedColor: unselectedColor,
                        animation: _animation,
                        onTap: () => widget.onTap(index),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernBottomNavItem extends StatelessWidget {
  final ModernBottomNavItem item;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final Animation<double> animation;
  final VoidCallback onTap;

  const _ModernBottomNavItem({
    required this.item,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.animation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: selectedColor.withValues(alpha: 0.1),
        highlightColor: selectedColor.withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with indicator
              Stack(
                alignment: Alignment.center,
                children: [
                  // Background indicator for selected item
                  if (isSelected)
                    AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: animation.value,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: selectedColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        );
                      },
                    ),
                  // Icon
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(6),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isSelected ? item.activeIcon ?? item.icon : item.icon,
                        key: ValueKey(isSelected),
                        color: isSelected ? selectedColor : unselectedColor,
                        size: isSelected ? 24 : 22,
                      ),
                    ),
                  ),
                  // Badge if present
                  if (item.badge != null)
                    Positioned(right: 2, top: 2, child: item.badge!),
                ],
              ),
              const SizedBox(height: 1),
              // Label
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.poppins(
                  fontSize: isSelected ? 11 : 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? selectedColor : unselectedColor,
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ModernBottomNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final Widget? badge;

  const ModernBottomNavItem({
    required this.icon,
    required this.label,
    this.activeIcon,
    this.badge,
  });
}

// Badge widget for notifications
class NotificationBadge extends StatelessWidget {
  final int count;
  final Color? backgroundColor;
  final Color? textColor;

  const NotificationBadge({
    super.key,
    required this.count,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (count <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.error,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.surface, width: 1.5),
      ),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor ?? Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
