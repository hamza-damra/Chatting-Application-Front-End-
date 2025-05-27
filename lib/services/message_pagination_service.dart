import 'package:dio/dio.dart';
import '../models/message.dart';
import '../models/paged_response.dart';
import '../utils/logger.dart';
import '../config/api_config.dart';
import '../core/services/token_service.dart';

class MessagePaginationService {
  final Dio _dio;
  final TokenService _tokenService;

  MessagePaginationService(this._dio, this._tokenService);

  /// Get paginated messages for a chat room
  Future<PagedResponse<Message>> getMessages({
    required int chatRoomId,
    int page = 0,
    int size = 20,
  }) async {
    try {
      // Ensure we have a valid token
      await _ensureValidToken();

      AppLogger.i(
        'MessagePaginationService',
        'Fetching messages for room $chatRoomId, page: $page, size: $size',
      );

      final response = await _dio.get(
        '/api/messages/chatroom/$chatRoomId',
        queryParameters: {'page': page, 'size': size},
        options: Options(
          headers: ApiConfig.getAuthHeaders(_tokenService.accessToken!),
        ),
      );

      if (response.statusCode == 200) {
        AppLogger.i(
          'MessagePaginationService',
          'Successfully fetched messages: ${response.data}',
        );

        // Handle different response formats from backend
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          // Check if it's a paginated response with metadata
          if (responseData.containsKey('page') &&
              responseData.containsKey('size') &&
              responseData.containsKey('totalElements')) {
            // Standard paginated response
            return PagedResponse.fromJson(
              responseData,
              (json) => Message.fromJson(json),
            );
          } else if (responseData.containsKey('content')) {
            // Response with content array but missing pagination metadata
            final List<dynamic> messages =
                responseData['content'] as List<dynamic>;
            return PagedResponse<Message>(
              content:
                  messages
                      .map(
                        (json) =>
                            Message.fromJson(json as Map<String, dynamic>),
                      )
                      .toList(),
              page: page,
              size: size,
              totalElements: messages.length,
              totalPages: 1, // Assume single page if no metadata
              last: true, // Assume last page if no metadata
            );
          }
        } else if (responseData is List<dynamic>) {
          // Direct array response (legacy format)
          return PagedResponse<Message>(
            content:
                responseData
                    .map(
                      (json) => Message.fromJson(json as Map<String, dynamic>),
                    )
                    .toList(),
            page: page,
            size: size,
            totalElements: responseData.length,
            totalPages: 1, // Assume single page if no metadata
            last: true, // Assume last page if no metadata
          );
        }

        throw Exception('Unexpected response format from server');
      } else {
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.e(
        'MessagePaginationService',
        'DioException while fetching messages: ${e.message}',
      );

      if (e.response?.statusCode == 403) {
        throw Exception('Access denied to chat room');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Chat room not found');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Authentication required');
      }
      throw Exception('Failed to load messages: ${e.message}');
    } catch (e) {
      AppLogger.e('MessagePaginationService', 'Error fetching messages: $e');
      throw Exception('Failed to load messages: $e');
    }
  }

  /// Ensure we have a valid authentication token
  Future<void> _ensureValidToken() async {
    if (_tokenService.accessToken == null) {
      throw Exception('No authentication token available');
    }

    // Check if token is expired and refresh if needed
    if (_tokenService.isTokenExpired) {
      try {
        final refreshed = await _tokenService.refreshAccessToken();
        if (!refreshed) {
          throw Exception('Failed to refresh token');
        }
      } catch (e) {
        AppLogger.e('MessagePaginationService', 'Failed to refresh token: $e');
        throw Exception('Authentication failed');
      }
    }
  }

  /// Get the latest messages (first page) for a chat room
  Future<PagedResponse<Message>> getLatestMessages({
    required int chatRoomId,
    int size = 20,
  }) async {
    return getMessages(chatRoomId: chatRoomId, page: 0, size: size);
  }

  /// Get older messages (next page) for a chat room
  Future<PagedResponse<Message>> getOlderMessages({
    required int chatRoomId,
    required int currentPage,
    int size = 20,
  }) async {
    return getMessages(
      chatRoomId: chatRoomId,
      page: currentPage + 1,
      size: size,
    );
  }

  /// Get messages for a specific page
  Future<PagedResponse<Message>> getMessagesForPage({
    required int chatRoomId,
    required int page,
    int size = 20,
  }) async {
    return getMessages(chatRoomId: chatRoomId, page: page, size: size);
  }
}
