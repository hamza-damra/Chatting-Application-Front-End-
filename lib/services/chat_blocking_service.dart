import '../domain/repositories/user_blocking_repository.dart';
import '../utils/logger.dart';

enum BlockingStatus {
  none, // No blocking between users
  currentBlocked, // Current user blocked the other user
  blockedBy, // Current user is blocked by the other user
  mutual, // Both users blocked each other
}

class ChatBlockingService {
  final UserBlockingRepository _userBlockingRepository;

  ChatBlockingService(this._userBlockingRepository);

  /// Check the blocking status between current user and another user
  Future<BlockingStatus> checkBlockingStatus(int otherUserId) async {
    try {
      AppLogger.d(
        'ChatBlockingService',
        'Checking blocking status with user: $otherUserId',
      );

      // For now, only check if current user blocked the other user
      // The "blocked by" functionality would require additional backend support
      final currentBlockedOther = await _userBlockingRepository.isUserBlocked(
        otherUserId,
      );

      if (currentBlockedOther) {
        AppLogger.d(
          'ChatBlockingService',
          'Current user blocked the other user',
        );
        return BlockingStatus.currentBlocked;
      } else {
        AppLogger.d('ChatBlockingService', 'No blocking detected');
        return BlockingStatus.none;
      }
    } catch (e) {
      AppLogger.e('ChatBlockingService', 'Error checking blocking status: $e');
      // Default to no blocking on error to avoid breaking chat functionality
      return BlockingStatus.none;
    }
  }

  /// Get user-friendly message for blocking status
  String getBlockingMessage(BlockingStatus status, String otherUserName) {
    switch (status) {
      case BlockingStatus.none:
        return '';
      case BlockingStatus.currentBlocked:
        return 'You have blocked $otherUserName. Unblock to send messages.';
      case BlockingStatus.blockedBy:
        return '$otherUserName has blocked you. You cannot send messages.';
      case BlockingStatus.mutual:
        return 'You and $otherUserName have blocked each other.';
    }
  }

  /// Check if messaging should be disabled
  bool shouldDisableMessaging(BlockingStatus status) {
    return status != BlockingStatus.none;
  }

  /// Check if unblock option should be shown
  bool shouldShowUnblockOption(BlockingStatus status) {
    return status == BlockingStatus.currentBlocked ||
        status == BlockingStatus.mutual;
  }
}
