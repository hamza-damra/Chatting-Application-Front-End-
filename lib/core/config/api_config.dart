class ApiConfig {
  // Base URL
  static const String baseUrl =
      'http://abusaker.zapto.org:8080'; // For Android emulator

  // Auth endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String logoutEndpoint = '/api/auth/logout';
  static const String refreshTokenEndpoint = '/api/auth/refresh-token';

  // User endpoints
  static const String usersEndpoint = '/api/users';
  static const String userProfileEndpoint = '/api/users/me';
  static const String userSearchEndpoint = '/api/users/search';

  // Chat room endpoints
  static const String chatRoomsEndpoint = '/api/chatrooms';

  // Message endpoints
  static const String messagesEndpoint = '/api/messages';

  // WebSocket endpoints
  static const String webSocketEndpoint = 'ws://abusaker.zapto.org:8080/ws';

  // STOMP destinations
  static const String stompChatTopic = '/topic/chatrooms/';
  static const String stompUserStatusTopic = '/user/queue/notifications';
  static const String stompUnreadTopic = '/user/queue/unread';
  static const String stompUnreadMessagesEndpoint = '/user/unread-messages';
  static const String stompSendMessageEndpoint = '/app/chat.sendMessage';
  static const String stompAddUserEndpoint = '/app/chat.addUser';
  static const String stompLeaveRoomEndpoint = '/app/chat.leaveRoom';
  static const String stompGetUnreadCountsEndpoint =
      '/app/chat.getUnreadCounts';
  static const String stompMarkRoomAsReadEndpoint = '/app/chat.markRoomAsRead';

  // Get auth headers
  static Map<String, String> getAuthHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}
