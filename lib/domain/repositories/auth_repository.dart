import '../models/user_model.dart';

abstract class AuthRepository {
  // Check if user is authenticated
  Future<bool> isAuthenticated();
  
  // Get current user
  Future<UserModel?> getCurrentUser();
  
  // Login user
  Future<UserModel> login(String usernameOrEmail, String password);
  
  // Register user
  Future<UserModel> register(String username, String email, String password, String fullName);
  
  // Logout user
  Future<void> logout();
}
