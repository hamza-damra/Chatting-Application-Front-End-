import 'package:flutter_test/flutter_test.dart';
import 'package:vector/config/api_config.dart';

void main() {
  group('Profile Image URL Generation Tests', () {
    test('should generate correct current user profile image URL', () {
      final url = ApiConfig.getCurrentUserProfileImageUrl();
      expect(
        url,
        equals(
          'http://abusaker.zapto.org:8080/api/users/me/profile-image/view',
        ),
      );
    });

    test('should generate correct user profile image URL with userId', () {
      final url = ApiConfig.getUserProfileImageUrl(123);
      expect(
        url,
        equals(
          'http://abusaker.zapto.org:8080/api/users/123/profile-image/view',
        ),
      );
    });

    test('should handle different user IDs correctly', () {
      final url1 = ApiConfig.getUserProfileImageUrl(1);
      final url2 = ApiConfig.getUserProfileImageUrl(999);

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
    });

    test('should use correct base URL', () {
      final currentUserUrl = ApiConfig.getCurrentUserProfileImageUrl();
      final userUrl = ApiConfig.getUserProfileImageUrl(456);

      expect(currentUserUrl, startsWith('http://abusaker.zapto.org:8080'));
      expect(userUrl, startsWith('http://abusaker.zapto.org:8080'));
    });

    test('should have correct endpoint paths', () {
      final currentUserUrl = ApiConfig.getCurrentUserProfileImageUrl();
      final userUrl = ApiConfig.getUserProfileImageUrl(789);

      expect(currentUserUrl, endsWith('/api/users/me/profile-image/view'));
      expect(userUrl, endsWith('/api/users/789/profile-image/view'));
    });
  });
}
