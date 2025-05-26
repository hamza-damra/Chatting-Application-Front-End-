import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../core/services/token_service.dart';
import '../domain/models/blocked_user_model.dart';
import '../utils/logger.dart';

class UserBlockingService {
  final TokenService _tokenService;
  final http.Client _httpClient;

  UserBlockingService({
    required TokenService tokenService,
    http.Client? httpClient,
  }) : _tokenService = tokenService,
       _httpClient = httpClient ?? http.Client();

  /// Block a user
  Future<BlockedUserModel> blockUser(
    int userId, {
    String? reason,
    bool isRetry = false,
  }) async {
    try {
      await _ensureValidToken();

      final request = BlockUserRequest(userId: userId, reason: reason);

      AppLogger.i(
        'UserBlockingService',
        'Blocking user: $userId${isRetry ? ' (retry)' : ''}',
      );

      final response = await _httpClient.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.blockUserEndpoint}'),
        headers: _getAuthHeaders(),
        body: jsonEncode(request.toJson()),
      );

      AppLogger.i(
        'UserBlockingService',
        'Block user response status: ${response.statusCode}',
      );
      AppLogger.i(
        'UserBlockingService',
        'Block user response body: ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        AppLogger.i('UserBlockingService', 'Parsed response data: $data');

        final blockedUser = BlockedUserModel.fromJson(data);

        AppLogger.i(
          'UserBlockingService',
          'User blocked successfully: $userId',
        );
        return blockedUser;
      } else if (response.statusCode == 401 && !isRetry) {
        AppLogger.w(
          'UserBlockingService',
          'Authentication failed when blocking user: $userId',
        );
        // Try to refresh token and retry once
        try {
          final refreshed = await _tokenService.refreshAccessToken();
          if (refreshed) {
            AppLogger.i(
              'UserBlockingService',
              'Token refreshed, retrying block',
            );
            return await blockUser(
              userId,
              reason: reason,
              isRetry: true,
            ); // Retry once
          }
        } catch (refreshError) {
          AppLogger.e(
            'UserBlockingService',
            'Token refresh failed: $refreshError',
          );
        }
        throw Exception('Authentication failed. Please try logging in again.');
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to block user';
        AppLogger.e(
          'UserBlockingService',
          'Block user failed: $errorMessage (Status: ${response.statusCode})',
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      AppLogger.e('UserBlockingService', 'Block user error: $e');
      rethrow;
    }
  }

  /// Unblock a user
  Future<void> unblockUser(int userId, {bool isRetry = false}) async {
    try {
      await _ensureValidToken();

      AppLogger.i(
        'UserBlockingService',
        'Unblocking user: $userId${isRetry ? ' (retry)' : ''}',
      );

      final response = await _httpClient.delete(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.unblockUserEndpoint}/$userId',
        ),
        headers: _getAuthHeaders(),
      );

      AppLogger.i(
        'UserBlockingService',
        'Unblock user response status: ${response.statusCode}',
      );
      AppLogger.i(
        'UserBlockingService',
        'Unblock user response body: ${response.body}',
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        AppLogger.i(
          'UserBlockingService',
          'User unblocked successfully: $userId',
        );
      } else if (response.statusCode == 401 && !isRetry) {
        AppLogger.w(
          'UserBlockingService',
          'Authentication failed when unblocking user: $userId',
        );
        // Try to refresh token and retry once
        try {
          final refreshed = await _tokenService.refreshAccessToken();
          if (refreshed) {
            AppLogger.i(
              'UserBlockingService',
              'Token refreshed, retrying unblock',
            );
            return await unblockUser(userId, isRetry: true); // Retry once
          }
        } catch (refreshError) {
          AppLogger.e(
            'UserBlockingService',
            'Token refresh failed: $refreshError',
          );
        }
        throw Exception('Authentication failed. Please try logging in again.');
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to unblock user';
        AppLogger.e(
          'UserBlockingService',
          'Unblock user failed: $errorMessage (Status: ${response.statusCode})',
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      AppLogger.e('UserBlockingService', 'Unblock user error: $e');
      rethrow;
    }
  }

  /// Get list of blocked users
  Future<List<BlockedUserModel>> getBlockedUsers() async {
    try {
      await _ensureValidToken();

      AppLogger.i('UserBlockingService', 'Fetching blocked users');

      final response = await _httpClient.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.blockedUsersEndpoint}'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final blockedUsers =
            data.map((json) => BlockedUserModel.fromJson(json)).toList();

        AppLogger.i(
          'UserBlockingService',
          'Fetched ${blockedUsers.length} blocked users',
        );
        return blockedUsers;
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage =
            errorData['message'] ?? 'Failed to fetch blocked users';
        AppLogger.e(
          'UserBlockingService',
          'Fetch blocked users failed: $errorMessage',
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      AppLogger.e('UserBlockingService', 'Fetch blocked users error: $e');
      rethrow;
    }
  }

  /// Check if a user is blocked
  Future<bool> isUserBlocked(int userId, {bool isRetry = false}) async {
    try {
      await _ensureValidToken();

      AppLogger.d(
        'UserBlockingService',
        'Checking if user is blocked: $userId${isRetry ? ' (retry)' : ''}',
      );

      final response = await _httpClient.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.isBlockedEndpoint}/$userId'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final blockStatus = BlockStatusResponse.fromJson(data);

        AppLogger.d(
          'UserBlockingService',
          'User $userId blocked status: ${blockStatus.isBlocked}',
        );
        return blockStatus.isBlocked;
      } else if (response.statusCode == 401 && !isRetry) {
        AppLogger.w(
          'UserBlockingService',
          'Authentication failed when checking block status for user: $userId',
        );
        // Try to refresh token and retry once
        try {
          final refreshed = await _tokenService.refreshAccessToken();
          if (refreshed) {
            AppLogger.i(
              'UserBlockingService',
              'Token refreshed, retrying block status check',
            );
            return await isUserBlocked(userId, isRetry: true); // Retry once
          }
        } catch (refreshError) {
          AppLogger.e(
            'UserBlockingService',
            'Token refresh failed: $refreshError',
          );
        }
        return false; // Default to not blocked if auth fails
      } else {
        AppLogger.w(
          'UserBlockingService',
          'Failed to check block status for user: $userId (Status: ${response.statusCode})',
        );
        return false; // Default to not blocked if check fails
      }
    } catch (e) {
      AppLogger.e('UserBlockingService', 'Check block status error: $e');
      return false; // Default to not blocked on error
    }
  }

  /// Get count of blocked users
  Future<int> getBlockedUsersCount() async {
    try {
      await _ensureValidToken();

      AppLogger.d('UserBlockingService', 'Fetching blocked users count');

      final response = await _httpClient.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.blockedUsersCountEndpoint}'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final countResponse = BlockedUsersCountResponse.fromJson(data);

        AppLogger.d(
          'UserBlockingService',
          'Blocked users count: ${countResponse.blockedUsersCount}',
        );
        return countResponse.blockedUsersCount;
      } else {
        AppLogger.w(
          'UserBlockingService',
          'Failed to fetch blocked users count',
        );
        return 0; // Default to 0 if fetch fails
      }
    } catch (e) {
      AppLogger.e('UserBlockingService', 'Fetch blocked users count error: $e');
      return 0; // Default to 0 on error
    }
  }

  /// Ensure we have a valid token
  Future<void> _ensureValidToken() async {
    if (_tokenService.accessToken == null) {
      throw Exception('No access token available');
    }

    if (await _tokenService.checkTokenExpiration()) {
      AppLogger.i('UserBlockingService', 'Token expired, attempting refresh');
      final refreshed = await _tokenService.refreshAccessToken();
      if (!refreshed) {
        throw Exception('Failed to refresh access token');
      }
    }
  }

  /// Get authentication headers
  Map<String, String> _getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${_tokenService.accessToken}',
    };
  }

  /// Dispose resources
  void dispose() {
    _httpClient.close();
  }
}
