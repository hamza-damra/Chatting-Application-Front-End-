import '../utils/logger.dart';

/// Manages the current screen state to help with notification decisions
class ScreenStateManager {
  static final ScreenStateManager _instance = ScreenStateManager._internal();
  factory ScreenStateManager() => _instance;
  ScreenStateManager._internal();

  static ScreenStateManager get instance => _instance;

  // Current screen types
  String? _currentScreen;
  String? _currentChatRoomId;

  // Screen constants
  static const String chatListScreen = 'chat_list';
  static const String privateChatListScreen = 'private_chat_list';
  static const String groupChatListScreen = 'group_chat_list';
  static const String chatRoomScreen = 'chat_room';
  static const String profileScreen = 'profile';
  static const String settingsScreen = 'settings';
  static const String loginScreen = 'login';
  static const String otherScreen = 'other';

  /// Get current screen
  String? get currentScreen => _currentScreen;

  /// Get current chat room ID (if in a chat room)
  String? get currentChatRoomId => _currentChatRoomId;

  /// Check if user is currently on any chat list screen
  bool get isOnChatListScreen {
    return _currentScreen == chatListScreen ||
        _currentScreen == privateChatListScreen ||
        _currentScreen == groupChatListScreen;
  }

  /// Check if user is currently in a specific chat room
  bool isInChatRoom(String roomId) {
    return _currentScreen == chatRoomScreen && _currentChatRoomId == roomId;
  }

  /// Update current screen
  void updateCurrentScreen(String screen, {String? chatRoomId}) {
    final previousScreen = _currentScreen;

    _currentScreen = screen;
    _currentChatRoomId = chatRoomId;

    AppLogger.i(
      'ScreenStateManager',
      'Screen changed: $previousScreen -> $screen ${chatRoomId != null ? '(room: $chatRoomId)' : ''}',
    );

    // Log specific transitions for debugging
    if (isOnChatListScreen) {
      AppLogger.i(
        'ScreenStateManager',
        'User is now on chat list screen - notifications should be suppressed',
      );
    } else if (_currentScreen == chatRoomScreen && chatRoomId != null) {
      AppLogger.i(
        'ScreenStateManager',
        'User is now in chat room $chatRoomId - notifications for this room should be suppressed',
      );
    }
  }

  /// Clear current screen (when app goes to background)
  void clearCurrentScreen() {
    AppLogger.i(
      'ScreenStateManager',
      'Clearing current screen state (app backgrounded)',
    );
    _currentScreen = null;
    _currentChatRoomId = null;
  }

  /// Check if notifications should be suppressed for a given room
  bool shouldSuppressNotification(String roomId) {
    // Suppress if user is on any chat list screen
    if (isOnChatListScreen) {
      AppLogger.d(
        'ScreenStateManager',
        'Suppressing notification for room $roomId - user is on chat list screen',
      );
      return true;
    }

    // Suppress if user is in the specific chat room
    if (isInChatRoom(roomId)) {
      AppLogger.d(
        'ScreenStateManager',
        'Suppressing notification for room $roomId - user is in this chat room',
      );
      return true;
    }

    return false;
  }

  /// Get debug info about current state
  Map<String, dynamic> getDebugInfo() {
    return {
      'currentScreen': _currentScreen,
      'currentChatRoomId': _currentChatRoomId,
      'isOnChatListScreen': isOnChatListScreen,
    };
  }
}
