class ApiConfig {
  // Base URL for API requests
  static const String baseUrl = 'http://abusaker.zapto.org:8080';

  // Authentication endpoints
  static const String registerEndpoint = '/api/auth/register';
  static const String loginEndpoint = '/api/auth/login';
  static const String refreshTokenEndpoint = '/api/auth/refresh';
  static const String logoutEndpoint = '/api/auth/logout';

  // User endpoints
  static const String currentUserEndpoint = '/api/users/me';
  static const String updateUserEndpoint = '/api/users/me';
  static const String changePasswordEndpoint = '/api/users/password';
  static const String usersEndpoint = '/api/users';
  static const String userStatusEndpoint = '/api/users/status';

  // Profile image endpoints
  static const String addProfileImageEndpoint = '/api/users/me/profile-image';
  static const String updateProfileImageEndpoint =
      '/api/users/me/profile-image';

  // Profile image GET endpoints (NEW - Direct image access)
  static const String getCurrentUserProfileImageEndpoint =
      '/api/users/me/profile-image/view';
  static const String getUserProfileImageEndpoint =
      '/api/users/{userId}/profile-image/view';

  // Chat room endpoints
  static const String chatRoomsEndpoint = '/api/chatrooms';

  // Message endpoints
  static const String messagesEndpoint = '/api/messages';

  // File endpoints
  static const String filesEndpoint = '/api/files';

  // WebSocket endpoints
  static const String webSocketEndpoint = 'ws://abusaker.zapto.org:8080/ws';

  // STOMP destinations - Updated to match backend documentation
  static const String stompChatTopic = '/topic/chatrooms/';

  // Notification subscription endpoints (client subscribes to these)
  static const String stompNotificationsEndpoint = '/user/notifications';
  static const String stompUnreadNotificationsEndpoint =
      '/user/notifications/unread';
  static const String stompUnreadCountEndpoint =
      '/user/notifications/unread-count';
  static const String stompNotificationErrorEndpoint =
      '/user/notifications/error';
  static const String stompReadAllConfirmationEndpoint =
      '/user/notifications/read-all-confirmation';

  // Legacy endpoints for backward compatibility
  static const String stompUserStatusTopic = '/user/queue/notifications';
  static const String stompUnreadTopic = '/user/queue/unread';
  static const String stompUnreadMessagesEndpoint = '/user/unread-messages';

  // Chat message destinations
  static const String stompSendMessageEndpoint = '/app/chat.sendMessage';
  static const String stompAddUserEndpoint = '/app/chat.addUser';
  static const String stompLeaveRoomEndpoint = '/app/chat.leaveRoom';
  static const String stompGetUnreadCountsEndpoint =
      '/app/chat.getUnreadCounts';
  static const String stompMarkRoomAsReadEndpoint = '/app/chat.markRoomAsRead';

  // Notification command destinations (client sends to these)
  static const String stompGetUnreadNotificationsEndpoint =
      '/app/notifications.getUnread';
  static const String stompMarkNotificationAsReadEndpoint =
      '/app/notifications.markAsRead';
  static const String stompMarkAllNotificationsAsReadEndpoint =
      '/app/notifications.markAllAsRead';
  static const String stompGetUnreadNotificationCountEndpoint =
      '/app/notifications.getUnreadCount';

  // Headers
  static Map<String, String> getAuthHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Map<String, String> getContentTypeHeader() {
    return {'Content-Type': 'application/json'};
  }

  // Profile image URL helpers (NEW)
  static String getCurrentUserProfileImageUrl() {
    return baseUrl + getCurrentUserProfileImageEndpoint;
  }

  static String getUserProfileImageUrl(int userId) {
    return baseUrl +
        getUserProfileImageEndpoint.replaceAll('{userId}', userId.toString());
  }
}
