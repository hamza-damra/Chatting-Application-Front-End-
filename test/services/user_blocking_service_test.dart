import 'package:flutter_test/flutter_test.dart';
import 'package:vector/domain/models/blocked_user_model.dart';
import 'package:vector/domain/models/user_model.dart';

void main() {
  group('BlockedUserModel', () {
    test('should create BlockedUserModel from JSON', () {
      // Arrange
      final userJson = {
        'id': 123,
        'username': 'testuser',
        'email': 'test@example.com',
        'fullName': 'Test User',
        'profilePicture': null,
        'isOnline': false,
        'role': 'user',
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-01T00:00:00.000Z',
      };

      final blockedUserJson = {
        'id': 1,
        'blockedUser': userJson,
        'blockedAt': '2024-01-15T10:30:00.000Z',
        'reason': 'Inappropriate behavior',
      };

      // Act
      final blockedUser = BlockedUserModel.fromJson(blockedUserJson);

      // Assert
      expect(blockedUser.id, equals(1));
      expect(blockedUser.blockedUser.id, equals(123));
      expect(blockedUser.blockedUser.username, equals('testuser'));
      expect(blockedUser.reason, equals('Inappropriate behavior'));
    });

    test('should convert BlockedUserModel to JSON', () {
      // Arrange
      final user = UserModel(
        id: 123,
        username: 'testuser',
        email: 'test@example.com',
        fullName: 'Test User',
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      );

      final blockedUser = BlockedUserModel(
        id: 1,
        blockedUser: user,
        blockedAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
        reason: 'Inappropriate behavior',
      );

      // Act
      final json = blockedUser.toJson();

      // Assert
      expect(json['id'], equals(1));
      expect(json['blockedUser']['id'], equals(123));
      expect(json['reason'], equals('Inappropriate behavior'));
    });
  });

  group('BlockUserRequest', () {
    test('should create BlockUserRequest and convert to JSON', () {
      // Arrange
      const request = BlockUserRequest(userId: 123, reason: 'Spam messages');

      // Act
      final json = request.toJson();

      // Assert
      expect(json['userId'], equals(123));
      expect(json['reason'], equals('Spam messages'));
    });

    test('should handle null reason', () {
      // Arrange
      const request = BlockUserRequest(userId: 123);

      // Act
      final json = request.toJson();

      // Assert
      expect(json['userId'], equals(123));
      expect(json['reason'], isNull);
    });
  });

  group('BlockStatusResponse', () {
    test('should create BlockStatusResponse from JSON', () {
      // Arrange
      final json = {'isBlocked': true};

      // Act
      final response = BlockStatusResponse.fromJson(json);

      // Assert
      expect(response.isBlocked, isTrue);
    });
  });

  group('BlockedUsersCountResponse', () {
    test('should create BlockedUsersCountResponse from JSON', () {
      // Arrange
      final json = {'blockedUsersCount': 5};

      // Act
      final response = BlockedUsersCountResponse.fromJson(json);

      // Assert
      expect(response.blockedUsersCount, equals(5));
    });
  });
}
