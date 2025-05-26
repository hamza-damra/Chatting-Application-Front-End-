import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

// Import existing providers for backward compatibility
import 'core/services/token_service.dart';
import 'services/api_auth_service.dart';
import 'services/api_chat_service.dart';
import 'services/websocket_service.dart' as legacy_ws;
import 'services/improved_file_upload_service.dart';
import 'services/api_file_service.dart';
import 'services/improved_chat_service.dart';
import 'config/api_config.dart';
import 'providers/api_auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/user_status_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/notification_provider.dart';
import 'services/notification_service.dart';
import 'services/navigation_service.dart';
import 'services/background_notification_manager.dart';

import 'services/connectivity_service.dart';
import 'utils/url_utils.dart';
import 'utils/logger.dart';

// Import new architecture components
import 'core/di/service_locator.dart';
import 'core/routes/app_router.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/blocs/auth/auth_state.dart';

// Import screens and routes
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';

import 'custom_routes.dart';

// Widgets
import 'widgets/shimmer_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize service locator
    setupServiceLocator();

    // Get the token service from service locator and initialize it
    final tokenService = serviceLocator<TokenService>();
    await tokenService.init();

    // Initialize URL utils with the token
    if (tokenService.accessToken != null) {
      UrlUtils.setAuthToken(tokenService.accessToken!);
    }

    // Initialize notification service
    await NotificationService.initialize();

    // Initialize background notification manager
    await BackgroundNotificationManager.initialize();

    // Initialize connectivity monitoring
    await ConnectivityService.instance.initialize();

    AppLogger.i('Main', 'Application initialized successfully');

    runApp(MyApp(tokenService: tokenService));
  } catch (e) {
    AppLogger.e('Main', 'Failed to initialize application: $e');

    // Show a basic error app if initialization fails
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Failed to start the application',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please restart the app or contact support',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  final TokenService tokenService;

  const MyApp({super.key, required this.tokenService});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ConnectivityService.instance.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground, check connectivity
        ConnectivityService.instance.checkConnectivity();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // App going to background or being terminated
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get services from service locator
    final apiAuthService = serviceLocator<ApiAuthService>();
    final apiChatService = serviceLocator<ApiChatService>();
    final webSocketService = serviceLocator<legacy_ws.WebSocketService>();

    return MultiBlocProvider(
      providers: getBlocProviders(),
      child: MultiProvider(
        providers: [
          // Provide TokenService for authenticated image loading
          Provider<TokenService>.value(value: widget.tokenService),
          // Keep old providers for backward compatibility
          ChangeNotifierProvider(
            create: (_) => ApiAuthProvider(authService: apiAuthService),
          ),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
          ChangeNotifierProvider(
            create: (context) {
              final chatProvider = ChatProvider(
                chatService: apiChatService,
                webSocketService: webSocketService,
                authProvider: Provider.of<ApiAuthProvider>(
                  context,
                  listen: false,
                ),
              );

              // Connect ChatProvider with NotificationProvider
              final notificationProvider = Provider.of<NotificationProvider>(
                context,
                listen: false,
              );
              chatProvider.setNotificationCallback(
                notificationProvider.addNotification,
              );

              return chatProvider;
            },
          ),
          ChangeNotifierProvider(
            create:
                (_) => UserStatusProvider(webSocketService: webSocketService),
          ),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          // Provide WebSocketService directly for direct access
          Provider<legacy_ws.WebSocketService>.value(value: webSocketService),
          // Provide ImprovedFileUploadService
          Provider<ImprovedFileUploadService>(
            create:
                (_) => ImprovedFileUploadService(
                  baseUrl: ApiConfig.baseUrl,
                  headers: ApiConfig.getAuthHeaders(
                    widget.tokenService.accessToken ?? '',
                  ),
                  webSocketService: webSocketService,
                ),
          ),
          // Provide new REST API file service
          Provider<ApiFileService>(
            create: (_) => ApiFileService(tokenService: widget.tokenService),
          ),
          // Provide improved chat service
          Provider<ImprovedChatService>(
            create:
                (context) => ImprovedChatService(
                  fileService: Provider.of<ApiFileService>(
                    context,
                    listen: false,
                  ),
                  webSocketService: webSocketService,
                ),
          ),
        ],
        child: Consumer<ThemeProvider>(
          builder:
              (context, themeProvider, _) => MaterialApp(
                title: 'Chat App',
                debugShowCheckedModeBanner: false,
                navigatorKey: NavigationService.navigatorKey,
                theme: themeProvider.lightTheme,
                darkTheme: themeProvider.darkTheme,
                themeMode: themeProvider.themeMode,
                home: const AuthWrapper(),
                onGenerateRoute: (settings) {
                  // Check custom routes first
                  if (settings.name?.startsWith('/') == true) {
                    return CustomRoutes.generateRoute(settings);
                  }
                  // Fall back to app router
                  return AppRouter.generateRoute(settings);
                },
              ),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Handle app lifecycle changes for background notifications
    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      default:
        break;
    }
  }

  void _handleAppResumed() {
    // App came to foreground
    // Update background notification manager
    // This will be handled by the BackgroundNotificationManager's observer
  }

  void _handleAppPaused() {
    // App went to background
    // Ensure background services are running
    _ensureBackgroundServicesRunning();
  }

  void _handleAppDetached() {
    // App is being terminated
    // Background services should continue running
  }

  void _ensureBackgroundServicesRunning() {
    // Get current user info and ensure background services are active
    final authProvider = Provider.of<ApiAuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated && authProvider.user != null) {
      // Get token from the auth service
      final tokenService = serviceLocator<TokenService>();
      final token = tokenService.accessToken ?? '';

      // Update background notification manager with current user
      BackgroundNotificationManager.instance.updateUserAuth(
        userId: authProvider.user!.id.toString(),
        authToken: token,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize auth check
    context.read<AuthBloc>().add(AuthCheckRequested());

    // Listen to auth state changes
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // For backward compatibility, also check the old auth provider
        final authProvider = Provider.of<ApiAuthProvider>(context);

        // Show loading indicator while checking authentication state
        if (state is AuthLoading || authProvider.isLoading) {
          return Scaffold(
            body: Center(child: ShimmerWidgets.authLoadingShimmer()),
          );
        }

        // Navigate to home screen if authenticated, otherwise show login screen
        if (state is AuthAuthenticated || authProvider.isAuthenticated) {
          // Initialize background services for authenticated user
          _initializeBackgroundServicesForUser(authProvider);
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }

  void _initializeBackgroundServicesForUser(ApiAuthProvider authProvider) {
    if (authProvider.isAuthenticated && authProvider.user != null) {
      // Get token from the auth service
      final tokenService = serviceLocator<TokenService>();
      final token = tokenService.accessToken ?? '';

      // Initialize background notification manager with user credentials
      WidgetsBinding.instance.addPostFrameCallback((_) {
        BackgroundNotificationManager.instance.updateUserAuth(
          userId: authProvider.user!.id.toString(),
          authToken: token,
        );
      });
    }
  }
}
