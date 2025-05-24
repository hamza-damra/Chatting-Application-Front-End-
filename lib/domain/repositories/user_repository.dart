import '../models/user_model.dart';

abstract class UserRepository {
  // Get all users
  Future<List<UserModel>> getAllUsers();
  
  // Get user by ID
  Future<UserModel> getUserById(String id);
  
  // Search users
  Future<List<UserModel>> searchUsers(String query);
  
  // Update user profile
  Future<UserModel> updateUserProfile(UserModel user);
  
  // Update user status (online/offline)
  Future<void> updateUserStatus(String userId, bool isOnline);
}
