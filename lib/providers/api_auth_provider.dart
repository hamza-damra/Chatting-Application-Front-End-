import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_auth_service.dart';
import '../utils/url_utils.dart';
import '../utils/logger.dart';

class ApiAuthProvider with ChangeNotifier {
  final ApiAuthService _authService;

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _authService.isAuthenticated;

  // Constructor
  ApiAuthProvider({required ApiAuthService authService})
    : _authService = authService {
    _init();
  }

  // Initialize the provider
  Future<void> _init() async {
    if (_authService.isAuthenticated) {
      await _fetchCurrentUser();
      // Set the token for image URLs
      _updateUrlToken();
    }
  }

  // Update the URL utils with the current token
  void _updateUrlToken() {
    final token = _authService.getAccessToken();
    if (token != null) {
      UrlUtils.setAuthToken(token);
      AppLogger.i('ApiAuthProvider', 'Updated UrlUtils with new token');
    }
  }

  // Fetch current user data
  Future<void> _fetchCurrentUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _authService.getCurrentUser();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register with username, email, and password
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.register(
        username: username,
        email: email,
        password: password,
        fullName: fullName,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login with username/email and password
  Future<bool> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.login(
        usernameOrEmail: usernameOrEmail,
        password: password,
      );

      // Update the URL utils with the token
      _updateUrlToken();

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _user = null;
      _error = null;

      // Clear the token from URL utils
      UrlUtils.setAuthToken("");
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    required String fullName,
    String? profilePicture,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.updateUserProfile(
        fullName: fullName,
        profilePicture: profilePicture,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
