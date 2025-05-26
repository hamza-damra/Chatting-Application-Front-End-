import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import '../utils/logger.dart';
import 'websocket_service.dart';

/// WebSocket-based file uploader that sends files in chunks
/// This matches the backend BinaryFileController implementation
class WebSocketFileUploader {
  static const int chunkSize = 32768; // 32KB chunks
  final WebSocketService _webSocketService;
  final Uuid _uuid = const Uuid();

  WebSocketFileUploader(this._webSocketService);

  /// Upload a file via WebSocket chunks to the backend
  Future<String> uploadFile({
    required File file,
    required int chatRoomId,
    Function(double)? onProgress,
    Function(String)? onComplete,
    Function(String)? onError,
  }) async {
    try {
      // Validate file exists
      if (!await file.exists()) {
        throw Exception('File does not exist: ${file.path}');
      }

      String fileName = path.basename(file.path);
      String contentType = _getContentType(fileName);
      Uint8List fileBytes = await file.readAsBytes();
      int fileSize = fileBytes.length;
      int totalChunks = (fileSize / chunkSize).ceil();
      String uploadId = _uuid.v4();

      AppLogger.i(
        'WebSocketFileUploader',
        'Starting file upload: $fileName ($fileSize bytes, $totalChunks chunks)',
      );

      // Send chunks sequentially
      for (int i = 0; i < totalChunks; i++) {
        int start = i * chunkSize;
        int end = math.min(start + chunkSize, fileSize);
        Uint8List chunkBytes = fileBytes.sublist(start, end);
        String base64Chunk = base64Encode(chunkBytes);

        // Create chunk data matching backend FileChunk model
        Map<String, dynamic> chunkData = {
          'fileName': fileName,
          'contentType': contentType,
          'fileSize': fileSize,
          'chunkIndex': i + 1, // Backend expects 1-based indexing
          'totalChunks': totalChunks,
          'data': base64Chunk,
          'chatRoomId': chatRoomId,
          'uploadId': uploadId,
        };

        AppLogger.d(
          'WebSocketFileUploader',
          'Sending chunk ${i + 1}/$totalChunks for $fileName',
        );

        // Send chunk via WebSocket to /app/file.chunk
        await _webSocketService.sendFileChunk('/app/file.chunk', chunkData);

        // Update progress
        if (onProgress != null) {
          double progress = (i + 1) / totalChunks;
          onProgress(progress);
        }

        // Small delay to prevent overwhelming the server
        await Future.delayed(const Duration(milliseconds: 50));
      }

      AppLogger.i('WebSocketFileUploader', 'File upload completed: $fileName');

      // Return the upload ID for tracking
      return uploadId;
    } catch (e) {
      AppLogger.e('WebSocketFileUploader', 'File upload error: $e');
      if (onError != null) {
        onError('Upload failed: $e');
      }
      rethrow;
    }
  }

  /// Get MIME content type based on file extension
  String _getContentType(String fileName) {
    String extension = fileName.toLowerCase().split('.').last;

    switch (extension) {
      // Images
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'svg':
        return 'image/svg+xml';

      // Videos
      case 'mp4':
        return 'video/mp4';
      case 'avi':
        return 'video/avi';
      case 'mov':
        return 'video/quicktime';
      case 'wmv':
        return 'video/x-ms-wmv';
      case 'flv':
        return 'video/x-flv';
      case 'webm':
        return 'video/webm';
      case 'mkv':
        return 'video/x-matroska';

      // Audio
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'ogg':
        return 'audio/ogg';
      case 'aac':
        return 'audio/aac';
      case 'm4a':
        return 'audio/mp4';

      // Documents
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';

      // Text
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
      case 'json':
        return 'application/json';
      case 'xml':
        return 'application/xml';

      // Archives
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/x-rar-compressed';
      case '7z':
        return 'application/x-7z-compressed';

      default:
        return 'application/octet-stream';
    }
  }

  /// Check if a file type is supported for upload
  bool isFileTypeSupported(String fileName) {
    String extension = fileName.toLowerCase().split('.').last;

    // Define supported extensions
    const supportedExtensions = {
      // Images
      'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg',
      // Videos
      'mp4', 'avi', 'mov', 'wmv', 'flv', 'webm', 'mkv',
      // Audio
      'mp3', 'wav', 'ogg', 'aac', 'm4a',
      // Documents
      'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
      // Text
      'txt', 'csv', 'json', 'xml',
      // Archives
      'zip', 'rar', '7z',
    };

    return supportedExtensions.contains(extension);
  }

  /// Get maximum file size allowed (in bytes)
  int getMaxFileSize() {
    return 50 * 1024 * 1024; // 50MB
  }

  /// Validate file before upload
  Future<bool> validateFile(File file) async {
    try {
      // Check if file exists
      if (!await file.exists()) {
        AppLogger.w('WebSocketFileUploader', 'File does not exist');
        return false;
      }

      // Check file size
      int fileSize = await file.length();
      if (fileSize > getMaxFileSize()) {
        AppLogger.w(
          'WebSocketFileUploader',
          'File too large: $fileSize bytes (max: ${getMaxFileSize()})',
        );
        return false;
      }

      // Check file type
      String fileName = path.basename(file.path);
      if (!isFileTypeSupported(fileName)) {
        AppLogger.w(
          'WebSocketFileUploader',
          'Unsupported file type: $fileName',
        );
        return false;
      }

      return true;
    } catch (e) {
      AppLogger.e('WebSocketFileUploader', 'Error validating file: $e');
      return false;
    }
  }
}
