import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../core/services/token_service.dart';
import '../utils/logger.dart';

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

  // Upload profile image (POST)
  Future<UserModel> uploadProfileImage({required File imageFile}) async {
    try {
      AppLogger.i('ApiAuthService', 'Starting profile image upload...');
      await _ensureValidToken();

      // Validate file exists
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      // Validate file size (5MB limit as per backend)
      final fileSize = await imageFile.length();
      AppLogger.d(
        'ApiAuthService',
        'File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB',
      );
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('Image file size cannot exceed 5MB');
      }

      // Validate file type
      final fileName = imageFile.path.split('/').last.toLowerCase();
      final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
      final fileExtension = fileName.split('.').last;
      AppLogger.d(
        'ApiAuthService',
        'File: $fileName, Extension: $fileExtension',
      );

      if (!allowedExtensions.contains(fileExtension)) {
        throw Exception('Only image files are allowed (JPEG, PNG, GIF, WebP)');
      }

      // Create multipart request
      final uploadUrl = ApiConfig.baseUrl + ApiConfig.addProfileImageEndpoint;

      // ENHANCED DEBUG LOGGING
      AppLogger.i('DEBUG', '=== PROFILE IMAGE UPLOAD DEBUG ===');
      AppLogger.i('DEBUG', 'Upload URL: $uploadUrl');
      AppLogger.i('DEBUG', 'Method: POST');
      AppLogger.i('DEBUG', 'File path: ${imageFile.path}');
      AppLogger.i('DEBUG', 'File exists: ${await imageFile.exists()}');
      AppLogger.i('DEBUG', 'File size: ${await imageFile.length()} bytes');
      AppLogger.i(
        'DEBUG',
        'Token length: ${_tokenService.accessToken?.length ?? 0}',
      );
      AppLogger.i('DEBUG', 'Token expired: ${_tokenService.isTokenExpired}');

      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

      // Add headers (DO NOT set Content-Type manually - let http package handle it)
      request.headers.addAll({
        'Authorization': 'Bearer ${_tokenService.accessToken}',
        'Accept': 'application/json',
      });

      AppLogger.i('DEBUG', 'Request headers: ${request.headers}');

      // Add file with exact parameter name "file"
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );
      AppLogger.i('DEBUG', 'File attached with parameter name: "file"');

      // Send request
      AppLogger.i('ApiAuthService', 'Sending profile image upload request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // ENHANCED RESPONSE LOGGING
      AppLogger.i('DEBUG', '=== RESPONSE DEBUG ===');
      AppLogger.i('DEBUG', 'Response status: ${response.statusCode}');
      AppLogger.i('DEBUG', 'Response headers: ${response.headers}');
      AppLogger.i('DEBUG', 'Response body: ${response.body}');
      AppLogger.i('DEBUG', 'Response reason: ${response.reasonPhrase}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.i('ApiAuthService', 'Profile image uploaded successfully');
        return UserModel.fromMap(data);
      } else {
        // Enhanced error logging for 500 errors
        if (response.statusCode == 500) {
          AppLogger.e('DEBUG', '500 INTERNAL SERVER ERROR DETAILS:');
          AppLogger.e(
            'DEBUG',
            'This suggests a backend issue, not a Flutter request issue',
          );
          AppLogger.e('DEBUG', 'Check backend logs for the actual error');
          AppLogger.e('DEBUG', 'Response body: ${response.body}');
        }

        AppLogger.e(
          'ApiAuthService',
          'Upload failed with status: ${response.statusCode}',
        );
        throw _handleError(response);
      }
    } catch (e) {
      AppLogger.e('ApiAuthService', 'Upload error: $e');
      rethrow;
    }
  }

  // Update profile image (PUT)
  Future<UserModel> updateProfileImage({required File imageFile}) async {
    try {
      AppLogger.i('ApiAuthService', 'Starting profile image update...');
      await _ensureValidToken();

      // Validate file exists
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      // Validate file size (5MB limit as per backend)
      final fileSize = await imageFile.length();
      AppLogger.d(
        'ApiAuthService',
        'File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB',
      );
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('Image file size cannot exceed 5MB');
      }

      // Validate file type
      final fileName = imageFile.path.split('/').last.toLowerCase();
      final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
      final fileExtension = fileName.split('.').last;
      AppLogger.d(
        'ApiAuthService',
        'File: $fileName, Extension: $fileExtension',
      );

      if (!allowedExtensions.contains(fileExtension)) {
        throw Exception('Only image files are allowed (JPEG, PNG, GIF, WebP)');
      }

      // Create multipart request
      final updateUrl =
          ApiConfig.baseUrl + ApiConfig.updateProfileImageEndpoint;
      AppLogger.d('ApiAuthService', 'Update URL: $updateUrl');

      final request = http.MultipartRequest('PUT', Uri.parse(updateUrl));

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer ${_tokenService.accessToken}',
        'Accept': 'application/json',
      });
      AppLogger.d('ApiAuthService', 'Headers added with token');

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );
      AppLogger.d('ApiAuthService', 'File attached to request');

      // Send request
      AppLogger.i('ApiAuthService', 'Sending profile image update request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      AppLogger.d('ApiAuthService', 'Response status: ${response.statusCode}');
      AppLogger.d('ApiAuthService', 'Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.i('ApiAuthService', 'Profile image updated successfully');
        return UserModel.fromMap(data);
      } else {
        AppLogger.e(
          'ApiAuthService',
          'Update failed with status: ${response.statusCode}',
        );
        throw _handleError(response);
      }
    } catch (e) {
      AppLogger.e('ApiAuthService', 'Update error: $e');
      rethrow;
    }
  }

  // Profile image URL helpers (NEW - Direct image access)
  String getCurrentUserProfileImageUrl() {
    return ApiConfig.getCurrentUserProfileImageUrl();
  }

  String getUserProfileImageUrl(int userId) {
    return ApiConfig.getUserProfileImageUrl(userId);
  }

  // Check if profile image exists for current user
  Future<bool> hasCurrentUserProfileImage() async {
    try {
      await _ensureValidToken();

      final response = await _httpClient.head(
        Uri.parse(getCurrentUserProfileImageUrl()),
        headers: ApiConfig.getAuthHeaders(_tokenService.accessToken!),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Check if profile image exists for specific user
  Future<bool> hasUserProfileImage(int userId) async {
    try {
      await _ensureValidToken();

      final response = await _httpClient.head(
        Uri.parse(getUserProfileImageUrl(userId)),
        headers: ApiConfig.getAuthHeaders(_tokenService.accessToken!),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Ensure token is valid, refresh if needed
  Future<void> _ensureValidToken() async {
    if (!_tokenService.hasToken) {
      throw Exception('Not authenticated');
    }

    if (_tokenService.isTokenExpired) {
      AppLogger.i('ApiAuthService', 'Token expired, refreshing...');
      await _tokenService.performTokenRefresh();
      AppLogger.i('ApiAuthService', 'Token refreshed successfully');
    }

    // Additional token validation for debugging
    final token = _tokenService.accessToken;
    if (token != null) {
      AppLogger.d('DEBUG', 'Token validation:');
      AppLogger.d('DEBUG', '  Length: ${token.length}');
      AppLogger.d('DEBUG', '  Starts with: ${token.substring(0, 20)}...');
      AppLogger.d('DEBUG', '  Contains Bearer: ${token.contains('Bearer')}');

      // Token should NOT contain 'Bearer' - that's added in headers
      if (token.contains('Bearer')) {
        AppLogger.w(
          'DEBUG',
          'WARNING: Token contains "Bearer" - this might cause issues',
        );
      }
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
