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
import 'utils/url_utils.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize service locator
  setupServiceLocator();

  // Get the token service from service locator and initialize it
  final tokenService = serviceLocator<TokenService>();
  await tokenService.init();

  // Initialize URL utils with the token
  if (tokenService.accessToken != null) {
    UrlUtils.setAuthToken(tokenService.accessToken!);
  }

  runApp(MyApp(tokenService: tokenService));
}

class MyApp extends StatelessWidget {
  final TokenService tokenService;

  const MyApp({super.key, required this.tokenService});

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
          Provider<TokenService>.value(value: tokenService),
          // Keep old providers for backward compatibility
          ChangeNotifierProvider(
            create: (_) => ApiAuthProvider(authService: apiAuthService),
          ),
          ChangeNotifierProvider(
            create:
                (context) => ChatProvider(
                  chatService: apiChatService,
                  webSocketService: webSocketService,
                  authProvider: Provider.of<ApiAuthProvider>(
                    context,
                    listen: false,
                  ),
                ),
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
                    tokenService.accessToken ?? '',
                  ),
                  webSocketService: webSocketService,
                ),
          ),
          // Provide new REST API file service
          Provider<ApiFileService>(
            create: (_) => ApiFileService(tokenService: tokenService),
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

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Navigate to home screen if authenticated, otherwise show login screen
        if (state is AuthAuthenticated || authProvider.isAuthenticated) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
