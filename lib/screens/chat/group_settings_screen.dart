import 'package:flutter/material.dart';
import '../../models/chat_room.dart';
import '../../widgets/group_actions_widget.dart';

/// Screen for group settings and management
class GroupSettingsScreen extends StatefulWidget {
  final ChatRoom chatRoom;

  const GroupSettingsScreen({super.key, required this.chatRoom});

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _handleGroupLeft() {
    // Navigate back to group list
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Group Settings'), elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Info Section
            _buildGroupInfoSection(),

            const Divider(),

            // Participants Section
            _buildParticipantsSection(),

            const Divider(),

            // Actions Section
            _buildActionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Avatar and Name
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  widget.chatRoom.name?.substring(0, 1).toUpperCase() ?? 'G',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.chatRoom.name ?? 'Group Chat',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.chatRoom.participantIds.length} members',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (widget.chatRoom.description != null) ...[
            const SizedBox(height: 16),
            Text(
              'Description',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.chatRoom.description!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParticipantsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Participants (${widget.chatRoom.participantIds.length})',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Note: In a real implementation, you would fetch participant details
          // For now, we'll show participant IDs
          ...widget.chatRoom.participantIds.map((participantId) {
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey[300],
                child: Text(
                  participantId.toString().substring(0, 1),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              title: Text('User $participantId'),
              subtitle: const Text('Group Member'),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Leave Group Button
          GroupActionsWidget(
            chatRoom: widget.chatRoom,
            onGroupLeft: _handleGroupLeft,
          ),

          const SizedBox(height: 16),

          // Additional info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Once you leave this group, you will no longer receive messages and cannot rejoin unless added by another member.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
