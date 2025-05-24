import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/api_config.dart';
import '../../core/services/token_service.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/websocket_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../data/repositories/chat_room_repository_impl.dart';
import '../../data/repositories/message_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/repositories/chat_room_repository.dart';
import '../../domain/repositories/message_repository.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/users/user_bloc.dart';
import '../../presentation/blocs/chat/chat_bloc.dart';
import '../../presentation/blocs/messages/message_bloc.dart';
import '../../services/api_auth_service.dart';
import '../../services/api_chat_service.dart';
import '../../services/websocket_service.dart' as legacy_ws;

final serviceLocator = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Core Services
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  serviceLocator.registerLazySingleton<Dio>(() => dio);
  serviceLocator.registerLazySingleton<TokenService>(() => TokenService(dio));
  serviceLocator.registerLazySingleton<ApiService>(
    () => ApiService(serviceLocator<Dio>(), serviceLocator<TokenService>()),
  );
  serviceLocator.registerLazySingleton<StorageService>(() => StorageService());
  serviceLocator.registerLazySingleton<AuthService>(
    () => AuthService(serviceLocator<Dio>(), serviceLocator<TokenService>()),
  );
  serviceLocator.registerLazySingleton<WebSocketService>(
    () => WebSocketService(serviceLocator<TokenService>()),
  );

  // Legacy Services (needed for backward compatibility)
  serviceLocator.registerLazySingleton<ApiAuthService>(
    () => ApiAuthService(tokenService: serviceLocator<TokenService>()),
  );
  serviceLocator.registerLazySingleton<ApiChatService>(
    () => ApiChatService(tokenService: serviceLocator<TokenService>()),
  );
  serviceLocator.registerLazySingleton<legacy_ws.WebSocketService>(
    () => legacy_ws.WebSocketService(
      tokenService: serviceLocator<TokenService>(),
    ),
  );

  // Repositories
  serviceLocator.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      serviceLocator<ApiService>(),
      serviceLocator<StorageService>(),
      serviceLocator<AuthService>(),
    ),
  );
  serviceLocator.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(serviceLocator<ApiService>()),
  );
  serviceLocator.registerLazySingleton<ChatRoomRepository>(
    () => ChatRoomRepositoryImpl(serviceLocator<ApiService>()),
  );
  serviceLocator.registerLazySingleton<MessageRepository>(
    () => MessageRepositoryImpl(
      serviceLocator<ApiService>(),
      serviceLocator<WebSocketService>(),
    ),
  );

  // BLoCs
  serviceLocator.registerFactory<AuthBloc>(
    () => AuthBloc(serviceLocator<AuthRepository>()),
  );
  serviceLocator.registerFactory<UserBloc>(
    () => UserBloc(serviceLocator<UserRepository>()),
  );
  serviceLocator.registerFactory<ChatBloc>(
    () => ChatBloc(
      serviceLocator<ChatRoomRepository>(),
      serviceLocator<AuthRepository>(),
    ),
  );
  serviceLocator.registerFactory<MessageBloc>(
    () => MessageBloc(serviceLocator<MessageRepository>()),
  );
}

List<BlocProvider> getBlocProviders() {
  return [
    BlocProvider<AuthBloc>(create: (context) => serviceLocator<AuthBloc>()),
    BlocProvider<UserBloc>(create: (context) => serviceLocator<UserBloc>()),
    BlocProvider<ChatBloc>(create: (context) => serviceLocator<ChatBloc>()),
    BlocProvider<MessageBloc>(
      create: (context) => serviceLocator<MessageBloc>(),
    ),
  ];
}
