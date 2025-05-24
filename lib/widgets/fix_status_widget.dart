import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/improved_chat_service.dart';
import '../services/api_file_service.dart';
import '../providers/api_auth_provider.dart';

class FixStatusWidget extends StatelessWidget {
  const FixStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<ApiAuthProvider>(context);
    final improvedChatService = Provider.of<ImprovedChatService>(context, listen: false);
    final apiFileService = Provider.of<ApiFileService>(context, listen: false);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.build_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Chat App Fixes Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatusItem(
              '✅ Authentication & Authorization',
              'JWT tokens and role-based access fixed',
              Colors.green,
            ),
            _buildStatusItem(
              '✅ REST API File Upload',
              'Proper file upload via /api/files/upload',
              Colors.green,
            ),
            _buildStatusItem(
              '✅ WebSocket Message Flow',
              'File URLs sent via WebSocket (not paths)',
              Colors.green,
            ),
            _buildStatusItem(
              '✅ Image Display',
              'Images now display correctly in chat',
              Colors.green,
            ),
            _buildStatusItem(
              '✅ Error Handling',
              'Better error messages and debugging',
              Colors.green,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'How to Test:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Go to Settings → Debug API to test endpoints\n'
                    '2. Try uploading an image in any chat room\n'
                    '3. Images should display correctly now\n'
                    '4. No more placeholder files on server',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            if (authProvider.isAuthenticated) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Authenticated as: ${authProvider.user?.username ?? "Unknown"}',
                        style: const TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String title, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
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
