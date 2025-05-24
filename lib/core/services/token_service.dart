import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../utils/logger.dart';
import '../../utils/url_utils.dart';

class TokenService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';

  final Dio _dio;
  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;

  // Getters
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get hasToken => _accessToken != null && _refreshToken != null;
  bool get isTokenExpired =>
      _tokenExpiry != null && DateTime.now().isAfter(_tokenExpiry!);

  TokenService(this._dio);

  // Initialize token service
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _accessToken = prefs.getString(_accessTokenKey);
      _refreshToken = prefs.getString(_refreshTokenKey);

      final expiryMillis = prefs.getInt(_tokenExpiryKey);
      if (expiryMillis != null) {
        _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(expiryMillis);
      }

      AppLogger.i(
        'TokenService',
        'Initialized with token: ${_accessToken != null ? 'Present' : 'Not present'}',
      );

      // Set up Dio interceptor for token refresh
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            if (_accessToken != null) {
              options.headers['Authorization'] = 'Bearer $_accessToken';
              AppLogger.d(
                'TokenService',
                'Added token to request: ${options.path}',
              );
            }
            return handler.next(options);
          },
          onError: (error, handler) async {
            if (error.response?.statusCode == 401 && _refreshToken != null) {
              AppLogger.w('TokenService', 'Token expired, attempting refresh');
              try {
                final refreshed = await refreshAccessToken();
                if (refreshed) {
                  AppLogger.i('TokenService', 'Token refreshed successfully');
                  // Retry the original request
                  final response = await _dio.fetch(error.requestOptions);
                  return handler.resolve(response);
                } else {
                  AppLogger.e('TokenService', 'Token refresh failed');
                  await clearTokens();
                  return handler.next(error);
                }
              } catch (e) {
                AppLogger.e('TokenService', 'Error during token refresh: $e');
                await clearTokens();
                return handler.next(error);
              }
            }
            return handler.next(error);
          },
        ),
      );
    } catch (e) {
      AppLogger.e('TokenService', 'Error initializing token service: $e');
      rethrow;
    }
  }

  // Get the stored access token
  Future<String?> getAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accessTokenKey);
    } catch (e) {
      AppLogger.e('TokenService', 'Error getting access token: $e');
      return null;
    }
  }

  // Get the stored refresh token
  Future<String?> getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    } catch (e) {
      AppLogger.e('TokenService', 'Error getting refresh token: $e');
      return null;
    }
  }

  // Check if the token is expired with buffer time
  Future<bool> checkTokenExpiration() async {
    if (_tokenExpiry == null) {
      AppLogger.d('TokenService', 'No token expiry set');
      return true;
    }

    // Consider token expired 5 minutes before actual expiry
    final bufferTime = const Duration(minutes: 5);
    final isExpired = DateTime.now().isAfter(
      _tokenExpiry!.subtract(bufferTime),
    );
    AppLogger.d(
      'TokenService',
      'Token expiry check: ${isExpired ? 'Expired' : 'Valid'}',
    );
    return isExpired;
  }

  // Save tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    try {
      _accessToken = accessToken;
      _refreshToken = refreshToken;
      _tokenExpiry = DateTime.now().add(Duration(milliseconds: expiresIn));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, accessToken);
      await prefs.setString(_refreshTokenKey, refreshToken);
      await prefs.setInt(_tokenExpiryKey, _tokenExpiry!.millisecondsSinceEpoch);

      // Update UrlUtils with the new token
      UrlUtils.setAuthToken(accessToken);

      AppLogger.i('TokenService', 'Tokens saved successfully');
    } catch (e) {
      AppLogger.e('TokenService', 'Error saving tokens: $e');
      rethrow;
    }
  }

  // Clear tokens
  Future<void> clearTokens() async {
    try {
      _accessToken = null;
      _refreshToken = null;
      _tokenExpiry = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_tokenExpiryKey);

      // Clear token from UrlUtils
      UrlUtils.setAuthToken("");

      AppLogger.i('TokenService', 'Tokens cleared successfully');
    } catch (e) {
      AppLogger.e('TokenService', 'Error clearing tokens: $e');
      rethrow;
    }
  }

  // Refresh access token
  Future<bool> refreshAccessToken() async {
    try {
      AppLogger.i('TokenService', 'Attempting to refresh token');
      final response = await _dio.post(
        '/api/auth/refresh',
        data: {'refreshToken': _refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          expiresIn: data['expiresIn'],
        );
        AppLogger.i('TokenService', 'Token refreshed successfully');
        return true;
      }
      AppLogger.w(
        'TokenService',
        'Token refresh failed with status: ${response.statusCode}',
      );
      return false;
    } catch (e) {
      AppLogger.e('TokenService', 'Error refreshing token: $e');
      await clearTokens();
      return false;
    }
  }

  // Public method to refresh token
  Future<bool> performTokenRefresh() async {
    return refreshAccessToken();
  }
}
