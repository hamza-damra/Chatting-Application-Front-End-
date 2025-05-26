import 'package:equatable/equatable.dart';
import 'user_model.dart';

class BlockedUserModel extends Equatable {
  final int id;
  final UserModel blockedUser;
  final DateTime blockedAt;
  final String? reason;

  const BlockedUserModel({
    required this.id,
    required this.blockedUser,
    required this.blockedAt,
    this.reason,
  });

  factory BlockedUserModel.fromJson(Map<String, dynamic> json) {
    return BlockedUserModel(
      id: json['id'] as int,
      blockedUser: UserModel.fromJson(json['blockedUser'] as Map<String, dynamic>),
      blockedAt: DateTime.parse(json['blockedAt'] as String),
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'blockedUser': blockedUser.toJson(),
      'blockedAt': blockedAt.toIso8601String(),
      'reason': reason,
    };
  }

  BlockedUserModel copyWith({
    int? id,
    UserModel? blockedUser,
    DateTime? blockedAt,
    String? reason,
  }) {
    return BlockedUserModel(
      id: id ?? this.id,
      blockedUser: blockedUser ?? this.blockedUser,
      blockedAt: blockedAt ?? this.blockedAt,
      reason: reason ?? this.reason,
    );
  }

  @override
  List<Object?> get props => [id, blockedUser, blockedAt, reason];
}

class BlockUserRequest extends Equatable {
  final int userId;
  final String? reason;

  const BlockUserRequest({
    required this.userId,
    this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'reason': reason,
    };
  }

  @override
  List<Object?> get props => [userId, reason];
}

class BlockStatusResponse extends Equatable {
  final bool isBlocked;

  const BlockStatusResponse({
    required this.isBlocked,
  });

  factory BlockStatusResponse.fromJson(Map<String, dynamic> json) {
    return BlockStatusResponse(
      isBlocked: json['isBlocked'] as bool,
    );
  }

  @override
  List<Object> get props => [isBlocked];
}

class BlockedUsersCountResponse extends Equatable {
  final int blockedUsersCount;

  const BlockedUsersCountResponse({
    required this.blockedUsersCount,
  });

  factory BlockedUsersCountResponse.fromJson(Map<String, dynamic> json) {
    return BlockedUsersCountResponse(
      blockedUsersCount: json['blockedUsersCount'] as int,
    );
  }

  @override
  List<Object> get props => [blockedUsersCount];
}
