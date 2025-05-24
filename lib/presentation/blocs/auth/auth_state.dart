import 'package:equatable/equatable.dart';
import '../../../domain/models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

// Initial state when the app starts
class AuthInitial extends AuthState {}

// Checking if the user is authenticated
class AuthLoading extends AuthState {}

// User is authenticated
class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

// User is not authenticated
class AuthUnauthenticated extends AuthState {}

// Authentication failed
class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}
