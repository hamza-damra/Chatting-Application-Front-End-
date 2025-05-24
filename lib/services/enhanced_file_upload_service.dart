import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import '../utils/logger.dart';
import 'websocket_service.dart';

/// Enum for different file categories
enum FileCategory { image, document, audio, video, other }

/// Enhanced service for handling file uploads via WebSocket with chunking
class EnhancedFileUploadService {
  static const int chunkSize = 64 * 1024; // 64KB chunks as recommended
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB limit

  final WebSocketService _webSocketService;
  final _supportedTypes = {
    FileCategory.image: ['.jpeg', '.jpg', '.png', '.gif'],
    FileCategory.document: ['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.txt'],
    FileCategory.audio: ['.mp3', '.wav'],
    FileCategory.video: ['.mp4', '.mpeg'],
  };

  // Upload state tracking
  bool _isUploading = false;
  String? _currentUploadId;
  final Map<String, _UploadState> _activeUploads = {};

  // Constructor
  EnhancedFileUploadService({required WebSocketService webSocketService})
    : _webSocketService = webSocketService;

  // Getters
  bool get isUploading => _isUploading;

  /// Get file category from extension
  FileCategory _getFileCategory(String fileName) {
    final extension = path.extension(fileName).toLowerCase();

    if (_supportedTypes[FileCategory.image]?.contains(extension) ?? false) {
      return FileCategory.image;
    }
    if (_supportedTypes[FileCategory.document]?.contains(extension) ?? false) {
      return FileCategory.document;
    }
    if (_supportedTypes[FileCategory.audio]?.contains(extension) ?? false) {
      return FileCategory.audio;
    }
    if (_supportedTypes[FileCategory.video]?.contains(extension) ?? false) {
      return FileCategory.video;
    }
    return FileCategory.other;
  }

  /// Upload a file with progress tracking and error handling
  Future<void> uploadFile(
    File file,
    int chatRoomId, {
    Function(int current, int total)? onProgress,
    Function(String url)? onComplete,
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
      final FileCategory fileCategory = _getFileCategory(fileName);

      // Validate file size
      if (fileSize > maxFileSize) {
        throw Exception(
          'File size (${_formatFileSize(fileSize)}) exceeds maximum allowed size (${_formatFileSize(maxFileSize)})',
        );
      }

      // Validate file type
      if (!_isFileTypeSupported(fileName, fileCategory)) {
        throw Exception('Unsupported file type: ${path.extension(fileName)}');
      }

      // Generate upload ID
      final String uploadId = const Uuid().v4();
      _currentUploadId = uploadId;

      // Create upload state
      _activeUploads[uploadId] = _UploadState(
        fileName: fileName,
        totalSize: fileSize,
        onProgress: onProgress,
        onComplete: onComplete,
        onError: onError,
      );

      // Register WebSocket callbacks
      _registerCallbacks(uploadId);

      // Start upload process
      await _uploadFileInChunks(file, fileName, fileSize, chatRoomId, uploadId);
    } catch (e) {
      AppLogger.e('EnhancedFileUploadService', 'Upload error: $e');
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

  /// Check if file type is supported
  bool _isFileTypeSupported(String fileName, FileCategory category) {
    final extension = path.extension(fileName).toLowerCase();
    return _supportedTypes[category]?.contains(extension) ?? false;
  }

  /// Register callbacks for WebSocket events
  void _registerCallbacks(String uploadId) {
    _webSocketService.registerFileCallbacks(
      uploadId,
      (currentChunk, totalChunks, serverUploadId) {
        final upload = _activeUploads[uploadId];
        if (upload != null) {
          upload.onProgress?.call(currentChunk, totalChunks);
        }
      },
      (response) {
        final upload = _activeUploads[uploadId];
        if (upload != null) {
          final String? url = response['attachmentUrl'];
          if (url != null) {
            upload.onComplete?.call(url);
          } else {
            upload.onError?.call('No attachment URL in response');
          }
        }
        _cleanup(uploadId);
      },
      (error) {
        final upload = _activeUploads[uploadId];
        if (upload != null) {
          upload.onError?.call(error);
        }
        _cleanup(uploadId);
      },
    );
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
      _isUploading = true;
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
      AppLogger.e('EnhancedFileUploadService', 'Chunk upload error: $e');
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
    final message = {
      'messageId': null,
      'chatRoomId': chatRoomId,
      'chunkIndex': chunkIndex,
      'totalChunks': totalChunks,
      'fileName': fileName,
      'contentType': _getContentType(fileName),
      'data': base64Data,
      'fileSize': fileSize,
      'uploadId': uploadId,
    };

    _webSocketService.sendCustomMessage(
      destination: '/app/file.chunk',
      body: jsonEncode(message),
    );
  }

  /// Get content type based on file extension
  String _getContentType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
      case '.docx':
        return 'application/msword';
      case '.xls':
      case '.xlsx':
        return 'application/vnd.ms-excel';
      case '.txt':
        return 'text/plain';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.mp4':
        return 'video/mp4';
      case '.mpeg':
        return 'video/mpeg';
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
      _webSocketService.unregisterFileCallbacks(uploadId);
      _activeUploads.remove(uploadId);
      if (uploadId == _currentUploadId) {
        _currentUploadId = null;
        _isUploading = false;
      }
    }
  }

  /// Cancel an active upload
  void cancelUpload(String uploadId) {
    _cleanup(uploadId);
  }
}

/// Internal class to track upload state
class _UploadState {
  final String fileName;
  final int totalSize;
  final Function(int current, int total)? onProgress;
  final Function(String url)? onComplete;
  final Function(String message)? onError;

  _UploadState({
    required this.fileName,
    required this.totalSize,
    this.onProgress,
    this.onComplete,
    this.onError,
  });
}
