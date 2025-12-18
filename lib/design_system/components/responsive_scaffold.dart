import 'package:flutter/material.dart';
import 'responsive_container.dart';

/// A scaffold wrapper that automatically applies ResponsiveContainer to the body.
///
/// This widget simplifies creating responsive screens by:
/// - Automatically wrapping the body with ResponsiveContainer
/// - Providing consistent max-width constraints on larger screens
/// - Centering content on tablet and desktop
/// - Supporting all standard Scaffold properties
///
/// Example usage:
/// ```dart
/// ResponsiveScaffold(
///   appBar: AppBar(title: Text('My Screen')),
///   body: MyContent(),
///   maxContentWidth: ResponsiveMaxWidths.profileSettings,
/// )
/// ```
class ResponsiveScaffold extends StatelessWidget {
  /// The app bar to display at the top of the scaffold.
  final PreferredSizeWidget? appBar;

  /// The primary content of the scaffold.
  /// This will be wrapped with ResponsiveContainer.
  final Widget body;

  /// The floating action button to display.
  final Widget? floatingActionButton;

  /// The location of the floating action button.
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// The animation for the floating action button.
  final FloatingActionButtonAnimator? floatingActionButtonAnimator;

  /// The bottom navigation bar to display.
  final Widget? bottomNavigationBar;

  /// The bottom sheet to display.
  final Widget? bottomSheet;

  /// The drawer to display.
  final Widget? drawer;

  /// The end drawer to display.
  final Widget? endDrawer;

  /// The background color of the scaffold.
  final Color? backgroundColor;

  /// Whether to resize the body to avoid the bottom inset (keyboard).
  final bool? resizeToAvoidBottomInset;

  /// Custom maximum content width override.
  /// If null, uses ResponsiveLayout.getMaxContentWidth().
  final double? maxContentWidth;

  /// Whether to center content on desktop/tablet screens.
  /// Defaults to true.
  final bool centerOnDesktop;

  /// Custom padding for the body content.
  /// If null, uses ResponsiveLayout.getScreenPadding().
  final EdgeInsets? bodyPadding;

  /// Whether the body content should be scrollable.
  /// Defaults to false.
  final bool scrollableBody;

  /// Scroll controller for the scrollable body.
  final ScrollController? scrollController;

  /// Scroll physics for the scrollable body.
  final ScrollPhysics? scrollPhysics;

  /// Whether to extend the body behind the app bar.
  final bool extendBodyBehindAppBar;

  /// Whether to extend the body behind the bottom navigation bar.
  final bool extendBody;

  /// The persistent footer buttons.
  final List<Widget>? persistentFooterButtons;

  /// Alignment of persistent footer buttons.
  final AlignmentDirectional persistentFooterAlignment;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.floatingActionButtonAnimator,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.maxContentWidth,
    this.centerOnDesktop = true,
    this.bodyPadding,
    this.scrollableBody = false,
    this.scrollController,
    this.scrollPhysics,
    this.extendBodyBehindAppBar = false,
    this.extendBody = false,
    this.persistentFooterButtons,
    this.persistentFooterAlignment = AlignmentDirectional.centerEnd,
  });

  @override
  Widget build(BuildContext context) {
    // Wrap body with ResponsiveContainer
    Widget responsiveBody = ResponsiveContainer(
      maxWidth: maxContentWidth,
      centerContent: centerOnDesktop,
      padding: bodyPadding,
      scrollable: scrollableBody,
      controller: scrollController,
      physics: scrollPhysics,
      child: body,
    );

    return Scaffold(
      appBar: appBar,
      body: responsiveBody,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      floatingActionButtonAnimator: floatingActionButtonAnimator,
      bottomNavigationBar: bottomNavigationBar,
      bottomSheet: bottomSheet,
      drawer: drawer,
      endDrawer: endDrawer,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      extendBody: extendBody,
      persistentFooterButtons: persistentFooterButtons,
      persistentFooterAlignment: persistentFooterAlignment,
    );
  }
}
