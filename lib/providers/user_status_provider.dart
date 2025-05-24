import 'package:flutter/foundation.dart';
import '../services/websocket_service.dart';

class UserStatusProvider with ChangeNotifier {
  final WebSocketService _webSocketService;
  final Map<String, bool> _userStatus = {};
  
  // Constructor
  UserStatusProvider({
    required WebSocketService webSocketService,
  }) : _webSocketService = webSocketService;
  
  // Get user status (online/offline)
  bool isUserOnline(String userId) {
    return _userStatus[userId] ?? false;
  }
  
  // Subscribe to a user's status updates
  void subscribeToUserStatus(String userId) {
    _webSocketService.subscribeToUserStatusUpdates(
      userId: userId,
      onStatusChanged: (isOnline) {
        _userStatus[userId] = isOnline;
        notifyListeners();
      },
    );
  }
  
  // Subscribe to multiple users' status updates
  void subscribeToMultipleUserStatus(List<String> userIds) {
    for (final userId in userIds) {
      subscribeToUserStatus(userId);
    }
  }
  
  // Clear all status data
  void clearStatus() {
    _userStatus.clear();
    notifyListeners();
  }
}
