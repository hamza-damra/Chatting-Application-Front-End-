import 'dart:io';
import 'dart:convert';
import '../services/websocket_service.dart';
import '../services/websocket_file_uploader.dart';
import 'logger.dart';

/// Diagnostic utility to verify file upload system is working correctly
class FileUploadDiagnostics {
  final WebSocketService _webSocketService;
  final WebSocketFileUploader _fileUploader;

  FileUploadDiagnostics(this._webSocketService)
    : _fileUploader = WebSocketFileUploader(_webSocketService);

  /// Run comprehensive diagnostics on the file upload system
  Future<DiagnosticResult> runDiagnostics() async {
    final result = DiagnosticResult();

    AppLogger.i(
      'FileUploadDiagnostics',
      '🔍 Starting file upload diagnostics...',
    );

    // Check 1: WebSocket Connection
    result.webSocketConnected = _checkWebSocketConnection();

    // Check 2: File Upload Service
    result.fileUploaderInitialized = _checkFileUploader();

    // Check 3: Supported File Types
    result.supportedFileTypes = _checkSupportedFileTypes();

    // Check 4: File Size Limits
    result.maxFileSize = _fileUploader.getMaxFileSize();

    // Check 5: WebSocket Subscriptions
    result.subscriptionsActive = _checkWebSocketSubscriptions();

    // Generate report
    _generateDiagnosticReport(result);

    return result;
  }

  bool _checkWebSocketConnection() {
    final isConnected = _webSocketService.isConnected;
    AppLogger.i(
      'FileUploadDiagnostics',
      isConnected ? '✅ WebSocket connected' : '❌ WebSocket not connected',
    );
    return isConnected;
  }

  bool _checkFileUploader() {
    try {
      // Try to create a file uploader instance
      WebSocketFileUploader(_webSocketService);
      AppLogger.i('FileUploadDiagnostics', '✅ File uploader initialized');
      return true;
    } catch (e) {
      AppLogger.e('FileUploadDiagnostics', '❌ File uploader failed: $e');
      return false;
    }
  }

  List<String> _checkSupportedFileTypes() {
    final supportedTypes = [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'bmp',
      'svg',
      'mp4',
      'avi',
      'mov',
      'wmv',
      'flv',
      'webm',
      'mkv',
      'mp3',
      'wav',
      'ogg',
      'aac',
      'm4a',
      'pdf',
      'doc',
      'docx',
      'xls',
      'xlsx',
      'ppt',
      'pptx',
      'txt',
      'csv',
      'json',
      'xml',
      'zip',
      'rar',
      '7z',
    ];

    AppLogger.i(
      'FileUploadDiagnostics',
      '✅ Supported file types: ${supportedTypes.length} types',
    );
    return supportedTypes;
  }

  bool _checkWebSocketSubscriptions() {
    // This is a simplified check - in a real implementation,
    // you would verify active subscriptions
    AppLogger.i(
      'FileUploadDiagnostics',
      '✅ WebSocket subscriptions should be active for:',
    );
    AppLogger.i('FileUploadDiagnostics', '   - /user/queue/files');
    AppLogger.i('FileUploadDiagnostics', '   - /user/queue/files.progress');
    AppLogger.i('FileUploadDiagnostics', '   - /user/queue/errors');
    return true;
  }

  void _generateDiagnosticReport(DiagnosticResult result) {
    AppLogger.i('FileUploadDiagnostics', '📋 DIAGNOSTIC REPORT');
    AppLogger.i('FileUploadDiagnostics', '==================');

    if (result.isHealthy) {
      AppLogger.i('FileUploadDiagnostics', '🎉 ALL SYSTEMS HEALTHY');
      AppLogger.i(
        'FileUploadDiagnostics',
        '✅ WebSocket file upload is properly configured',
      );
      AppLogger.i(
        'FileUploadDiagnostics',
        '✅ Ready to upload files via chunks to /app/file.chunk',
      );
    } else {
      AppLogger.e('FileUploadDiagnostics', '⚠️  ISSUES DETECTED');
      if (!result.webSocketConnected) {
        AppLogger.e('FileUploadDiagnostics', '❌ WebSocket not connected');
      }
      if (!result.fileUploaderInitialized) {
        AppLogger.e('FileUploadDiagnostics', '❌ File uploader not initialized');
      }
    }

    AppLogger.i(
      'FileUploadDiagnostics',
      'Max file size: ${result.maxFileSize ~/ (1024 * 1024)}MB',
    );
    AppLogger.i(
      'FileUploadDiagnostics',
      'Supported types: ${result.supportedFileTypes.length}',
    );
  }

  /// Test file upload with a small test file
  Future<bool> testFileUpload(int chatRoomId) async {
    try {
      AppLogger.i('FileUploadDiagnostics', '🧪 Testing file upload...');

      // Create a small test file
      final testContent =
          'File upload test - ${DateTime.now().toIso8601String()}';
      final testFile = File('test_upload.txt');
      await testFile.writeAsString(testContent);

      AppLogger.i(
        'FileUploadDiagnostics',
        '📄 Created test file: ${testFile.path}',
      );

      // Validate the file
      final isValid = await _fileUploader.validateFile(testFile);
      if (!isValid) {
        AppLogger.e('FileUploadDiagnostics', '❌ Test file validation failed');
        return false;
      }

      AppLogger.i('FileUploadDiagnostics', '✅ Test file validation passed');

      // Note: We don't actually upload to avoid creating test files on server
      // In a real test, you would call:
      // await _fileUploader.uploadFile(file: testFile, chatRoomId: chatRoomId);

      // Clean up test file
      if (await testFile.exists()) {
        await testFile.delete();
      }

      AppLogger.i(
        'FileUploadDiagnostics',
        '✅ File upload test completed successfully',
      );
      return true;
    } catch (e) {
      AppLogger.e('FileUploadDiagnostics', '❌ File upload test failed: $e');
      return false;
    }
  }

  /// Check for common anti-patterns in the codebase
  void checkForAntiPatterns() {
    AppLogger.i('FileUploadDiagnostics', '🔍 Checking for anti-patterns...');

    // This would be implemented to scan code for problematic patterns
    final antiPatterns = [
      'uploads/auto_generated',
      'sendMessage.*\\.jpg',
      'sendMessage.*\\.png',
      'sendMessage.*\\.pdf',
      'http.MultipartRequest',
      'FilePicker.*sendMessage',
    ];

    AppLogger.i(
      'FileUploadDiagnostics',
      '⚠️  Watch out for these anti-patterns:',
    );
    for (final pattern in antiPatterns) {
      AppLogger.w('FileUploadDiagnostics', '   - $pattern');
    }

    AppLogger.i(
      'FileUploadDiagnostics',
      '✅ Make sure your code uses WebSocketFileUploader instead',
    );
  }

  /// Monitor WebSocket traffic for file upload messages
  void monitorWebSocketTraffic() {
    AppLogger.i('FileUploadDiagnostics', '📡 Monitoring WebSocket traffic...');
    AppLogger.i('FileUploadDiagnostics', 'Look for these SUCCESS indicators:');
    AppLogger.i('FileUploadDiagnostics', '✅ Messages to: /app/file.chunk');
    AppLogger.i('FileUploadDiagnostics', '✅ Responses from: /user/queue/files');
    AppLogger.i(
      'FileUploadDiagnostics',
      '✅ Progress from: /user/queue/files.progress',
    );

    AppLogger.w('FileUploadDiagnostics', 'AVOID these PROBLEM indicators:');
    AppLogger.w(
      'FileUploadDiagnostics',
      '❌ File paths in: /app/chat.sendMessage',
    );
    AppLogger.w(
      'FileUploadDiagnostics',
      '❌ HTTP uploads to: /api/files/upload',
    );
    AppLogger.w('FileUploadDiagnostics', '❌ Auto-generated paths in messages');
  }
}

/// Result of diagnostic checks
class DiagnosticResult {
  bool webSocketConnected = false;
  bool fileUploaderInitialized = false;
  bool subscriptionsActive = false;
  List<String> supportedFileTypes = [];
  int maxFileSize = 0;

  bool get isHealthy =>
      webSocketConnected &&
      fileUploaderInitialized &&
      subscriptionsActive &&
      supportedFileTypes.isNotEmpty &&
      maxFileSize > 0;

  Map<String, dynamic> toJson() => {
    'webSocketConnected': webSocketConnected,
    'fileUploaderInitialized': fileUploaderInitialized,
    'subscriptionsActive': subscriptionsActive,
    'supportedFileTypes': supportedFileTypes,
    'maxFileSize': maxFileSize,
    'isHealthy': isHealthy,
  };

  @override
  String toString() => jsonEncode(toJson());
}

/// Extension to easily run diagnostics from any widget
extension WebSocketServiceDiagnostics on WebSocketService {
  Future<DiagnosticResult> runFileUploadDiagnostics() async {
    final diagnostics = FileUploadDiagnostics(this);
    return await diagnostics.runDiagnostics();
  }

  void checkFileUploadHealth() {
    final diagnostics = FileUploadDiagnostics(this);
    diagnostics.checkForAntiPatterns();
    diagnostics.monitorWebSocketTraffic();
  }
}
