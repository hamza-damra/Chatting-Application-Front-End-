import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_auth_service.dart';
import '../utils/url_utils.dart';
import '../utils/logger.dart';
import '../services/spring_boot_push_manager.dart';
import '../services/background_notification_manager.dart';
import '../services/websocket_service.dart' as legacy_ws;
import '../core/di/service_locator.dart';
import '../core/services/websocket_service.dart';

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
      AppLogger.i('ApiAuthProvider', 'Starting logout process...');

      // 1. Logout from the auth service (clears tokens)
      await _authService.logout();

      // 2. Clear user data
      _user = null;
      _error = null;

      // 3. Clear the token from URL utils
      UrlUtils.setAuthToken("");

      // 4. Clean up WebSocket connections
      try {
        final webSocketService = serviceLocator<WebSocketService>();
        await webSocketService.disconnect();
        AppLogger.i('ApiAuthProvider', 'WebSocket disconnected');
      } catch (e) {
        AppLogger.w('ApiAuthProvider', 'Error disconnecting WebSocket: $e');
      }

      // Also clean up legacy WebSocket service
      try {
        final legacyWebSocketService =
            serviceLocator<legacy_ws.WebSocketService>();
        await legacyWebSocketService.disconnect();
        AppLogger.i('ApiAuthProvider', 'Legacy WebSocket disconnected');
      } catch (e) {
        AppLogger.w(
          'ApiAuthProvider',
          'Error disconnecting legacy WebSocket: $e',
        );
      }

      // 5. Clean up push notifications and background services
      try {
        await SpringBootPushManager.cleanup();
        AppLogger.i('ApiAuthProvider', 'Push notifications cleaned up');
      } catch (e) {
        AppLogger.w(
          'ApiAuthProvider',
          'Error cleaning up push notifications: $e',
        );
      }

      // 6. Clean up background notification manager
      try {
        BackgroundNotificationManager.instance.dispose();
        AppLogger.i(
          'ApiAuthProvider',
          'Background notification manager disposed',
        );
      } catch (e) {
        AppLogger.w(
          'ApiAuthProvider',
          'Error disposing background notification manager: $e',
        );
      }

      AppLogger.i('ApiAuthProvider', 'Logout completed successfully');
    } catch (e) {
      _error = e.toString();
      AppLogger.e('ApiAuthProvider', 'Logout error: $e');
    } finally {
      _isLoading = false;
      // Ensure listeners are notified after logout to trigger UI updates
      notifyListeners();

      // Add a small delay to ensure all cleanup is complete
      await Future.delayed(const Duration(milliseconds: 100));

      AppLogger.i(
        'ApiAuthProvider',
        'Logout state updated, isAuthenticated: $isAuthenticated',
      );

      // Force another notification to ensure UI updates
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

  // Upload profile image (for users without existing profile image)
  Future<bool> uploadProfileImage({required File imageFile}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.uploadProfileImage(imageFile: imageFile);

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

  // Update profile image (for users with existing profile image)
  Future<bool> updateProfileImage({required File imageFile}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.updateProfileImage(imageFile: imageFile);

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

  // Upload or update profile image (smart method that chooses the right endpoint)
  Future<bool> setProfileImage({required File imageFile}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppLogger.i('ApiAuthProvider', 'setProfileImage called');
      AppLogger.d(
        'ApiAuthProvider',
        'Current user profile picture: ${_user?.profilePicture}',
      );

      // Use correct endpoint based on whether user already has a profile picture
      if (_user?.profilePicture != null && _user!.profilePicture!.isNotEmpty) {
        AppLogger.i(
          'ApiAuthProvider',
          'User has existing profile picture, using UPDATE endpoint (PUT)',
        );
        _user = await _authService.updateProfileImage(imageFile: imageFile);
      } else {
        AppLogger.i(
          'ApiAuthProvider',
          'User has no profile picture, using UPLOAD endpoint (POST)',
        );
        _user = await _authService.uploadProfileImage(imageFile: imageFile);
      }

      // Update the URL utils with the token
      _updateUrlToken();

      AppLogger.i(
        'ApiAuthProvider',
        'Profile image operation completed successfully',
      );
      return true;
    } catch (e) {
      AppLogger.e('ApiAuthProvider', 'Profile image operation failed: $e');
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
