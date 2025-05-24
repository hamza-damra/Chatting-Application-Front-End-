import 'dart:async';
import 'package:flutter/material.dart';

/// Enhanced controller for managing chat messages scrolling behavior with smooth animations
class ChatMessagesController {
  final ScrollController scrollController = ScrollController();
  String? _latestMessageId;
  bool _isUserScrolling = false;
  bool _isNearBottom = true;
  bool _hasUnreadMessages = false;

  // Scroll thresholds and animation parameters
  static const double _bottomThreshold =
      150.0; // Distance from bottom to consider "near bottom"
  static const double _scrollDistanceThreshold =
      500.0; // Distance threshold for adaptive animation duration

  // Stream controller for notifying about unread messages
  final _unreadMessagesController = StreamController<bool>.broadcast();
  Stream<bool> get unreadMessagesStream => _unreadMessagesController.stream;

  // Timer for debouncing scroll events
  Timer? _scrollDebounceTimer;

  void initialize() {
    // Add scroll listener to detect when user is near bottom
    scrollController.addListener(_scrollListener);
  }

  void dispose() {
    _scrollDebounceTimer?.cancel();
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    _unreadMessagesController.close();
  }

  /// Listener to detect when user is near the bottom of the chat
  void _scrollListener() {
    if (!scrollController.hasClients) return;

    final position = scrollController.position;

    // Check if we're near the bottom
    final wasNearBottom = _isNearBottom;
    _isNearBottom =
        position.maxScrollExtent - position.pixels <= _bottomThreshold;

    // If we just scrolled to the bottom and had unread messages, clear them
    if (_isNearBottom && !wasNearBottom && _hasUnreadMessages) {
      _hasUnreadMessages = false;
      _unreadMessagesController.add(false);
    }

    // Debounce rapid scroll events
    _scrollDebounceTimer?.cancel();
    _scrollDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      // Additional logic can be added here if needed
    });
  }

  /// Jump to bottom instantly without animation
  void jumpToBottom() {
    if (!scrollController.hasClients) return;

    scrollController.jumpTo(scrollController.position.maxScrollExtent);

    // Clear unread messages indicator
    if (_hasUnreadMessages) {
      _hasUnreadMessages = false;
      _unreadMessagesController.add(false);
    }
  }

  /// Smoothly animate to the bottom of the chat with enhanced animation
  void animateToBottom({
    bool isCurrentUserMessage = false,
    bool isCurrentUser = false,
  }) {
    if (!scrollController.hasClients) return;

    // Calculate distance to scroll
    final position = scrollController.position;
    final distanceToScroll = position.maxScrollExtent - position.pixels;

    // Skip animation if already at bottom
    if (distanceToScroll <= 0) return;

    // Adaptive duration based on scroll distance
    final baseDuration = isCurrentUserMessage ? 200 : 300;
    final adaptiveDuration = _calculateAdaptiveDuration(
      distanceToScroll,
      baseDuration,
    );

    // Select appropriate curve based on distance and message sender
    final curve = _selectAnimationCurve(distanceToScroll, isCurrentUserMessage);

    // Execute the scroll animation
    scrollController.animateTo(
      position.maxScrollExtent,
      duration: Duration(milliseconds: adaptiveDuration),
      curve: curve,
    );

    // Clear unread messages indicator
    if (_hasUnreadMessages) {
      _hasUnreadMessages = false;
      _unreadMessagesController.add(false);
    }
  }

  /// Calculate adaptive duration based on scroll distance
  int _calculateAdaptiveDuration(double distance, int baseDuration) {
    // For very small distances, use a shorter duration
    if (distance < 100) {
      return (baseDuration * 0.5).round();
    }

    // For medium distances, use the base duration
    if (distance < _scrollDistanceThreshold) {
      return baseDuration;
    }

    // For larger distances, scale the duration but cap it
    final scaleFactor = (distance / _scrollDistanceThreshold).clamp(1.0, 2.0);
    return (baseDuration * scaleFactor).round().clamp(baseDuration, 600);
  }

  /// Select appropriate animation curve based on distance and message type
  Curve _selectAnimationCurve(double distance, bool isCurrentUserMessage) {
    // For small distances, use a simple ease out
    if (distance < 100) {
      return Curves.easeOutQuad;
    }

    // For medium distances
    if (distance < _scrollDistanceThreshold) {
      return isCurrentUserMessage ? Curves.easeOutQuad : Curves.easeOutCubic;
    }

    // For larger distances, use a more pronounced curve
    return isCurrentUserMessage
        ? Curves.easeOutCubic
        : Curves.elasticOut;
  }

  /// Mark a message as the latest for animation purposes
  void markMessageAsLatest(String messageId) {
    _latestMessageId = messageId;
  }

  /// Check if a message is the latest one
  bool isLatestMessage(String messageId) {
    return _latestMessageId == messageId;
  }

  /// Determine if we should auto-scroll for a new message
  bool shouldAutoScrollForNewMessage(bool isCurrentUserMessage) {
    // Always scroll for the current user's messages
    if (isCurrentUserMessage) return true;

    // If user is not actively scrolling and is near bottom, auto-scroll
    if (!_isUserScrolling && _isNearBottom) {
      return true;
    }

    // If we're not going to scroll, mark that we have unread messages
    if (!isCurrentUserMessage && !_isNearBottom) {
      _hasUnreadMessages = true;
      _unreadMessagesController.add(true);
    }

    return false;
  }

  /// Get whether there are unread messages
  bool get hasUnreadMessages => _hasUnreadMessages;

  /// Manually mark messages as read
  void markMessagesAsRead() {
    if (_hasUnreadMessages) {
      _hasUnreadMessages = false;
      _unreadMessagesController.add(false);
    }
  }

  /// Called when user starts scrolling
  void onUserScrollStart() {
    _isUserScrolling = true;
  }

  /// Called when user stops scrolling
  void onUserScrollEnd() {
    _isUserScrolling = false;

    // If user stopped scrolling near bottom and we have unread messages, clear them
    if (_isNearBottom && _hasUnreadMessages) {
      _hasUnreadMessages = false;
      _unreadMessagesController.add(false);
    }
  }

  /// Smooth scroll to a specific position with adaptive animation
  void smoothScrollTo(double position, {bool isJump = false}) {
    if (!scrollController.hasClients) return;

    if (isJump) {
      scrollController.jumpTo(position);
      return;
    }

    final currentPosition = scrollController.position.pixels;
    final distance = (position - currentPosition).abs();

    // Calculate adaptive duration
    final duration = _calculateAdaptiveDuration(distance, 300);
    final curve = distance < 100 ? Curves.easeOut : Curves.easeOutCubic;

    scrollController.animateTo(
      position,
      duration: Duration(milliseconds: duration),
      curve: curve,
    );
  }
}
