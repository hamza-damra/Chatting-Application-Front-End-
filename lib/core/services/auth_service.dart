import 'package:dio/dio.dart';
import 'token_service.dart';
import '../../utils/logger.dart';

class AuthService {
  final Dio _dio;
  final TokenService _tokenService;

  AuthService(this._dio, this._tokenService);

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    if (!_tokenService.hasToken) return false;

    // Check if token is expired
    final isExpired = await _tokenService.checkTokenExpiration();
    if (isExpired) {
      // Try to refresh the token
      return await _tokenService.performTokenRefresh();
    }

    return true;
  }

  // Login with username/email and password
  Future<bool> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {'usernameOrEmail': usernameOrEmail, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await _tokenService.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          expiresIn: data['expiresIn'],
        );
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.e('AuthService', 'Login error: $e');
      return false;
    }
  }

  // Register with username, email, and password
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
          'fullName': fullName,
        },
      );

      if (response.statusCode == 201) {
        final data = response.data;
        await _tokenService.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          expiresIn: data['expiresIn'],
        );
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.e('AuthService', 'Registration error: $e');
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _tokenService.clearTokens();
  }

  // Get current user data
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await _dio.get('/api/auth/me');
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      AppLogger.e('AuthService', 'Get current user error: $e');
      return null;
    }
  }
}
