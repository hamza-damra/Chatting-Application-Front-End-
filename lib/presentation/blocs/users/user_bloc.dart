import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../domain/models/user_model.dart';
import '../../../utils/logger.dart';

// Events
abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object> get props => [];
}

class LoadUsers extends UserEvent {}

class LoadUserById extends UserEvent {
  final String userId;

  const LoadUserById(this.userId);

  @override
  List<Object> get props => [userId];
}

class UpdateUserProfile extends UserEvent {
  final UserModel user;

  const UpdateUserProfile(this.user);

  @override
  List<Object> get props => [user];
}

class UpdateUserStatus extends UserEvent {
  final String userId;
  final bool isOnline;

  const UpdateUserStatus({required this.userId, required this.isOnline});

  @override
  List<Object> get props => [userId, isOnline];
}

class SearchUsers extends UserEvent {
  final String query;

  const SearchUsers(this.query);

  @override
  List<Object> get props => [query];
}

// States
abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final UserModel user;

  const UserLoaded(this.user);

  @override
  List<Object> get props => [user];
}

class UsersLoaded extends UserState {
  final List<UserModel> users;

  const UsersLoaded(this.users);

  @override
  List<Object> get props => [users];
}

class UserFailure extends UserState {
  final String error;

  const UserFailure(this.error);

  @override
  List<Object> get props => [error];
}

// Bloc
class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository _userRepository;

  UserBloc(this._userRepository) : super(UserInitial()) {
    on<LoadUsers>(_onLoadUsers);
    on<LoadUserById>(_onLoadUserById);
    on<UpdateUserProfile>(_onUpdateUserProfile);
    on<UpdateUserStatus>(_onUpdateUserStatus);
    on<SearchUsers>(_onSearchUsers);
  }

  Future<void> _onLoadUsers(LoadUsers event, Emitter<UserState> emit) async {
    try {
      emit(UserLoading());
      final users = await _userRepository.getAllUsers();
      emit(UsersLoaded(users));
    } catch (e) {
      AppLogger.e('UserBloc', 'Error loading users: $e');
      emit(UserFailure(e.toString()));
    }
  }

  Future<void> _onLoadUserById(
    LoadUserById event,
    Emitter<UserState> emit,
  ) async {
    try {
      emit(UserLoading());
      final user = await _userRepository.getUserById(event.userId);
      emit(UserLoaded(user));
    } catch (e) {
      AppLogger.e('UserBloc', 'Error loading user by ID: $e');
      emit(UserFailure(e.toString()));
    }
  }

  Future<void> _onUpdateUserProfile(
    UpdateUserProfile event,
    Emitter<UserState> emit,
  ) async {
    try {
      emit(UserLoading());
      final user = await _userRepository.updateUserProfile(event.user);
      emit(UserLoaded(user));
    } catch (e) {
      AppLogger.e('UserBloc', 'Error updating user profile: $e');
      emit(UserFailure(e.toString()));
    }
  }

  Future<void> _onUpdateUserStatus(
    UpdateUserStatus event,
    Emitter<UserState> emit,
  ) async {
    try {
      await _userRepository.updateUserStatus(event.userId, event.isOnline);
      // Refresh user list if it's currently loaded
      if (state is UsersLoaded) {
        add(LoadUsers());
      }
    } catch (e) {
      // Silently fail, don't update UI for status errors
      AppLogger.w('UserBloc', 'Error updating user status: $e');
    }
  }

  Future<void> _onSearchUsers(
    SearchUsers event,
    Emitter<UserState> emit,
  ) async {
    try {
      emit(UserLoading());
      final users = await _userRepository.searchUsers(event.query);
      emit(UsersLoaded(users));
    } catch (e) {
      AppLogger.e('UserBloc', 'Error searching users: $e');
      emit(UserFailure(e.toString()));
    }
  }
}
