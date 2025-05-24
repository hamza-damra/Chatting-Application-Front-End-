import 'package:equatable/equatable.dart';
import '../../../domain/models/user_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

// Check if the user is already authenticated
class AuthCheckRequested extends AuthEvent {}

// User logged in
class AuthLoggedIn extends AuthEvent {
  final UserModel user;

  const AuthLoggedIn(this.user);

  @override
  List<Object?> get props => [user];
}

// User logged out
class AuthLoggedOut extends AuthEvent {}

// Login with username/email and password
class AuthLoginRequested extends AuthEvent {
  final String usernameOrEmail;
  final String password;

  const AuthLoginRequested({
    required this.usernameOrEmail,
    required this.password,
  });

  @override
  List<Object?> get props => [usernameOrEmail, password];
}

// Register a new user
class AuthRegisterRequested extends AuthEvent {
  final String username;
  final String email;
  final String password;
  final String fullName;

  const AuthRegisterRequested({
    required this.username,
    required this.email,
    required this.password,
    required this.fullName,
  });

  @override
  List<Object?> get props => [username, email, password, fullName];
}
