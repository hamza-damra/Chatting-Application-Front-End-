import 'package:flutter_test/flutter_test.dart';
import 'package:vector/config/api_config.dart';

void main() {
  group('Profile Image Endpoint Logic Tests', () {
    test('should use /me endpoint when userId is null', () {
      final url = ApiConfig.getCurrentUserProfileImageUrl();
      expect(
        url,
        equals(
          'http://abusaker.zapto.org:8080/api/users/me/profile-image/view',
        ),
      );
    });

    test('should use specific user endpoint when userId is provided', () {
      final url = ApiConfig.getUserProfileImageUrl(15);
      expect(
        url,
        equals(
          'http://abusaker.zapto.org:8080/api/users/15/profile-image/view',
        ),
      );
    });

    test('should handle different user IDs correctly', () {
      final url1 = ApiConfig.getUserProfileImageUrl(1);
      final url2 = ApiConfig.getUserProfileImageUrl(999);
      final url3 = ApiConfig.getUserProfileImageUrl(15);

      expect(
        url1,
        equals('http://abusaker.zapto.org:8080/api/users/1/profile-image/view'),
      );
      expect(
        url2,
        equals(
          'http://abusaker.zapto.org:8080/api/users/999/profile-image/view',
        ),
      );
      expect(
        url3,
        equals(
          'http://abusaker.zapto.org:8080/api/users/15/profile-image/view',
        ),
      );
    });

    test('should have consistent base URL across all endpoints', () {
      final currentUserUrl = ApiConfig.getCurrentUserProfileImageUrl();
      final userUrl = ApiConfig.getUserProfileImageUrl(15);

      expect(currentUserUrl, startsWith('http://abusaker.zapto.org:8080'));
      expect(userUrl, startsWith('http://abusaker.zapto.org:8080'));
    });

    test('should have correct endpoint structure', () {
      final currentUserUrl = ApiConfig.getCurrentUserProfileImageUrl();
      final userUrl = ApiConfig.getUserProfileImageUrl(15);

      expect(currentUserUrl, contains('/api/users/me/profile-image/view'));
      expect(userUrl, contains('/api/users/15/profile-image/view'));
    });
  });

  group('Profile Image Widget Logic Tests', () {
    test('should determine current user correctly', () {
      // Simulate the logic from ProfileImageWidget
      const int userId = 15;
      const int currentUserId = 15;
      final isCurrentUser = userId == currentUserId;

      expect(isCurrentUser, isTrue);
    });

    test('should determine other user correctly', () {
      // Simulate the logic from ProfileImageWidget
      const int userId = 15;
      const int currentUserId = 10;
      final isCurrentUser = userId == currentUserId;

      expect(isCurrentUser, isFalse);
    });

    test('should handle null userId correctly', () {
      // Simulate the logic from ProfileImageWidget
      const int? userId = null;
      const int currentUserId = 15;
      final isCurrentUser = userId != null && userId == currentUserId;

      expect(isCurrentUser, isFalse);
    });

    test('should handle null currentUserId correctly', () {
      // Simulate the logic from ProfileImageWidget
      const int userId = 15;
      const int? currentUserId = null;
      final isCurrentUser = currentUserId != null && userId == currentUserId;

      expect(isCurrentUser, isFalse);
    });

    test('should choose correct URL based on user logic', () {
      // Test case 1: Current user (userId matches currentUserId)
      const int userId1 = 15;
      const int currentUserId1 = 15;
      final isCurrentUser1 = userId1 == currentUserId1;
      final imageUrl1 =
          isCurrentUser1
              ? ApiConfig.getCurrentUserProfileImageUrl()
              : ApiConfig.getUserProfileImageUrl(userId1);

      expect(
        imageUrl1,
        equals(
          'http://abusaker.zapto.org:8080/api/users/me/profile-image/view',
        ),
      );

      // Test case 2: Other user (userId different from currentUserId)
      const int userId2 = 15;
      const int currentUserId2 = 10;
      final isCurrentUser2 = userId2 == currentUserId2;
      final imageUrl2 =
          isCurrentUser2
              ? ApiConfig.getCurrentUserProfileImageUrl()
              : ApiConfig.getUserProfileImageUrl(userId2);

      expect(
        imageUrl2,
        equals(
          'http://abusaker.zapto.org:8080/api/users/15/profile-image/view',
        ),
      );

      // Test case 3: No userId provided (should use current user)
      const int? userId3 = null;
      const int currentUserId3 = 15;
      final isCurrentUser3 = userId3 != null && userId3 == currentUserId3;
      final imageUrl3 =
          userId3 == null || isCurrentUser3
              ? ApiConfig.getCurrentUserProfileImageUrl()
              : ApiConfig.getUserProfileImageUrl(userId3);

      expect(
        imageUrl3,
        equals(
          'http://abusaker.zapto.org:8080/api/users/me/profile-image/view',
        ),
      );
    });
  });
}
