import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../core/services/token_service.dart';

class ApiAuthService {
  final TokenService _tokenService;
  final http.Client _httpClient;

  ApiAuthService({required TokenService tokenService, http.Client? httpClient})
    : _tokenService = tokenService,
      _httpClient = httpClient ?? http.Client();

  // Check if user is authenticated
  bool get isAuthenticated =>
      _tokenService.hasToken && !_tokenService.isTokenExpired;

  // Get the current access token
  String? getAccessToken() {
    return _tokenService.accessToken;
  }

  // Register with username, email, and password
  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse(ApiConfig.baseUrl + ApiConfig.registerEndpoint),
        headers: ApiConfig.getContentTypeHeader(),
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'fullName': fullName,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return UserModel.fromMap(data);
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Login with username/email and password
  Future<UserModel> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse(ApiConfig.baseUrl + ApiConfig.loginEndpoint),
        headers: ApiConfig.getContentTypeHeader(),
        body: jsonEncode({
          'usernameOrEmail': usernameOrEmail,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Save tokens
        await _tokenService.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          expiresIn: data['expiresIn'],
        );

        return UserModel.fromMap(data['user']);
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Refresh token
  Future<void> refreshToken() async {
    try {
      if (_tokenService.refreshToken == null) {
        throw Exception('No refresh token available');
      }

      final response = await _httpClient.post(
        Uri.parse(ApiConfig.baseUrl + ApiConfig.refreshTokenEndpoint),
        headers: ApiConfig.getContentTypeHeader(),
        body: jsonEncode({'refreshToken': _tokenService.refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Save new tokens
        await _tokenService.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          expiresIn: data['expiresIn'],
        );
      } else {
        // If refresh token is invalid, clear tokens and force re-login
        await _tokenService.clearTokens();
        throw _handleError(response);
      }
    } catch (e) {
      await _tokenService.clearTokens();
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      if (_tokenService.accessToken != null) {
        await _httpClient.post(
          Uri.parse(ApiConfig.baseUrl + ApiConfig.logoutEndpoint),
          headers: ApiConfig.getAuthHeaders(_tokenService.accessToken!),
        );
      }
    } catch (e) {
      // Ignore errors during logout
    } finally {
      await _tokenService.clearTokens();
    }
  }

  // Get current user
  Future<UserModel> getCurrentUser() async {
    try {
      await _ensureValidToken();

      final response = await _httpClient.get(
        Uri.parse(ApiConfig.baseUrl + ApiConfig.currentUserEndpoint),
        headers: ApiConfig.getAuthHeaders(_tokenService.accessToken!),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromMap(data);
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile
  Future<UserModel> updateUserProfile({
    required String fullName,
    String? profilePicture,
  }) async {
    try {
      await _ensureValidToken();

      final response = await _httpClient.put(
        Uri.parse(ApiConfig.baseUrl + ApiConfig.updateUserEndpoint),
        headers: ApiConfig.getAuthHeaders(_tokenService.accessToken!),
        body: jsonEncode({
          'fullName': fullName,
          if (profilePicture != null) 'profilePicture': profilePicture,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromMap(data);
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _ensureValidToken();

      final response = await _httpClient.put(
        Uri.parse(ApiConfig.baseUrl + ApiConfig.changePasswordEndpoint),
        headers: ApiConfig.getAuthHeaders(_tokenService.accessToken!),
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode != 200) {
        throw _handleError(response);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Ensure token is valid, refresh if needed
  Future<void> _ensureValidToken() async {
    if (!_tokenService.hasToken) {
      throw Exception('Not authenticated');
    }

    if (_tokenService.isTokenExpired) {
      await _tokenService.performTokenRefresh();
    }
  }

  // Handle API errors
  Exception _handleError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      return Exception(data['message'] ?? 'Unknown error');
    } catch (e) {
      return Exception(
        'Error ${response.statusCode}: ${response.reasonPhrase}',
      );
    }
  }
}
