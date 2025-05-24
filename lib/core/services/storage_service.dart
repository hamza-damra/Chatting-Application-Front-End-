import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/logger.dart';

class StorageService {
  static const String _userDataKey = 'user_data';
  
  // Save user data
  Future<void> saveUserData(String userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userDataKey, userData);
    } catch (e) {
      AppLogger.e('StorageService', 'Error saving user data: $e');
      rethrow;
    }
  }
  
  // Get user data
  Future<String?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userDataKey);
    } catch (e) {
      AppLogger.e('StorageService', 'Error getting user data: $e');
      return null;
    }
  }
  
  // Clear user data
  Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userDataKey);
    } catch (e) {
      AppLogger.e('StorageService', 'Error clearing user data: $e');
      rethrow;
    }
  }
  
  // Clear all data including tokens
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      AppLogger.e('StorageService', 'Error clearing all data: $e');
      rethrow;
    }
  }
  
  // Save a value with a specific key
  Future<void> saveValue(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      AppLogger.e('StorageService', 'Error saving value: $e');
      rethrow;
    }
  }
  
  // Get a value with a specific key
  Future<String?> getValue(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      AppLogger.e('StorageService', 'Error getting value: $e');
      return null;
    }
  }
  
  // Remove a value with a specific key
  Future<void> removeValue(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (e) {
      AppLogger.e('StorageService', 'Error removing value: $e');
      rethrow;
    }
  }
}
