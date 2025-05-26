import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/repositories/user_blocking_repository.dart';
import '../../../domain/models/blocked_user_model.dart';
import '../../../utils/logger.dart';

// Events
abstract class UserBlockingEvent extends Equatable {
  const UserBlockingEvent();

  @override
  List<Object?> get props => [];
}

class BlockUser extends UserBlockingEvent {
  final int userId;
  final String? reason;

  const BlockUser(this.userId, {this.reason});

  @override
  List<Object?> get props => [userId, reason];
}

class UnblockUser extends UserBlockingEvent {
  final int userId;

  const UnblockUser(this.userId);

  @override
  List<Object> get props => [userId];
}

class LoadBlockedUsers extends UserBlockingEvent {}

class CheckUserBlockStatus extends UserBlockingEvent {
  final int userId;

  const CheckUserBlockStatus(this.userId);

  @override
  List<Object> get props => [userId];
}

class LoadBlockedUsersCount extends UserBlockingEvent {}

class RefreshBlockedUsers extends UserBlockingEvent {}

// States
abstract class UserBlockingState extends Equatable {
  const UserBlockingState();

  @override
  List<Object?> get props => [];
}

class UserBlockingInitial extends UserBlockingState {}

class UserBlockingLoading extends UserBlockingState {}

class UserBlockingActionLoading extends UserBlockingState {
  final String action; // 'blocking', 'unblocking', 'checking'
  final int? userId;

  const UserBlockingActionLoading(this.action, {this.userId});

  @override
  List<Object?> get props => [action, userId];
}

class UserBlocked extends UserBlockingState {
  final BlockedUserModel blockedUser;

  const UserBlocked(this.blockedUser);

  @override
  List<Object> get props => [blockedUser];
}

class UserUnblocked extends UserBlockingState {
  final int userId;

  const UserUnblocked(this.userId);

  @override
  List<Object> get props => [userId];
}

class BlockedUsersLoaded extends UserBlockingState {
  final List<BlockedUserModel> blockedUsers;

  const BlockedUsersLoaded(this.blockedUsers);

  @override
  List<Object> get props => [blockedUsers];
}

class UserBlockStatusChecked extends UserBlockingState {
  final int userId;
  final bool isBlocked;

  const UserBlockStatusChecked(this.userId, this.isBlocked);

  @override
  List<Object> get props => [userId, isBlocked];
}

class BlockedUsersCountLoaded extends UserBlockingState {
  final int count;

  const BlockedUsersCountLoaded(this.count);

  @override
  List<Object> get props => [count];
}

class UserBlockingFailure extends UserBlockingState {
  final String message;
  final String? action;

  const UserBlockingFailure(this.message, {this.action});

  @override
  List<Object?> get props => [message, action];
}

// Bloc
class UserBlockingBloc extends Bloc<UserBlockingEvent, UserBlockingState> {
  final UserBlockingRepository _userBlockingRepository;

  UserBlockingBloc(this._userBlockingRepository)
    : super(UserBlockingInitial()) {
    on<BlockUser>(_onBlockUser);
    on<UnblockUser>(_onUnblockUser);
    on<LoadBlockedUsers>(_onLoadBlockedUsers);
    on<CheckUserBlockStatus>(_onCheckUserBlockStatus);
    on<LoadBlockedUsersCount>(_onLoadBlockedUsersCount);
    on<RefreshBlockedUsers>(_onRefreshBlockedUsers);
  }

  Future<void> _onBlockUser(
    BlockUser event,
    Emitter<UserBlockingState> emit,
  ) async {
    try {
      AppLogger.i(
        'UserBlockingBloc',
        'Starting to block user: ${event.userId}',
      );
      emit(UserBlockingActionLoading('blocking', userId: event.userId));

      final blockedUser = await _userBlockingRepository.blockUser(
        event.userId,
        reason: event.reason,
      );

      AppLogger.i(
        'UserBlockingBloc',
        'User blocked successfully: ${event.userId}',
      );
      emit(UserBlocked(blockedUser));

      // Refresh the blocked users list if it was previously loaded
      if (state is BlockedUsersLoaded) {
        add(LoadBlockedUsers());
      }
    } catch (e) {
      AppLogger.e('UserBlockingBloc', 'Error blocking user: $e');
      emit(UserBlockingFailure(e.toString(), action: 'blocking'));
    }
  }

  Future<void> _onUnblockUser(
    UnblockUser event,
    Emitter<UserBlockingState> emit,
  ) async {
    try {
      emit(UserBlockingActionLoading('unblocking', userId: event.userId));

      await _userBlockingRepository.unblockUser(event.userId);

      emit(UserUnblocked(event.userId));

      // Refresh the blocked users list if it was previously loaded
      if (state is BlockedUsersLoaded) {
        add(LoadBlockedUsers());
      }
    } catch (e) {
      AppLogger.e('UserBlockingBloc', 'Error unblocking user: $e');
      emit(UserBlockingFailure(e.toString(), action: 'unblocking'));
    }
  }

  Future<void> _onLoadBlockedUsers(
    LoadBlockedUsers event,
    Emitter<UserBlockingState> emit,
  ) async {
    try {
      emit(UserBlockingLoading());

      final blockedUsers = await _userBlockingRepository.getBlockedUsers();

      emit(BlockedUsersLoaded(blockedUsers));
    } catch (e) {
      AppLogger.e('UserBlockingBloc', 'Error loading blocked users: $e');
      emit(UserBlockingFailure(e.toString(), action: 'loading'));
    }
  }

  Future<void> _onCheckUserBlockStatus(
    CheckUserBlockStatus event,
    Emitter<UserBlockingState> emit,
  ) async {
    try {
      AppLogger.i(
        'UserBlockingBloc',
        'Checking block status for user: ${event.userId}',
      );
      emit(UserBlockingActionLoading('checking', userId: event.userId));

      final isBlocked = await _userBlockingRepository.isUserBlocked(
        event.userId,
      );

      AppLogger.i(
        'UserBlockingBloc',
        'Block status checked for user ${event.userId}: $isBlocked',
      );
      emit(UserBlockStatusChecked(event.userId, isBlocked));
    } catch (e) {
      AppLogger.e('UserBlockingBloc', 'Error checking user block status: $e');
      emit(UserBlockingFailure(e.toString(), action: 'checking'));
    }
  }

  Future<void> _onLoadBlockedUsersCount(
    LoadBlockedUsersCount event,
    Emitter<UserBlockingState> emit,
  ) async {
    try {
      final count = await _userBlockingRepository.getBlockedUsersCount();
      emit(BlockedUsersCountLoaded(count));
    } catch (e) {
      AppLogger.e('UserBlockingBloc', 'Error loading blocked users count: $e');
      emit(UserBlockingFailure(e.toString(), action: 'counting'));
    }
  }

  Future<void> _onRefreshBlockedUsers(
    RefreshBlockedUsers event,
    Emitter<UserBlockingState> emit,
  ) async {
    // Don't show loading state for refresh, just update the data
    try {
      final blockedUsers = await _userBlockingRepository.getBlockedUsers();
      emit(BlockedUsersLoaded(blockedUsers));
    } catch (e) {
      AppLogger.e('UserBlockingBloc', 'Error refreshing blocked users: $e');
      emit(UserBlockingFailure(e.toString(), action: 'refreshing'));
    }
  }
}
