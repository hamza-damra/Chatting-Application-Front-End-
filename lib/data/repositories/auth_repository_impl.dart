import 'package:dio/dio.dart';
import 'dart:convert';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/auth_service.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../utils/logger.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiService _apiService;
  final StorageService _storageService;
  final AuthService _authService;

  AuthRepositoryImpl(this._apiService, this._storageService, this._authService);

  @override
  Future<bool> isAuthenticated() async {
    return await _authService.isAuthenticated();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await _apiService.get('/api/users/me');
      return UserModel.fromJson(response.data);
    } catch (e) {
      AppLogger.e('AuthRepositoryImpl', 'Error getting current user: $e');
      // If we can't get the current user, we're not authenticated
      await _storageService.clearUserData();
      return null;
    }
  }

  @override
  Future<UserModel> login(String usernameOrEmail, String password) async {
    try {
      final success = await _authService.login(
        usernameOrEmail: usernameOrEmail,
        password: password,
      );

      if (!success) {
        throw Exception('Login failed');
      }

      // Get user details
      final userResponse = await _apiService.get('/api/users/me');
      final user = UserModel.fromJson(userResponse.data);

      // Save user data
      await _storageService.saveUserData(jsonEncode(user.toJson()));

      return user;
    } catch (e) {
      AppLogger.e('AuthRepositoryImpl', 'Login error: $e');
      throw _handleError(e);
    }
  }

  @override
  Future<UserModel> register(
    String username,
    String email,
    String password,
    String fullName,
  ) async {
    try {
      final success = await _authService.register(
        username: username,
        email: email,
        password: password,
        fullName: fullName,
      );

      if (!success) {
        throw Exception('Registration failed');
      }

      // Get user details
      final userResponse = await _apiService.get('/api/users/me');
      final user = UserModel.fromJson(userResponse.data);

      // Save user data
      await _storageService.saveUserData(jsonEncode(user.toJson()));

      return user;
    } catch (e) {
      AppLogger.e('AuthRepositoryImpl', 'Registration error: $e');
      throw _handleError(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _authService.logout();
      await _storageService.clearUserData();
    } catch (e) {
      AppLogger.e('AuthRepositoryImpl', 'Error during logout: $e');
      rethrow;
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        final statusCode = error.response!.statusCode;
        final data = error.response!.data;

        if (statusCode == 400) {
          return Exception(
            'Invalid credentials: ${data['message'] ?? 'Please check your username and password'}',
          );
        } else if (statusCode == 401) {
          return Exception(
            'Authentication failed: ${data['message'] ?? 'Unauthorized access'}',
          );
        } else if (statusCode == 409) {
          return Exception(
            'Account already exists: ${data['message'] ?? 'Please use a different username or email'}',
          );
        } else if (statusCode == 422) {
          return Exception(
            'Validation error: ${data['message'] ?? 'Please check your input'}',
          );
        } else if (statusCode! >= 500) {
          return Exception(
            'Server error: ${data['message'] ?? 'Something went wrong, please try again later'}',
          );
        }

        return Exception(
          'Authentication error: ${data['message'] ?? 'Unknown error'}',
        );
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return Exception(
          'Connection error: Please check your internet connection',
        );
      }

      return Exception('Network error: ${error.message}');
    }

    return Exception('Unexpected error: ${error.toString()}');
  }
}
