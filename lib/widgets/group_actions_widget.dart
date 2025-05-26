import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/chat_room.dart';
import '../utils/logger.dart';

/// Widget for group actions like leaving a group
class GroupActionsWidget extends StatefulWidget {
  final ChatRoom chatRoom;
  final VoidCallback? onGroupLeft;
  final bool showAsMenuItem;

  const GroupActionsWidget({
    super.key,
    required this.chatRoom,
    this.onGroupLeft,
    this.showAsMenuItem = false,
  });

  @override
  State<GroupActionsWidget> createState() => _GroupActionsWidgetState();
}

class _GroupActionsWidgetState extends State<GroupActionsWidget> {
  bool _isLoading = false;

  /// Show confirmation dialog before leaving group
  Future<bool> _showLeaveConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Leave Group'),
                content: Text(
                  'Are you sure you want to leave "${widget.chatRoom.name}"?\n\n'
                  'You will no longer receive messages from this group.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Leave Group'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  /// Handle leave group action
  Future<void> _handleLeaveGroup() async {
    final confirmed = await _showLeaveConfirmationDialog();
    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      if (!mounted) return;

      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final success = await chatProvider.leaveGroup(widget.chatRoom.id);

      if (!mounted) return;

      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully left the group'),
            backgroundColor: Colors.green,
          ),
        );

        // Call callback to handle group removal from UI
        widget.onGroupLeft?.call();

        // Navigate back if we're in the group chat
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      } else {
        // Show error message
        _showErrorDialog(chatProvider.error ?? 'Failed to leave group');
      }
    } catch (e) {
      AppLogger.e('GroupActionsWidget', 'Error leaving group: $e');
      if (mounted) {
        _showErrorDialog('An unexpected error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showAsMenuItem) {
      return PopupMenuItem<String>(
        value: 'leave_group',
        child: Row(
          children: [
            const Icon(Icons.exit_to_app, color: Colors.red),
            const SizedBox(width: 12),
            const Text('Leave Group', style: TextStyle(color: Colors.red)),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _handleLeaveGroup,
        icon:
            _isLoading
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : const Icon(Icons.exit_to_app),
        label: Text(_isLoading ? 'Leaving...' : 'Leave Group'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
