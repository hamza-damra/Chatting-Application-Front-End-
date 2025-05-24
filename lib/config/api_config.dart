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

  // Chat room endpoints
  static const String chatRoomsEndpoint = '/api/chatrooms';

  // Message endpoints
  static const String messagesEndpoint = '/api/messages';

  // File endpoints
  static const String filesEndpoint = '/api/files';

  // WebSocket endpoints
  static const String webSocketEndpoint = 'ws://abusaker.zapto.org:8080/ws';

  // STOMP destinations
  static const String stompChatTopic = '/topic/chatrooms/';
  static const String stompUserStatusTopic = '/user/queue/notifications';
  // The backend expects '/app/chat.sendMessage/{roomId}' format
  // We'll use a template that will be completed with the roomId
  static const String stompSendMessageEndpoint =
      '/app/chat.sendMessage'; // Base endpoint, roomId will be appended
  static const String stompAddUserEndpoint =
      '/app/chat.addUser'; // Add back '/app' prefix
  static const String stompLeaveRoomEndpoint =
      '/app/chat.leaveRoom'; // Add back '/app' prefix

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
}
