import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../providers/notification_provider.dart';
import '../models/unread_message_notification.dart';
import '../utils/logger.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Notification System Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: _testLocalNotification,
              child: const Text('Test Local Notification'),
            ),
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _testNotificationProvider,
              child: const Text('Test Notification Provider'),
            ),
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _testPermissions,
              child: const Text('Test Notification Permissions'),
            ),
            const SizedBox(height: 20),
            
            const Text(
              'Current Notifications:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            
            Expanded(
              child: Consumer<NotificationProvider>(
                builder: (context, notificationProvider, child) {
                  final notifications = notificationProvider.notifications;
                  
                  if (notifications.isEmpty) {
                    return const Center(
                      child: Text('No notifications'),
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return Card(
                        child: ListTile(
                          title: Text(notification.senderUsername),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Room: ${notification.chatRoomName}'),
                              if (notification.contentPreview != null)
                                Text('Content: ${notification.contentPreview}'),
                              Text('Type: ${notification.notificationType.displayName}'),
                              Text('Time: ${notification.notificationTimestamp}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              notificationProvider.removeNotification(notification.messageId);
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Provider.of<NotificationProvider>(context, listen: false)
                    .clearAllNotifications();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Clear All Notifications'),
            ),
          ],
        ),
      ),
    );
  }

  void _testLocalNotification() async {
    try {
      AppLogger.i('NotificationTest', 'Testing local notification...');
      
      final testNotification = UnreadMessageNotification(
        messageId: DateTime.now().millisecondsSinceEpoch,
        chatRoomId: 999,
        chatRoomName: 'Test Room',
        senderId: 123,
        senderUsername: 'TestUser',
        senderFullName: 'Test User Full Name',
        contentPreview: 'This is a test notification message!',
        contentType: 'TEXT',
        sentAt: DateTime.now(),
        notificationTimestamp: DateTime.now(),
        unreadCount: 1,
        totalUnreadCount: 1,
        recipientUserId: 456,
        isPrivateChat: false,
        participantCount: 2,
        notificationType: NotificationType.newMessage,
      );

      await NotificationService.showUnreadMessageNotification(testNotification);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test notification sent! Check your notification panel.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.e('NotificationTest', 'Error testing local notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _testNotificationProvider() {
    try {
      AppLogger.i('NotificationTest', 'Testing notification provider...');
      
      final testNotification = UnreadMessageNotification(
        messageId: DateTime.now().millisecondsSinceEpoch,
        chatRoomId: 888,
        chatRoomName: 'Provider Test Room',
        senderId: 789,
        senderUsername: 'ProviderTestUser',
        senderFullName: 'Provider Test User',
        contentPreview: 'This is a test notification from the provider!',
        contentType: 'TEXT',
        sentAt: DateTime.now(),
        notificationTimestamp: DateTime.now(),
        unreadCount: 1,
        totalUnreadCount: 1,
        recipientUserId: 456,
        isPrivateChat: true,
        participantCount: 2,
        notificationType: NotificationType.privateMessage,
      );

      Provider.of<NotificationProvider>(context, listen: false)
          .addNotification(testNotification);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification added to provider!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      AppLogger.e('NotificationTest', 'Error testing notification provider: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _testPermissions() async {
    try {
      AppLogger.i('NotificationTest', 'Testing notification permissions...');
      
      // Re-initialize to check permissions
      await NotificationService.initialize();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permissions checked. Check logs for details.'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      AppLogger.e('NotificationTest', 'Error testing permissions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
