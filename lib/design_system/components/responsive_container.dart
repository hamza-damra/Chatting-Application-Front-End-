import 'package:flutter/material.dart';
import '../tokens/app_spacing.dart';

/// A responsive container that adapts its layout based on screen size.
/// 
/// This widget provides:
/// - Automatic horizontal centering on larger screens
/// - Maximum content width constraints
/// - Responsive padding
/// - Optional scroll behavior
class ResponsiveContainer extends StatelessWidget {
  /// The child widget to display.
  final Widget child;

  /// Whether to center the content horizontally on larger screens.
  final bool centerContent;

  /// Custom maximum width override. If null, uses responsive defaults.
  final double? maxWidth;

  /// Custom padding override. If null, uses responsive defaults.
  final EdgeInsets? padding;

  /// Whether the content should be scrollable.
  final bool scrollable;

  /// Scroll physics for the scrollable container.
  final ScrollPhysics? physics;

  /// Scroll controller for the scrollable container.
  final ScrollController? controller;

  /// Background color for the container.
  final Color? backgroundColor;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.centerContent = true,
    this.maxWidth,
    this.padding,
    this.scrollable = false,
    this.physics,
    this.controller,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxWidth ?? ResponsiveLayout.getMaxContentWidth(context);
    final effectivePadding = padding ?? ResponsiveLayout.getScreenPadding(context);

    Widget content = child;

    // Apply padding
    content = Padding(
      padding: effectivePadding,
      child: content,
    );

    // Apply max width constraint and centering
    if (centerContent && effectiveMaxWidth != double.infinity) {
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
          child: content,
        ),
      );
    }

    // Apply scrolling if needed
    if (scrollable) {
      content = SingleChildScrollView(
        controller: controller,
        physics: physics,
        child: content,
      );
    }

    // Apply background color if specified
    if (backgroundColor != null) {
      content = ColoredBox(
        color: backgroundColor!,
        child: content,
      );
    }

    return content;
  }
}

/// A responsive builder widget that provides device size information.
/// 
/// Use this when you need to build completely different layouts
/// for different screen sizes.
class ResponsiveBuilder extends StatelessWidget {
  /// Builder for mobile layout (width < 600px).
  final Widget Function(BuildContext context) mobile;

  /// Builder for tablet layout (600px <= width < 900px).
  /// Falls back to mobile if not provided.
  final Widget Function(BuildContext context)? tablet;

  /// Builder for desktop layout (width >= 900px).
  /// Falls back to tablet, then mobile if not provided.
  final Widget Function(BuildContext context)? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final deviceSize = ResponsiveLayout.getDeviceSize(context);

    switch (deviceSize) {
      case DeviceSize.mobile:
        return mobile(context);
      case DeviceSize.tablet:
        return (tablet ?? mobile)(context);
      case DeviceSize.desktop:
        return (desktop ?? tablet ?? mobile)(context);
    }
  }
}

/// A widget that shows/hides content based on screen size.
class ResponsiveVisibility extends StatelessWidget {
  /// The child widget to conditionally display.
  final Widget child;

  /// Whether to show on mobile devices.
  final bool visibleOnMobile;

  /// Whether to show on tablet devices.
  final bool visibleOnTablet;

  /// Whether to show on desktop devices.
  final bool visibleOnDesktop;

  /// Widget to show when the child is hidden.
  final Widget? replacement;

  const ResponsiveVisibility({
    super.key,
    required this.child,
    this.visibleOnMobile = true,
    this.visibleOnTablet = true,
    this.visibleOnDesktop = true,
    this.replacement,
  });

  @override
  Widget build(BuildContext context) {
    final deviceSize = ResponsiveLayout.getDeviceSize(context);
    
    bool isVisible;
    switch (deviceSize) {
      case DeviceSize.mobile:
        isVisible = visibleOnMobile;
        break;
      case DeviceSize.tablet:
        isVisible = visibleOnTablet;
        break;
      case DeviceSize.desktop:
        isVisible = visibleOnDesktop;
        break;
    }

    if (isVisible) {
      return child;
    }

    return replacement ?? const SizedBox.shrink();
  }
}

/// A responsive row that wraps to column on smaller screens.
class ResponsiveRowColumn extends StatelessWidget {
  /// The children widgets.
  final List<Widget> children;

  /// Spacing between children.
  final double spacing;

  /// Main axis alignment for row layout.
  final MainAxisAlignment rowMainAxisAlignment;

  /// Cross axis alignment for row layout.
  final CrossAxisAlignment rowCrossAxisAlignment;

  /// Main axis alignment for column layout.
  final MainAxisAlignment columnMainAxisAlignment;

  /// Cross axis alignment for column layout.
  final CrossAxisAlignment columnCrossAxisAlignment;

  /// Whether to use row layout on tablet (default: true).
  final bool rowOnTablet;

  const ResponsiveRowColumn({
    super.key,
    required this.children,
    this.spacing = AppSpacing.lg,
    this.rowMainAxisAlignment = MainAxisAlignment.start,
    this.rowCrossAxisAlignment = CrossAxisAlignment.center,
    this.columnMainAxisAlignment = MainAxisAlignment.start,
    this.columnCrossAxisAlignment = CrossAxisAlignment.stretch,
    this.rowOnTablet = true,
  });

  @override
  Widget build(BuildContext context) {
    final deviceSize = ResponsiveLayout.getDeviceSize(context);
    final useRow = deviceSize == DeviceSize.desktop || 
                   (deviceSize == DeviceSize.tablet && rowOnTablet);

    if (useRow) {
      return Row(
        mainAxisAlignment: rowMainAxisAlignment,
        crossAxisAlignment: rowCrossAxisAlignment,
        children: _addSpacing(children, spacing, isRow: true),
      );
    }

    return Column(
      mainAxisAlignment: columnMainAxisAlignment,
      crossAxisAlignment: columnCrossAxisAlignment,
      children: _addSpacing(children, spacing, isRow: false),
    );
  }

  List<Widget> _addSpacing(List<Widget> widgets, double spacing, {required bool isRow}) {
    if (widgets.isEmpty) return widgets;

    final result = <Widget>[];
    for (int i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i < widgets.length - 1) {
        result.add(isRow ? SizedBox(width: spacing) : SizedBox(height: spacing));
      }
    }
    return result;
  }
}
