import 'package:flutter/material.dart';
import '../services/chat_blocking_service.dart';
import '../core/di/service_locator.dart';
import '../utils/logger.dart';

class BlockedUserIndicator extends StatefulWidget {
  final int otherUserId;
  final Widget child;

  const BlockedUserIndicator({
    super.key,
    required this.otherUserId,
    required this.child,
  });

  @override
  State<BlockedUserIndicator> createState() => _BlockedUserIndicatorState();
}

class _BlockedUserIndicatorState extends State<BlockedUserIndicator> {
  late final ChatBlockingService _chatBlockingService;
  BlockingStatus _blockingStatus = BlockingStatus.none;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chatBlockingService = serviceLocator<ChatBlockingService>();
    _checkBlockingStatus();
  }

  Future<void> _checkBlockingStatus() async {
    try {
      final status = await _chatBlockingService.checkBlockingStatus(widget.otherUserId);
      if (mounted) {
        setState(() {
          _blockingStatus = status;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.e('BlockedUserIndicator', 'Error checking blocking status: $e');
      if (mounted) {
        setState(() {
          _blockingStatus = BlockingStatus.none;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.child;
    }

    final isBlocked = _blockingStatus != BlockingStatus.none;

    if (!isBlocked) {
      return widget.child;
    }

    // Wrap the child with blocked indicator
    return Stack(
      children: [
        // Original child with opacity overlay
        Opacity(
          opacity: 0.6,
          child: widget.child,
        ),
        
        // Blocked indicator overlay
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.block,
                  size: 12,
                  color: Colors.white,
                ),
                const SizedBox(width: 2),
                Text(
                  'Blocked',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
