import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../core/services/token_service.dart';
import '../providers/api_auth_provider.dart';
import '../utils/logger.dart';
import 'package:http/http.dart' as http;

/// A debug widget to test profile image endpoints
class DebugProfileImageWidget extends StatefulWidget {
  final int? userId;
  final String? userName;

  const DebugProfileImageWidget({
    super.key,
    this.userId,
    this.userName,
  });

  @override
  State<DebugProfileImageWidget> createState() => _DebugProfileImageWidgetState();
}

class _DebugProfileImageWidgetState extends State<DebugProfileImageWidget> {
  String _debugInfo = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _testEndpoint();
  }

  Future<void> _testEndpoint() async {
    setState(() {
      _isLoading = true;
      _debugInfo = 'Testing endpoint...';
    });

    try {
      final authProvider = Provider.of<ApiAuthProvider>(context, listen: false);
      final tokenService = Provider.of<TokenService>(context, listen: false);

      final currentUserId = authProvider.user?.id;
      final isCurrentUser = widget.userId != null && 
          currentUserId != null && 
          widget.userId == currentUserId;

      final imageUrl = widget.userId == null || isCurrentUser
          ? ApiConfig.getCurrentUserProfileImageUrl()
          : ApiConfig.getUserProfileImageUrl(widget.userId!);

      final authHeaders = tokenService.accessToken != null
          ? ApiConfig.getAuthHeaders(tokenService.accessToken!)
          : <String, String>{};

      AppLogger.i('DebugProfileImageWidget', 'Testing endpoint: $imageUrl');
      AppLogger.i('DebugProfileImageWidget', 'Headers: $authHeaders');

      // Test with HEAD request first
      final headResponse = await http.head(
        Uri.parse(imageUrl),
        headers: authHeaders,
      );

      String debugText = '''
DEBUG INFO:
-----------
Widget userId: ${widget.userId}
Current user ID: $currentUserId
Is current user: $isCurrentUser
Image URL: $imageUrl
Token available: ${tokenService.accessToken != null}

HEAD Request:
Status: ${headResponse.statusCode}
Headers: ${headResponse.headers}

''';

      if (headResponse.statusCode == 200) {
        debugText += 'HEAD request successful - image exists\n';
        
        // Try GET request
        final getResponse = await http.get(
          Uri.parse(imageUrl),
          headers: authHeaders,
        );
        
        debugText += '''
GET Request:
Status: ${getResponse.statusCode}
Content-Type: ${getResponse.headers['content-type']}
Content-Length: ${getResponse.headers['content-length']}
Body length: ${getResponse.bodyBytes.length}
''';
      } else {
        debugText += '''
HEAD request failed:
Status: ${headResponse.statusCode}
Reason: ${headResponse.reasonPhrase}
Body: ${headResponse.body}
''';

        // Try alternative endpoints
        if (!isCurrentUser && widget.userId != null) {
          debugText += '\nTrying /me endpoint as fallback...\n';
          final meUrl = ApiConfig.getCurrentUserProfileImageUrl();
          final meResponse = await http.head(
            Uri.parse(meUrl),
            headers: authHeaders,
          );
          debugText += '''
/me endpoint test:
URL: $meUrl
Status: ${meResponse.statusCode}
''';
        }
      }

      setState(() {
        _debugInfo = debugText;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _debugInfo = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile Image Debug',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _debugInfo,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _testEndpoint,
                  child: const Text('Retest'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    AppLogger.i('DebugProfileImageWidget', _debugInfo);
                  },
                  child: const Text('Log to Console'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
