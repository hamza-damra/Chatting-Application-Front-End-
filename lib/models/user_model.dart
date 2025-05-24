import 'package:equatable/equatable.dart';

enum UserRole { user, admin }

class UserModel extends Equatable {
  final int id;
  final String username;
  final String email;
  final String fullName;
  final String? profilePicture;
  final bool isOnline;
  final DateTime? lastSeen;
  final UserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    this.profilePicture,
    this.isOnline = false,
    this.lastSeen,
    this.role = UserRole.user,
    required this.createdAt,
    required this.updatedAt,
  });

  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? fullName,
    String? profilePicture,
    bool? isOnline,
    DateTime? lastSeen,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      profilePicture: profilePicture ?? this.profilePicture,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fullName': fullName,
      'profilePicture': profilePicture,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'role': role.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      username: map['username'],
      email: map['email'],
      fullName: map['fullName'],
      profilePicture: map['profilePicture'],
      isOnline: map['isOnline'] ?? map['online'] ?? false,
      lastSeen:
          map['lastSeen'] != null ? DateTime.parse(map['lastSeen']) : null,
      role:
          map['role'] != null
              ? UserRole.values.firstWhere(
                (e) => e.toString().split('.').last == map['role'],
                orElse: () => UserRole.user,
              )
              : UserRole.user,
      createdAt:
          map['createdAt'] != null
              ? DateTime.parse(map['createdAt'])
              : DateTime.now(),
      updatedAt:
          map['updatedAt'] != null
              ? DateTime.parse(map['updatedAt'])
              : DateTime.now(),
    );
  }

  // Alias methods for backward compatibility
  Map<String, dynamic> toJson() => toMap();
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      UserModel.fromMap(json);

  @override
  List<Object?> get props => [
    id,
    username,
    email,
    fullName,
    profilePicture,
    isOnline,
    lastSeen,
    role,
    createdAt,
    updatedAt,
  ];
}
