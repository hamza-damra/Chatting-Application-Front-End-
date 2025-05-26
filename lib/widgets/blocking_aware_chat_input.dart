import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../presentation/blocs/user_blocking/user_blocking_bloc.dart';
import '../presentation/widgets/chat/professional_chat_input.dart';
import '../services/chat_blocking_service.dart';
import '../domain/repositories/user_blocking_repository.dart';
import '../core/di/service_locator.dart';
import '../widgets/block_user_button.dart';
import '../utils/logger.dart';

class BlockingAwareChatInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSendMessage;
  final VoidCallback? onAttachmentPressed;
  final Function(String)? onChanged;
  final Function(bool)? onTypingChanged;
  final String hintText;
  final int maxLines;
  final int minLines;
  final int otherUserId;
  final String otherUserName;

  const BlockingAwareChatInput({
    super.key,
    required this.controller,
    required this.onSendMessage,
    required this.otherUserId,
    required this.otherUserName,
    this.onAttachmentPressed,
    this.onChanged,
    this.onTypingChanged,
    this.hintText = 'Type a message...',
    this.maxLines = 6,
    this.minLines = 1,
  });

  @override
  State<BlockingAwareChatInput> createState() => _BlockingAwareChatInputState();
}

class _BlockingAwareChatInputState extends State<BlockingAwareChatInput> {
  late final ChatBlockingService _chatBlockingService;
  BlockingStatus _blockingStatus = BlockingStatus.none;
  bool _isCheckingStatus = true;

  @override
  void initState() {
    super.initState();
    _chatBlockingService = ChatBlockingService(
      serviceLocator<UserBlockingRepository>(),
    );
    _checkBlockingStatus();
  }

  Future<void> _checkBlockingStatus() async {
    try {
      setState(() {
        _isCheckingStatus = true;
      });

      final status = await _chatBlockingService.checkBlockingStatus(
        widget.otherUserId,
      );

      if (mounted) {
        setState(() {
          _blockingStatus = status;
          _isCheckingStatus = false;
        });
      }
    } catch (e) {
      AppLogger.e(
        'BlockingAwareChatInput',
        'Error checking blocking status: $e',
      );
      if (mounted) {
        setState(() {
          _blockingStatus = BlockingStatus.none;
          _isCheckingStatus = false;
        });
      }
    }
  }

  void _onBlockStatusChanged() {
    // Refresh blocking status when block/unblock action occurs
    _checkBlockingStatus();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: serviceLocator<UserBlockingBloc>(),
      child: BlocListener<UserBlockingBloc, UserBlockingState>(
        listener: (context, state) {
          // Listen for blocking/unblocking events and refresh status
          if (state is UserBlocked &&
              state.blockedUser.blockedUser.id == widget.otherUserId) {
            _onBlockStatusChanged();
          } else if (state is UserUnblocked &&
              state.userId == widget.otherUserId) {
            _onBlockStatusChanged();
          }
        },
        child: Column(
          children: [
            // Show blocking status message if needed
            if (_chatBlockingService.shouldDisableMessaging(_blockingStatus))
              _buildBlockingStatusBar(),

            // Chat input (disabled if blocked)
            ProfessionalChatInput(
              controller: widget.controller,
              onSendMessage: widget.onSendMessage,
              onAttachmentPressed: widget.onAttachmentPressed,
              onChanged: widget.onChanged,
              onTypingChanged: widget.onTypingChanged,
              hintText: _getHintText(),
              maxLines: widget.maxLines,
              minLines: widget.minLines,
              isEnabled:
                  !_chatBlockingService.shouldDisableMessaging(
                    _blockingStatus,
                  ) &&
                  !_isCheckingStatus,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockingStatusBar() {
    final theme = Theme.of(context);
    final message = _chatBlockingService.getBlockingMessage(
      _blockingStatus,
      widget.otherUserName,
    );
    final showUnblockOption = _chatBlockingService.shouldShowUnblockOption(
      _blockingStatus,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.error.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.block, size: 20, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (showUnblockOption) ...[
            const SizedBox(width: 8),
            BlockUserButton(
              userId: widget.otherUserId,
              userName: widget.otherUserName,
              onBlockStatusChanged: _onBlockStatusChanged,
            ),
          ],
        ],
      ),
    );
  }

  String _getHintText() {
    if (_isCheckingStatus) {
      return 'Checking status...';
    } else if (_chatBlockingService.shouldDisableMessaging(_blockingStatus)) {
      return 'Messaging disabled';
    } else {
      return widget.hintText;
    }
  }
}
