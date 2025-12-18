import 'package:flutter/material.dart';

/// A mixin that provides state preservation capabilities for orientation changes.
/// 
/// This mixin helps preserve scroll positions, input state, and other UI state
/// when the device orientation changes, ensuring a smooth user experience.
/// 
/// Usage:
/// ```dart
/// class _MyScreenState extends State<MyScreen> 
///     with AutomaticKeepAliveClientMixin, OrientationStateMixin {
///   @override
///   bool get wantKeepAlive => true;
///   
///   @override
///   Widget build(BuildContext context) {
///     super.build(context); // Required for AutomaticKeepAliveClientMixin
///     return ...;
///   }
/// }
/// ```
mixin OrientationStateMixin<T extends StatefulWidget> on State<T> {
  /// Stores scroll positions by controller key
  final Map<String, double> _scrollPositions = {};
  
  /// Stores text field values by controller key
  final Map<String, String> _textFieldValues = {};
  
  /// The previous orientation, used to detect orientation changes
  Orientation? _previousOrientation;
  
  /// Whether an orientation change is currently in progress
  bool _isOrientationChanging = false;
  
  /// Callback that can be overridden to perform actions before orientation change
  @protected
  void onBeforeOrientationChange(Orientation oldOrientation, Orientation newOrientation) {}
  
  /// Callback that can be overridden to perform actions after orientation change
  @protected
  void onAfterOrientationChange(Orientation oldOrientation, Orientation newOrientation) {}
  
  /// Saves the current scroll position for a given controller
  void saveScrollPosition(String key, ScrollController controller) {
    if (controller.hasClients) {
      _scrollPositions[key] = controller.offset;
    }
  }
  
  /// Restores the scroll position for a given controller
  void restoreScrollPosition(String key, ScrollController controller) {
    final savedPosition = _scrollPositions[key];
    if (savedPosition != null && controller.hasClients) {
      // Use post-frame callback to ensure the scroll view is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (controller.hasClients && mounted) {
          final maxScroll = controller.position.maxScrollExtent;
          final targetPosition = savedPosition.clamp(0.0, maxScroll);
          controller.jumpTo(targetPosition);
        }
      });
    }
  }
  
  /// Saves a text field value
  void saveTextFieldValue(String key, TextEditingController controller) {
    _textFieldValues[key] = controller.text;
  }
  
  /// Restores a text field value
  void restoreTextFieldValue(String key, TextEditingController controller) {
    final savedValue = _textFieldValues[key];
    if (savedValue != null && controller.text != savedValue) {
      controller.text = savedValue;
    }
  }
  
  /// Clears all saved state
  void clearSavedState() {
    _scrollPositions.clear();
    _textFieldValues.clear();
  }
  
  /// Checks for orientation changes and triggers callbacks
  /// Call this in build() method before returning the widget
  void checkOrientationChange(BuildContext context) {
    final currentOrientation = MediaQuery.of(context).orientation;
    
    if (_previousOrientation != null && _previousOrientation != currentOrientation) {
      _isOrientationChanging = true;
      onBeforeOrientationChange(_previousOrientation!, currentOrientation);
      
      // Schedule the after callback for the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          onAfterOrientationChange(_previousOrientation!, currentOrientation);
          _isOrientationChanging = false;
        }
      });
    }
    
    _previousOrientation = currentOrientation;
  }
  
  /// Returns true if an orientation change is currently in progress
  bool get isOrientationChanging => _isOrientationChanging;
  
  /// Gets the current orientation
  Orientation? get currentOrientation => _previousOrientation;
}

/// A helper class for managing scroll position restoration
class ScrollPositionRestorer {
  final ScrollController controller;
  final String key;
  double? _savedPosition;
  
  ScrollPositionRestorer({
    required this.controller,
    required this.key,
  });
  
  /// Saves the current scroll position
  void save() {
    if (controller.hasClients) {
      _savedPosition = controller.offset;
    }
  }
  
  /// Restores the saved scroll position
  void restore() {
    if (_savedPosition != null && controller.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (controller.hasClients) {
          final maxScroll = controller.position.maxScrollExtent;
          final targetPosition = _savedPosition!.clamp(0.0, maxScroll);
          controller.jumpTo(targetPosition);
        }
      });
    }
  }
  
  /// Clears the saved position
  void clear() {
    _savedPosition = null;
  }
}

/// A widget that preserves its child's state across orientation changes
/// by using AutomaticKeepAlive
class OrientationPreserver extends StatefulWidget {
  final Widget child;
  
  const OrientationPreserver({
    super.key,
    required this.child,
  });
  
  @override
  State<OrientationPreserver> createState() => _OrientationPreserverState();
}

class _OrientationPreserverState extends State<OrientationPreserver>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
