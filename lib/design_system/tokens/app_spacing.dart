import 'package:flutter/widgets.dart';

/// Spacing constants for the design system.
/// All values are multiples of 4.0 (the base unit).
abstract class AppSpacing {
  // Base spacing values (multiples of 4)
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 48.0;

  // Semantic spacing
  static const double cardPadding = lg;
  static const double listItemPadding = lg;
  static const double sectionSpacing = xxl;
  static const double screenPadding = xl;
  static const double inputPadding = lg;
  static const double buttonPadding = lg;
  static const double iconPadding = sm;

  // Border radius values
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 24.0;
  static const double radiusFull = 999.0;

  // Icon sizes
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;
  static const double iconXl = 32.0;

  // Avatar sizes
  static const double avatarSm = 32.0;
  static const double avatarMd = 40.0;
  static const double avatarLg = 56.0;
  static const double avatarXl = 80.0;

  // Touch target minimum size (accessibility)
  static const double minTouchTarget = 44.0;

  // Responsive breakpoints
  static const double breakpointMobile = 600.0;
  static const double breakpointTablet = 900.0;
  static const double breakpointDesktop = 1200.0;

  // Maximum content widths for different screen sizes
  static const double maxContentWidthMobile = double.infinity;
  static const double maxContentWidthTablet = 600.0;
  static const double maxContentWidthDesktop = 800.0;

  // Responsive horizontal padding values
  static const double paddingMobile = 16.0; // lg
  static const double paddingTablet = 24.0; // xxl
  static const double paddingDesktop = 48.0; // huge

  /// Returns all base spacing values for validation.
  static List<double> get allBaseSpacings => [
        xs,
        sm,
        md,
        lg,
        xl,
        xxl,
        xxxl,
        huge,
      ];

  /// Validates that a spacing value is a multiple of the base unit (4.0).
  static bool isValidSpacing(double value) {
    return value % 4.0 == 0;
  }
}

/// Maximum content width constants for specific screen types.
/// Use these with ResponsiveContainer for consistent max-width constraints.
abstract class ResponsiveMaxWidths {
  /// Maximum width for chat list screens (800px)
  static const double chatList = 800.0;

  /// Maximum width for chat screen message area (800px)
  static const double chatScreen = 800.0;

  /// Maximum width for authentication forms (400px)
  static const double authForm = 400.0;

  /// Maximum width for profile and settings screens (600px)
  static const double profileSettings = 600.0;

  /// Maximum width for user list screens (600px)
  static const double userList = 600.0;

  /// Maximum width for dialogs (400px)
  static const double dialog = 400.0;

  /// Maximum width for create group screen (500px)
  static const double createGroup = 500.0;

  /// Maximum width for media gallery (1200px)
  static const double mediaGallery = 1200.0;

  /// Maximum width for text viewer screens (800px)
  static const double textViewer = 800.0;
}

/// Enum representing device size categories for responsive layouts.
enum DeviceSize {
  /// Mobile devices (width < 600px)
  mobile,
  /// Tablet devices (600px <= width < 900px)
  tablet,
  /// Desktop devices (width >= 900px)
  desktop,
}

/// Utility class for responsive layout calculations.
class ResponsiveLayout {
  /// Returns the current device size category based on screen width.
  static DeviceSize getDeviceSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return getDeviceSizeFromWidth(width);
  }

  /// Returns the device size category from a given width.
  static DeviceSize getDeviceSizeFromWidth(double width) {
    if (width < AppSpacing.breakpointMobile) {
      return DeviceSize.mobile;
    } else if (width < AppSpacing.breakpointTablet) {
      return DeviceSize.tablet;
    } else {
      return DeviceSize.desktop;
    }
  }

  /// Returns true if the current device is mobile.
  static bool isMobile(BuildContext context) {
    return getDeviceSize(context) == DeviceSize.mobile;
  }

  /// Returns true if the current device is tablet.
  static bool isTablet(BuildContext context) {
    return getDeviceSize(context) == DeviceSize.tablet;
  }

  /// Returns true if the current device is desktop.
  static bool isDesktop(BuildContext context) {
    return getDeviceSize(context) == DeviceSize.desktop;
  }

  /// Returns the appropriate horizontal padding based on screen size.
  static double getHorizontalPadding(BuildContext context) {
    final deviceSize = getDeviceSize(context);
    switch (deviceSize) {
      case DeviceSize.mobile:
        return AppSpacing.lg;
      case DeviceSize.tablet:
        return AppSpacing.xxl;
      case DeviceSize.desktop:
        return AppSpacing.huge;
    }
  }

  /// Returns the appropriate screen padding based on screen size.
  static EdgeInsets getScreenPadding(BuildContext context) {
    final horizontal = getHorizontalPadding(context);
    return EdgeInsets.symmetric(
      horizontal: horizontal,
      vertical: AppSpacing.lg,
    );
  }

  /// Returns the maximum content width for the current screen size.
  static double getMaxContentWidth(BuildContext context) {
    final deviceSize = getDeviceSize(context);
    switch (deviceSize) {
      case DeviceSize.mobile:
        return AppSpacing.maxContentWidthMobile;
      case DeviceSize.tablet:
        return AppSpacing.maxContentWidthTablet;
      case DeviceSize.desktop:
        return AppSpacing.maxContentWidthDesktop;
    }
  }

  /// Returns the number of columns for a grid layout based on screen size.
  static int getGridColumns(BuildContext context) {
    final deviceSize = getDeviceSize(context);
    switch (deviceSize) {
      case DeviceSize.mobile:
        return 1;
      case DeviceSize.tablet:
        return 2;
      case DeviceSize.desktop:
        return 3;
    }
  }

  /// Returns a value based on the current device size.
  /// Useful for responsive values that differ across breakpoints.
  static T value<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final deviceSize = getDeviceSize(context);
    switch (deviceSize) {
      case DeviceSize.mobile:
        return mobile;
      case DeviceSize.tablet:
        return tablet ?? mobile;
      case DeviceSize.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  /// Checks if the layout would overflow at the given width.
  /// Returns true if the width is sufficient for the content.
  static bool hasNoHorizontalOverflow(double availableWidth, double contentWidth) {
    return availableWidth >= contentWidth;
  }
}
