import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../presentation/blocs/user_blocking/user_blocking_bloc.dart';
import '../core/di/service_locator.dart';

class BlockUserButton extends StatefulWidget {
  final int userId;
  final String userName;
  final bool? isBlocked;
  final VoidCallback? onBlockStatusChanged;
  final ButtonStyle? style;
  final Widget? blockedIcon;
  final Widget? unblockedIcon;

  const BlockUserButton({
    super.key,
    required this.userId,
    required this.userName,
    this.isBlocked,
    this.onBlockStatusChanged,
    this.style,
    this.blockedIcon,
    this.unblockedIcon,
  });

  @override
  State<BlockUserButton> createState() => _BlockUserButtonState();
}

class _BlockUserButtonState extends State<BlockUserButton> {
  bool? _isBlocked;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isBlocked = widget.isBlocked;

    // If block status is unknown, check it
    if (_isBlocked == null) {
      _checkBlockStatus();
    }
  }

  @override
  void didUpdateWidget(BlockUserButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBlocked != oldWidget.isBlocked) {
      _isBlocked = widget.isBlocked;
    }
  }

  void _checkBlockStatus() {
    if (widget.userId <= 0) {
      // Invalid user ID, don't check
      setState(() {
        _isLoading = false;
        _isBlocked = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    serviceLocator<UserBlockingBloc>().add(CheckUserBlockStatus(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: serviceLocator<UserBlockingBloc>(),
      child: BlocListener<UserBlockingBloc, UserBlockingState>(
        listener: (context, state) {
          if (state is UserBlockStatusChecked &&
              state.userId == widget.userId) {
            setState(() {
              _isBlocked = state.isBlocked;
              _isLoading = false;
            });
          } else if (state is UserBlocked &&
              state.blockedUser.blockedUser.id == widget.userId) {
            setState(() {
              _isBlocked = true;
              _isLoading = false;
            });
            widget.onBlockStatusChanged?.call();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${widget.userName} has been blocked'),
                backgroundColor: Colors.orange,
              ),
            );
          } else if (state is UserUnblocked && state.userId == widget.userId) {
            setState(() {
              _isBlocked = false;
              _isLoading = false;
            });
            widget.onBlockStatusChanged?.call();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${widget.userName} has been unblocked'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is UserBlockingActionLoading &&
              state.userId == widget.userId) {
            setState(() {
              _isLoading = true;
            });
          } else if (state is UserBlockingFailure) {
            setState(() {
              _isLoading = false;
            });

            // Only show error for blocking/unblocking actions, not status checks
            if (state.action == 'blocking' || state.action == 'unblocking') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        child: _buildButton(context),
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    if (_isLoading) {
      return ElevatedButton(
        onPressed: null,
        style: widget.style,
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_isBlocked == null) {
      return ElevatedButton(
        onPressed: _checkBlockStatus,
        style: widget.style,
        child: const Text('Check Status'),
      );
    }

    if (_isBlocked!) {
      return ElevatedButton(
        onPressed: () => _showUnblockDialog(context),
        style:
            widget.style ??
            ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[600],
              foregroundColor: Colors.white,
            ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.blockedIcon ?? const Icon(Icons.block, size: 16),
            const SizedBox(width: 4),
            const Text('Unblock'),
          ],
        ),
      );
    } else {
      return ElevatedButton(
        onPressed: () => _showBlockDialog(context),
        style:
            widget.style ??
            ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.unblockedIcon ?? const Icon(Icons.block, size: 16),
            const SizedBox(width: 4),
            const Text('Block'),
          ],
        ),
      );
    }
  }

  void _showBlockDialog(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text('Block ${widget.userName}?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('This user will not be able to send you messages.'),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason (optional)',
                    hintText: 'Why are you blocking this user?',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  maxLength: 500,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  final reason = reasonController.text.trim();
                  context.read<UserBlockingBloc>().add(
                    BlockUser(
                      widget.userId,
                      reason: reason.isEmpty ? null : reason,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Block User'),
              ),
            ],
          ),
    );
  }

  void _showUnblockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text('Unblock ${widget.userName}?'),
            content: const Text(
              'This user will be able to send you messages again.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.read<UserBlockingBloc>().add(
                    UnblockUser(widget.userId),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Unblock'),
              ),
            ],
          ),
    );
  }
}
