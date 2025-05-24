import 'package:dio/dio.dart';
import '../../core/services/api_service.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/user_repository.dart';
import '../../utils/logger.dart';

class UserRepositoryImpl implements UserRepository {
  final ApiService _apiService;

  UserRepositoryImpl(this._apiService);

  @override
  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _apiService.get('/api/users');
      final List<dynamic> usersJson = response.data;
      return usersJson.map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      AppLogger.e('UserRepositoryImpl', 'Error getting all users: $e');
      throw _handleError(e);
    }
  }

  @override
  Future<UserModel> getUserById(String id) async {
    try {
      final response = await _apiService.get('/api/users/$id');
      return UserModel.fromJson(response.data);
    } catch (e) {
      AppLogger.e('UserRepositoryImpl', 'Error getting user by ID: $e');
      throw _handleError(e);
    }
  }

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final response = await _apiService.get(
        '/api/users/search',
        queryParameters: {'query': query},
      );
      final List<dynamic> usersJson = response.data;
      return usersJson.map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      AppLogger.e('UserRepositoryImpl', 'Error searching users: $e');
      throw _handleError(e);
    }
  }

  @override
  Future<UserModel> updateUserProfile(UserModel user) async {
    try {
      final response = await _apiService.put(
        '/api/users/${user.id}',
        data: {
          'fullName': user.fullName,
          'email': user.email,
          'profilePicture': user.profilePicture,
        },
      );
      return UserModel.fromJson(response.data);
    } catch (e) {
      AppLogger.e('UserRepositoryImpl', 'Error updating user profile: $e');
      throw _handleError(e);
    }
  }

  @override
  Future<void> updateUserStatus(String userId, bool isOnline) async {
    try {
      await _apiService.put('/api/users/status', data: {'isOnline': isOnline});
    } catch (e) {
      AppLogger.e('UserRepositoryImpl', 'Error updating user status: $e');
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        final statusCode = error.response!.statusCode;
        final data = error.response!.data;

        if (statusCode == 404) {
          return Exception('User not found');
        } else if (statusCode == 400) {
          return Exception(
            'Bad request: ${data['message'] ?? 'Unknown error'}',
          );
        } else if (statusCode == 403) {
          return Exception(
            'Access denied: You do not have permission to perform this action',
          );
        } else if (statusCode! >= 500) {
          return Exception(
            'Server error: ${data['message'] ?? 'Unknown error'}',
          );
        }

        return Exception(
          'HTTP error $statusCode: ${data['message'] ?? 'Unknown error'}',
        );
      }

      return Exception('Network error: ${error.message}');
    }

    return Exception('Unexpected error: ${error.toString()}');
  }
}
