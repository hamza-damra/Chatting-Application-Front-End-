import '../../domain/models/blocked_user_model.dart';
import '../../domain/repositories/user_blocking_repository.dart';
import '../../services/user_blocking_service.dart';
import '../../utils/logger.dart';

class UserBlockingRepositoryImpl implements UserBlockingRepository {
  final UserBlockingService _userBlockingService;

  UserBlockingRepositoryImpl(this._userBlockingService);

  @override
  Future<BlockedUserModel> blockUser(int userId, {String? reason}) async {
    try {
      return await _userBlockingService.blockUser(userId, reason: reason);
    } catch (e) {
      AppLogger.e('UserBlockingRepositoryImpl', 'Error blocking user: $e');
      throw _handleError(e);
    }
  }

  @override
  Future<void> unblockUser(int userId) async {
    try {
      await _userBlockingService.unblockUser(userId);
    } catch (e) {
      AppLogger.e('UserBlockingRepositoryImpl', 'Error unblocking user: $e');
      throw _handleError(e);
    }
  }

  @override
  Future<List<BlockedUserModel>> getBlockedUsers() async {
    try {
      return await _userBlockingService.getBlockedUsers();
    } catch (e) {
      AppLogger.e('UserBlockingRepositoryImpl', 'Error getting blocked users: $e');
      throw _handleError(e);
    }
  }

  @override
  Future<bool> isUserBlocked(int userId) async {
    try {
      return await _userBlockingService.isUserBlocked(userId);
    } catch (e) {
      AppLogger.e('UserBlockingRepositoryImpl', 'Error checking if user is blocked: $e');
      // Return false on error to avoid blocking UI functionality
      return false;
    }
  }

  @override
  Future<int> getBlockedUsersCount() async {
    try {
      return await _userBlockingService.getBlockedUsersCount();
    } catch (e) {
      AppLogger.e('UserBlockingRepositoryImpl', 'Error getting blocked users count: $e');
      // Return 0 on error
      return 0;
    }
  }

  /// Handle and transform errors
  Exception _handleError(dynamic error) {
    if (error is Exception) {
      return error;
    }
    return Exception(error.toString());
  }
}
