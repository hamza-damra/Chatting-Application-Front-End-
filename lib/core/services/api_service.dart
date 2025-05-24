import 'package:dio/dio.dart';
import 'token_service.dart';
import '../../utils/logger.dart';

class ApiService {
  final Dio _dio;
  final TokenService _tokenService;

  ApiService(this._dio, this._tokenService) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token to requests if available
          final token = await _tokenService.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Handle token refresh on 401 errors
          if (error.response?.statusCode == 401) {
            try {
              final refreshed = await _tokenService.performTokenRefresh();
              if (refreshed) {
                // Retry the request with the new token
                final token = await _tokenService.getAccessToken();
                error.requestOptions.headers['Authorization'] = 'Bearer $token';

                // Create a new request with the updated token
                final response = await _dio.fetch(error.requestOptions);
                return handler.resolve(response);
              }
            } catch (e) {
              AppLogger.e('ApiService', 'Error refreshing token: $e');
              // If refresh fails, proceed with the error
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } catch (e) {
      AppLogger.e('ApiService', 'GET request failed: $e');
      rethrow;
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } catch (e) {
      AppLogger.e('ApiService', 'POST request failed: $e');
      rethrow;
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.put(path, data: data, queryParameters: queryParameters);
    } catch (e) {
      AppLogger.e('ApiService', 'PUT request failed: $e');
      rethrow;
    }
  }

  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.delete(path, queryParameters: queryParameters);
    } catch (e) {
      AppLogger.e('ApiService', 'DELETE request failed: $e');
      rethrow;
    }
  }
}
