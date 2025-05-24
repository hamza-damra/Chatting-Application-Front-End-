import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import '../models/chat_room.dart';
import '../models/message.dart';
import '../providers/chat_provider.dart';

class SearchChatDelegate extends SearchDelegate<Message?> {
  final List<ChatRoom> chatRooms;
  final ChatProvider chatProvider;
  final int currentUserId;

  SearchChatDelegate({
    required this.chatRooms,
    required this.chatProvider,
    required this.currentUserId,
  });

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Type to search messages'));
    }

    return FutureBuilder<List<Message>>(
      future: _searchMessages(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final messages = snapshot.data ?? [];

        if (messages.isEmpty) {
          return const Center(child: Text('No messages found'));
        }

        return ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return _buildMessageItem(context, message);
          },
        );
      },
    );
  }

  Future<List<Message>> _searchMessages() async {
    final results = <Message>[];

    for (final room in chatRooms) {
      try {
        final messages = chatProvider.getMessages(room.id.toString());

        final filteredMessages =
            messages
                .where((message) {
                  if (message is types.TextMessage) {
                    final content = message.text.toLowerCase();
                    final senderName =
                        message.author.firstName?.toLowerCase() ?? '';
                    final lastName =
                        message.author.lastName?.toLowerCase() ?? '';
                    final searchQuery = query.toLowerCase();

                    return content.contains(searchQuery) ||
                        senderName.contains(searchQuery) ||
                        lastName.contains(searchQuery);
                  }
                  return false;
                })
                .map(
                  (msg) => Message(
                    id: int.tryParse(msg.id) ?? 0,
                    roomId: room.id,
                    senderId: currentUserId,
                    senderName:
                        '${msg.author.firstName} ${msg.author.lastName}',
                    content: msg is types.TextMessage ? msg.text : null,
                    contentType: msg is types.TextMessage ? 'TEXT' : 'OTHER',
                    sentAt:
                        msg.createdAt != null
                            ? DateTime.fromMillisecondsSinceEpoch(
                              msg.createdAt!,
                            )
                            : DateTime.now(),
                    isRead: true,
                  ),
                )
                .toList();

        results.addAll(filteredMessages);
      } catch (e) {
        // Ignore errors for individual rooms
      }
    }

    // Sort by date, newest first
    results.sort((a, b) {
      if (a.sentAt == null || b.sentAt == null) {
        return 0;
      }
      return b.sentAt!.compareTo(a.sentAt!);
    });

    return results;
  }

  Widget _buildMessageItem(BuildContext context, Message message) {
    final room = _findRoomById(message.roomId);
    final roomName = room?.name ?? 'Unknown Room';
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary,
          child: Text(
            roomName.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          message.senderName ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content ?? 'No content',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${_formatDate(message.sentAt)} • $roomName',
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodySmall?.color ?? Colors.grey,
              ),
            ),
          ],
        ),
        onTap: () {
          close(context, message);
        },
      ),
    );
  }

  ChatRoom? _findRoomById(int? roomId) {
    if (roomId == null) return null;
    return chatRooms.firstWhere(
      (room) => room.id == roomId,
      orElse: () => chatRooms.first,
    );
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) {
      return '';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return 'Today ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Yesterday ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
