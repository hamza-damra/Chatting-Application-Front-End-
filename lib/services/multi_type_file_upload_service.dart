import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../utils/logger.dart';
import 'websocket_service.dart';

/// Enum for different file categories
enum FileCategory { image, document, audio, video, other }

/// Enhanced service for handling file uploads via WebSocket with chunking
/// Compatible with the updated backend file handling system
class MultiTypeFileUploadService {
  static const int chunkSize = 64 * 1024; // 64KB chunks as recommended
  static const int maxFileSize = 1024 * 1024 * 1024; // 1GB limit

  final WebSocketService _webSocketService;
  final _supportedTypes = {
    FileCategory.image: [
      '.jpeg',
      '.jpg',
      '.png',
      '.gif',
      '.webp',
      '.svg',
      '.bmp',
      '.tiff',
    ],
    FileCategory.document: [
      '.pdf',
      '.doc',
      '.docx',
      '.xls',
      '.xlsx',
      '.ppt',
      '.pptx',
      '.txt',
      '.html',
      '.css',
      '.js',
      '.json',
      '.xml',
    ],
    FileCategory.audio: ['.mp3', '.wav', '.ogg', '.aac', '.flac'],
    FileCategory.video: ['.mp4', '.mpeg', '.webm', '.mov', '.avi'],
    FileCategory.other: ['.zip', '.rar', '.tar', '.gz'],
  };

  // Upload state tracking
  bool _isUploading = false;
  String? _currentUploadId;
  final Map<String, _UploadState> _activeUploads = {};

  // Constructor
  MultiTypeFileUploadService({required WebSocketService webSocketService})
    : _webSocketService = webSocketService {
    // Set up WebSocket subscriptions for file uploads
    _setupWebSocketSubscriptions();
  }

  // Getters
  bool get isUploading => _isUploading;
  String? get currentUploadId => _currentUploadId;

  /// Set up WebSocket subscriptions for file uploads
  void _setupWebSocketSubscriptions() {
    // Subscribe to file progress updates
    _webSocketService.subscribeToDestination(
      destination: '/user/queue/files.progress',
      callback: _handleFileProgress,
    );

    // Subscribe to file completion notifications
    _webSocketService.subscribeToDestination(
      destination: '/user/queue/files',
      callback: _handleFileComplete,
    );

    // Subscribe to error notifications
    _webSocketService.subscribeToDestination(
      destination: '/user/queue/errors',
      callback: _handleError,
    );
  }

  /// Handle file progress updates from the server
  void _handleFileProgress(dynamic frame) {
    try {
      final progress = jsonDecode(frame.body!);
      final uploadId = progress['uploadId'];

      if (uploadId != null && _activeUploads.containsKey(uploadId)) {
        final upload = _activeUploads[uploadId]!;
        final chunkIndex = progress['chunkIndex'];
        final totalChunks = progress['totalChunks'];

        AppLogger.i(
          'MultiTypeFileUploadService',
          'Progress update for $uploadId: $chunkIndex/$totalChunks',
        );

        upload.onProgress?.call(chunkIndex, totalChunks);
      }
    } catch (e) {
      AppLogger.e(
        'MultiTypeFileUploadService',
        'Error handling progress update: $e',
      );
    }
  }

  /// Handle file upload completion notification
  void _handleFileComplete(dynamic frame) {
    try {
      final response = jsonDecode(frame.body!);
      final attachmentUrl = response['attachmentUrl'];

      // Try to find the upload by matching the file name
      final fileName = response['content'];
      String? matchedUploadId;

      for (final entry in _activeUploads.entries) {
        if (entry.value.fileName == fileName) {
          matchedUploadId = entry.key;
          break;
        }
      }

      if (matchedUploadId != null &&
          _activeUploads.containsKey(matchedUploadId)) {
        final upload = _activeUploads[matchedUploadId]!;

        AppLogger.i(
          'MultiTypeFileUploadService',
          'Upload complete for $matchedUploadId: $fileName -> $attachmentUrl',
        );

        upload.onComplete?.call(response);
        _cleanup(matchedUploadId);
      }
    } catch (e) {
      AppLogger.e(
        'MultiTypeFileUploadService',
        'Error handling upload completion: $e',
      );
    }
  }

  /// Handle error notifications
  void _handleError(dynamic frame) {
    try {
      final errorData = jsonDecode(frame.body!);
      final errorMessage = errorData['message'] ?? 'Unknown error';
      final uploadId = _currentUploadId;

      AppLogger.e(
        'MultiTypeFileUploadService',
        'Error from server: $errorMessage',
      );

      if (uploadId != null && _activeUploads.containsKey(uploadId)) {
        final upload = _activeUploads[uploadId]!;
        upload.onError?.call(errorMessage);
        _cleanup(uploadId);
      }
    } catch (e) {
      AppLogger.e(
        'MultiTypeFileUploadService',
        'Error handling error notification: $e',
      );
    }
  }

  // Removed unused _getFileCategory method

  /// Pick and upload a file with progress tracking and error handling
  Future<void> pickAndUploadFile(
    int chatRoomId, {
    FileCategory? category,
    Function(int current, int total)? onProgress,
    Function(dynamic result)? onComplete,
    Function(String message)? onError,
  }) async {
    try {
      File? file;

      // Use FilePicker for all file types
      if (category == null || category == FileCategory.other) {
        // Allow any file type
        final result = await FilePicker.platform.pickFiles();
        if (result != null) {
          file = File(result.files.single.path!);
        }
      } else {
        // Filter by category
        FileType fileType;
        List<String>? allowedExtensions;

        switch (category) {
          case FileCategory.image:
            fileType = FileType.image;
            break;
          case FileCategory.document:
            fileType = FileType.custom;
            allowedExtensions =
                _supportedTypes[FileCategory.document]!
                    .map((e) => e.substring(1)) // Remove the dot
                    .toList();
            break;
          case FileCategory.audio:
            fileType = FileType.audio;
            break;
          case FileCategory.video:
            fileType = FileType.video;
            break;
          default:
            fileType = FileType.any;
        }

        final result = await FilePicker.platform.pickFiles(
          type: fileType,
          allowedExtensions: allowedExtensions,
        );

        if (result != null) {
          file = File(result.files.single.path!);
        }
      }

      if (file != null) {
        await uploadFile(
          file,
          chatRoomId,
          onProgress: onProgress,
          onComplete: onComplete,
          onError: onError,
        );
      }
    } catch (e) {
      AppLogger.e('MultiTypeFileUploadService', 'Error picking file: $e');
      onError?.call('Error picking file: $e');
    }
  }

  /// Upload an image from the camera
  Future<void> uploadImageFromCamera(
    int chatRoomId, {
    Function(int current, int total)? onProgress,
    Function(dynamic result)? onComplete,
    Function(String message)? onError,
  }) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        File file = File(image.path);
        await uploadFile(
          file,
          chatRoomId,
          onProgress: onProgress,
          onComplete: onComplete,
          onError: onError,
        );
      }
    } catch (e) {
      AppLogger.e('MultiTypeFileUploadService', 'Error capturing image: $e');
      onError?.call('Error capturing image: $e');
    }
  }

  /// Upload a file with progress tracking and error handling
  Future<void> uploadFile(
    File file,
    int chatRoomId, {
    Function(int current, int total)? onProgress,
    Function(dynamic result)? onComplete,
    Function(String message)? onError,
  }) async {
    try {
      // Validate file exists
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      // Get file information
      final String fileName = path.basename(file.path);
      final int fileSize = await file.length();

      // Validate file size
      if (fileSize > maxFileSize) {
        throw Exception(
          'File size (${_formatFileSize(fileSize)}) exceeds maximum allowed size (${_formatFileSize(maxFileSize)})',
        );
      }

      // Generate upload ID
      final String uploadId = const Uuid().v4();
      _currentUploadId = uploadId;
      _isUploading = true;

      // Create upload state
      _activeUploads[uploadId] = _UploadState(
        fileName: fileName,
        totalSize: fileSize,
        onProgress: onProgress,
        onComplete: onComplete,
        onError: onError,
      );

      // Start upload process
      await _uploadFileInChunks(file, fileName, fileSize, chatRoomId, uploadId);
    } catch (e) {
      AppLogger.e('MultiTypeFileUploadService', 'Upload error: $e');
      onError?.call(e.toString());
      _cleanup(_currentUploadId);
    }
  }

  /// Format file size to human readable string
  String _formatFileSize(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
  }

  /// Upload file in chunks
  Future<void> _uploadFileInChunks(
    File file,
    String fileName,
    int fileSize,
    int chatRoomId,
    String uploadId,
  ) async {
    if (!_webSocketService.isConnected) {
      await _ensureConnection();
    }

    try {
      final totalChunks = (fileSize / chunkSize).ceil();
      final RandomAccessFile reader = await file.open(mode: FileMode.read);

      for (int chunkIndex = 0; chunkIndex < totalChunks; chunkIndex++) {
        if (!_activeUploads.containsKey(uploadId)) {
          // Upload was cancelled
          await reader.close();
          return;
        }

        final currentChunkSize = _calculateChunkSize(
          chunkIndex,
          totalChunks,
          fileSize,
        );
        final chunk = await _readChunk(reader, currentChunkSize);
        final base64Data = base64Encode(chunk);

        await _sendChunk(
          uploadId,
          chatRoomId,
          fileName,
          fileSize,
          chunkIndex + 1,
          totalChunks,
          base64Data,
        );

        // Small delay to prevent overwhelming the connection
        await Future.delayed(const Duration(milliseconds: 100));
      }

      await reader.close();
    } catch (e) {
      AppLogger.e('MultiTypeFileUploadService', 'Chunk upload error: $e');
      _activeUploads[uploadId]?.onError?.call('Error uploading file: $e');
      _cleanup(uploadId);
    }
  }

  /// Calculate the size of a specific chunk
  int _calculateChunkSize(int chunkIndex, int totalChunks, int fileSize) {
    if (chunkIndex == totalChunks - 1) {
      return fileSize - (chunkIndex * chunkSize);
    }
    return chunkSize;
  }

  /// Read a chunk from the file
  Future<Uint8List> _readChunk(RandomAccessFile reader, int size) async {
    final buffer = Uint8List(size);
    final bytesRead = await reader.readInto(buffer);
    if (bytesRead < size) {
      return buffer.sublist(0, bytesRead);
    }
    return buffer;
  }

  /// Send a chunk to the server
  Future<void> _sendChunk(
    String uploadId,
    int chatRoomId,
    String fileName,
    int fileSize,
    int chunkIndex,
    int totalChunks,
    String base64Data,
  ) async {
    final contentType = _getContentType(fileName);

    final message = {
      'messageId': null,
      'chatRoomId': chatRoomId,
      'chunkIndex': chunkIndex,
      'totalChunks': totalChunks,
      'fileName': fileName,
      'contentType': contentType,
      'data': base64Data,
      'fileSize': fileSize,
      'uploadId': uploadId,
    };

    _webSocketService.sendCustomMessage(
      destination: '/app/file.chunk',
      body: jsonEncode(message),
    );

    AppLogger.i(
      'MultiTypeFileUploadService',
      'Sent chunk $chunkIndex/$totalChunks for $fileName (type: $contentType)',
    );
  }

  /// Get content type based on file extension and content
  String _getContentType(String fileName) {
    // First try to detect MIME type from file extension
    final mimeType = lookupMimeType(fileName);
    if (mimeType != null) {
      return mimeType;
    }

    // Fallback to extension-based detection
    final extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.svg':
        return 'image/svg+xml';
      case '.bmp':
        return 'image/bmp';
      case '.tiff':
        return 'image/tiff';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case '.ppt':
        return 'application/vnd.ms-powerpoint';
      case '.pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case '.txt':
        return 'text/plain';
      case '.html':
        return 'text/html';
      case '.css':
        return 'text/css';
      case '.js':
        return 'text/javascript';
      case '.json':
        return 'application/json';
      case '.xml':
        return 'application/xml';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.ogg':
        return 'audio/ogg';
      case '.aac':
        return 'audio/aac';
      case '.flac':
        return 'audio/flac';
      case '.mp4':
        return 'video/mp4';
      case '.mpeg':
        return 'video/mpeg';
      case '.webm':
        return 'video/webm';
      case '.mov':
        return 'video/quicktime';
      case '.avi':
        return 'video/x-msvideo';
      case '.zip':
        return 'application/zip';
      case '.rar':
        return 'application/x-rar-compressed';
      case '.tar':
        return 'application/x-tar';
      case '.gz':
        return 'application/gzip';
      default:
        return 'application/octet-stream';
    }
  }

  /// Ensure WebSocket connection is established
  Future<void> _ensureConnection() async {
    await _webSocketService.connect();
    if (!_webSocketService.isConnected) {
      throw Exception('Failed to establish WebSocket connection');
    }
  }

  /// Clean up upload state
  void _cleanup(String? uploadId) {
    if (uploadId != null) {
      _activeUploads.remove(uploadId);
      if (uploadId == _currentUploadId) {
        _currentUploadId = null;
        _isUploading = false;
      }
    }
  }

  /// Cancel an active upload
  void cancelUpload(String? uploadId) {
    if (uploadId != null) {
      _cleanup(uploadId);
    } else if (_currentUploadId != null) {
      _cleanup(_currentUploadId);
    }
  }
}

/// Internal class to track upload state
class _UploadState {
  final String fileName;
  final int totalSize;
  final Function(int current, int total)? onProgress;
  final Function(dynamic result)? onComplete;
  final Function(String message)? onError;

  _UploadState({
    required this.fileName,
    required this.totalSize,
    this.onProgress,
    this.onComplete,
    this.onError,
  });
}
