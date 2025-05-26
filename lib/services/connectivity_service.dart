import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/logger.dart';
import 'global_message_service.dart';

/// Service for monitoring network and server connectivity
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  static ConnectivityService get instance => _instance;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _serverCheckTimer;

  bool _isNetworkConnected = true;
  bool _isServerReachable = true;
  bool _hasShownServerError = false;
  bool _hasShownNetworkError = false;

  // Streams for connectivity status
  final StreamController<bool> _networkStatusController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _serverStatusController =
      StreamController<bool>.broadcast();

  Stream<bool> get networkStatusStream => _networkStatusController.stream;
  Stream<bool> get serverStatusStream => _serverStatusController.stream;

  bool get isNetworkConnected => _isNetworkConnected;
  bool get isServerReachable => _isServerReachable;
  bool get isFullyConnected => _isNetworkConnected && _isServerReachable;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    AppLogger.i(
      'ConnectivityService',
      'Initializing connectivity monitoring...',
    );

    // Check initial connectivity
    await _checkInitialConnectivity();

    // Start monitoring network connectivity
    _startNetworkMonitoring();

    // Start monitoring server connectivity
    _startServerMonitoring();

    AppLogger.i('ConnectivityService', 'Connectivity monitoring initialized');
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _serverCheckTimer?.cancel();
    _networkStatusController.close();
    _serverStatusController.close();
  }

  /// Check initial connectivity status
  Future<void> _checkInitialConnectivity() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      _updateNetworkStatus(connectivityResults);

      if (_isNetworkConnected) {
        await _checkServerConnectivity();
      }
    } catch (e) {
      AppLogger.e(
        'ConnectivityService',
        'Error checking initial connectivity: $e',
      );
    }
  }

  /// Start monitoring network connectivity
  void _startNetworkMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _updateNetworkStatus(results);

        if (_isNetworkConnected) {
          // Network is back, check server connectivity
          _checkServerConnectivity();
          _hasShownNetworkError = false;
        } else {
          // Network is lost
          _updateServerStatus(false);
          if (!_hasShownNetworkError) {
            GlobalMessageService.showNetworkError(
              onRetry: () => _checkInitialConnectivity(),
            );
            _hasShownNetworkError = true;
          }
        }
      },
      onError: (error) {
        AppLogger.e('ConnectivityService', 'Network monitoring error: $error');
      },
    );
  }

  /// Start monitoring server connectivity
  void _startServerMonitoring() {
    _serverCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isNetworkConnected) {
        _checkServerConnectivity();
      }
    });
  }

  /// Update network status
  void _updateNetworkStatus(List<ConnectivityResult> results) {
    final wasConnected = _isNetworkConnected;
    _isNetworkConnected =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);

    if (wasConnected != _isNetworkConnected) {
      _networkStatusController.add(_isNetworkConnected);
      AppLogger.i(
        'ConnectivityService',
        'Network status changed: $_isNetworkConnected',
      );
    }
  }

  /// Update server status
  void _updateServerStatus(bool isReachable) {
    final wasReachable = _isServerReachable;
    _isServerReachable = isReachable;

    if (wasReachable != _isServerReachable) {
      _serverStatusController.add(_isServerReachable);
      AppLogger.i(
        'ConnectivityService',
        'Server status changed: $_isServerReachable',
      );

      if (!_isServerReachable && !_hasShownServerError) {
        GlobalMessageService.showServerConnectivityError(
          onRetry: () => _checkServerConnectivity(),
        );
        _hasShownServerError = true;
      } else if (_isServerReachable && _hasShownServerError) {
        GlobalMessageService.showSuccess('Connection restored');
        _hasShownServerError = false;
      }
    }
  }

  /// Check server connectivity
  Future<void> _checkServerConnectivity() async {
    try {
      AppLogger.d('ConnectivityService', 'Checking server connectivity...');

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/health'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      final isReachable =
          response.statusCode == 200 || response.statusCode == 404;
      _updateServerStatus(isReachable);

      AppLogger.d(
        'ConnectivityService',
        'Server check result: $isReachable (status: ${response.statusCode})',
      );
    } catch (e) {
      AppLogger.w(
        'ConnectivityService',
        'Server connectivity check failed: $e',
      );
      _updateServerStatus(false);
    }
  }

  /// Manually check connectivity
  Future<bool> checkConnectivity() async {
    await _checkInitialConnectivity();
    return isFullyConnected;
  }

  /// Check if a specific error is a connectivity error
  static bool isConnectivityError(String error) {
    final connectivityKeywords = [
      'SocketException',
      'Connection refused',
      'Connection failed',
      'No route to host',
      'Host unreachable',
      'Network is unreachable',
      'Connection timed out',
      'Failed to connect',
      'Unable to connect',
      'No internet connection',
      'Network error',
      'ConnectException',
      'ConnectTimeoutException',
      'HttpException',
      'HandshakeException',
    ];

    return connectivityKeywords.any(
      (keyword) => error.toLowerCase().contains(keyword.toLowerCase()),
    );
  }

  /// Handle connectivity error automatically
  static void handleConnectivityError(String error) {
    if (isConnectivityError(error)) {
      if (error.toLowerCase().contains('server') ||
          error.toLowerCase().contains('host') ||
          error.toLowerCase().contains('connection refused')) {
        GlobalMessageService.showServerConnectivityError(
          onRetry: () => ConnectivityService.instance.checkConnectivity(),
        );
      } else {
        GlobalMessageService.showNetworkError(
          onRetry: () => ConnectivityService.instance.checkConnectivity(),
        );
      }
    } else {
      GlobalMessageService.showError(error);
    }
  }
}
