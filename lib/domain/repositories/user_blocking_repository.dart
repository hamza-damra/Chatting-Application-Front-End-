import '../models/blocked_user_model.dart';

abstract class UserBlockingRepository {
  /// Block a user
  Future<BlockedUserModel> blockUser(int userId, {String? reason});
  
  /// Unblock a user
  Future<void> unblockUser(int userId);
  
  /// Get list of blocked users
  Future<List<BlockedUserModel>> getBlockedUsers();
  
  /// Check if a user is blocked
  Future<bool> isUserBlocked(int userId);
  
  /// Get count of blocked users
  Future<int> getBlockedUsersCount();
}
