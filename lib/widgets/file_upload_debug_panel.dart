import 'package:flutter/material.dart';
import '../services/websocket_service.dart';
import '../utils/file_upload_diagnostics.dart';
import '../utils/logger.dart';

/// Debug panel widget for testing and diagnosing file upload issues
/// Add this to your app during development to verify the fix is working
class FileUploadDebugPanel extends StatefulWidget {
  final WebSocketService webSocketService;
  final int? chatRoomId;

  const FileUploadDebugPanel({
    Key? key,
    required this.webSocketService,
    this.chatRoomId,
  }) : super(key: key);

  @override
  State<FileUploadDebugPanel> createState() => _FileUploadDebugPanelState();
}

class _FileUploadDebugPanelState extends State<FileUploadDebugPanel> {
  DiagnosticResult? _lastResult;
  bool _isRunningDiagnostics = false;
  bool _isTestingUpload = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.bug_report, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'File Upload Diagnostics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_lastResult?.isHealthy == true)
                  const Icon(Icons.check_circle, color: Colors.green)
                else if (_lastResult != null)
                  const Icon(Icons.error, color: Colors.red),
              ],
            ),
            
            const SizedBox(height: 16),

            // Status indicators
            if (_lastResult != null) ...[
              _buildStatusIndicator(
                'WebSocket Connected',
                _lastResult!.webSocketConnected,
              ),
              _buildStatusIndicator(
                'File Uploader Ready',
                _lastResult!.fileUploaderInitialized,
              ),
              _buildStatusIndicator(
                'Subscriptions Active',
                _lastResult!.subscriptionsActive,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Max File Size: ${(_lastResult!.maxFileSize / (1024 * 1024)).toStringAsFixed(1)}MB',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                'Supported Types: ${_lastResult!.supportedFileTypes.length}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              
              const SizedBox(height: 16),
            ],

            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isRunningDiagnostics ? null : _runDiagnostics,
                  icon: _isRunningDiagnostics
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: const Text('Run Diagnostics'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                
                if (widget.chatRoomId != null)
                  ElevatedButton.icon(
                    onPressed: _isTestingUpload ? null : _testFileUpload,
                    icon: _isTestingUpload
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file),
                    label: const Text('Test Upload'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                
                ElevatedButton.icon(
                  onPressed: _checkAntiPatterns,
                  icon: const Icon(Icons.search),
                  label: const Text('Check Anti-Patterns'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                
                ElevatedButton.icon(
                  onPressed: _monitorTraffic,
                  icon: const Icon(Icons.network_check),
                  label: const Text('Monitor Traffic'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Instructions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔍 How to Use This Panel',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Run Diagnostics - Check if file upload system is properly configured\n'
                    '2. Test Upload - Try uploading a small test file (if chat room selected)\n'
                    '3. Check Anti-Patterns - Look for common mistakes in console\n'
                    '4. Monitor Traffic - See what WebSocket messages to watch for',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Success/Error indicators
            if (_lastResult?.isHealthy == true)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '✅ File upload system is healthy and ready!',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (_lastResult != null && !_lastResult!.isHealthy)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '❌ Issues detected. Check console for details.',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String label, bool isOk) {
    return Row(
      children: [
        Icon(
          isOk ? Icons.check_circle : Icons.error,
          color: isOk ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: isOk ? Colors.green.shade700 : Colors.red.shade700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isRunningDiagnostics = true;
    });

    try {
      final diagnostics = FileUploadDiagnostics(widget.webSocketService);
      final result = await diagnostics.runDiagnostics();
      
      setState(() {
        _lastResult = result;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isHealthy 
              ? '✅ Diagnostics passed!' 
              : '⚠️ Issues detected - check console'
          ),
          backgroundColor: result.isHealthy ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      AppLogger.e('FileUploadDebugPanel', 'Diagnostics failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Diagnostics failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isRunningDiagnostics = false;
      });
    }
  }

  Future<void> _testFileUpload() async {
    if (widget.chatRoomId == null) return;

    setState(() {
      _isTestingUpload = true;
    });

    try {
      final diagnostics = FileUploadDiagnostics(widget.webSocketService);
      final success = await diagnostics.testFileUpload(widget.chatRoomId!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
              ? '✅ Test upload successful!' 
              : '❌ Test upload failed'
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      AppLogger.e('FileUploadDebugPanel', 'Test upload failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Test upload error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isTestingUpload = false;
      });
    }
  }

  void _checkAntiPatterns() {
    final diagnostics = FileUploadDiagnostics(widget.webSocketService);
    diagnostics.checkForAntiPatterns();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔍 Anti-pattern check complete - see console'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _monitorTraffic() {
    final diagnostics = FileUploadDiagnostics(widget.webSocketService);
    diagnostics.monitorWebSocketTraffic();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📡 Traffic monitoring info logged to console'),
        backgroundColor: Colors.purple,
      ),
    );
  }
}
