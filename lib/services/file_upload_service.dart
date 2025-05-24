import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:path/path.dart' as path;
import '../utils/logger.dart';
import 'websocket_service.dart';

/// Enum for file types that can be picked
enum FilePickerType { image, document, audio, video, any }

/// Service for handling file uploads via WebSocket
class FileUploadService {
  static const int chunkSize = 64 * 1024; // 64KB chunks
  final WebSocketService _webSocketService;

  // Upload state
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _statusMessage = '';

  // Callbacks
  Function(double)? onProgressUpdate;
  Function(String)? onComplete;
  Function(String)? onError;

  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String get statusMessage => _statusMessage;

  FileUploadService(this._webSocketService) {
    // Set up handlers for WebSocket responses
    _setupHandlers();
  }

  /// Set up handlers for WebSocket file upload responses
  void _setupHandlers() {
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
  void _handleFileProgress(StompFrame frame) {
    try {
      final progress = jsonDecode(frame.body!);

      AppLogger.i(
        'FileUploadService',
        'Progress update: ${progress['chunkIndex']}/${progress['totalChunks']}',
      );

      _uploadProgress = progress['chunkIndex'] / progress['totalChunks'];
      _statusMessage =
          'Uploading: ${(_uploadProgress * 100).toInt()}% (${progress['chunkIndex']}/${progress['totalChunks']})';
      onProgressUpdate?.call(_uploadProgress);
    } catch (e) {
      AppLogger.e('FileUploadService', 'Error handling progress update: $e');
    }
  }

  /// Handle file upload completion notification
  void _handleFileComplete(StompFrame frame) {
    try {
      final response = jsonDecode(frame.body!);

      AppLogger.i(
        'FileUploadService',
        'Upload complete: ${response['fileName']} -> ${response['attachmentUrl']}',
      );

      _isUploading = false;
      _uploadProgress = 1.0;
      _statusMessage = 'Upload complete!';
      onProgressUpdate?.call(_uploadProgress);
      onComplete?.call(response['attachmentUrl']);
    } catch (e) {
      AppLogger.e('FileUploadService', 'Error handling upload completion: $e');
    }
  }

  /// Handle error notifications
  void _handleError(StompFrame frame) {
    try {
      final errorData = jsonDecode(frame.body!);
      final errorMessage = errorData['message'] ?? 'Unknown error';

      AppLogger.e('FileUploadService', 'Error from server: $errorMessage');

      _isUploading = false;
      _statusMessage = 'Error: $errorMessage';
      onError?.call(errorMessage);
    } catch (e) {
      AppLogger.e('FileUploadService', 'Error handling error notification: $e');
    }
  }

  /// Pick a file and upload it to the specified chat room
  Future<void> pickAndUploadFile(
    int chatRoomId, {
    FilePickerType type = FilePickerType.image,
  }) async {
    if (!_webSocketService.isConnected) {
      final errorMsg = 'Not connected to server. Attempting to connect...';
      AppLogger.e('FileUploadService', errorMsg);
      onError?.call(errorMsg);

      // Try to connect
      await _webSocketService.connect();

      // Check if connection was successful
      if (!_webSocketService.isConnected) {
        final errorMsg = 'Failed to connect to server. Please try again later.';
        AppLogger.e('FileUploadService', errorMsg);
        onError?.call(errorMsg);
        return;
      }
    }

    File? file;
    String? fileName;
    String? mimeType;

    // Since we can't use file_picker, we'll use image_picker for all types
    // and inform the user about the limitations
    final ImagePicker imagePicker = ImagePicker();
    XFile? pickedFile;

    // Show appropriate message based on the requested type
    switch (type) {
      case FilePickerType.image:
        pickedFile = await imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85, // Higher quality to ensure better image data
          maxWidth: 1200, // Limit width to ensure reasonable file size
          maxHeight: 1200, // Limit height to ensure reasonable file size
          requestFullMetadata: false,
        );
        break;

      case FilePickerType.video:
        pickedFile = await imagePicker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(minutes: 10), // Limit video length
        );
        break;

      case FilePickerType.document:
      case FilePickerType.audio:
      case FilePickerType.any:
        // For document, audio, and any other types, we'll use pickImage as a fallback
        // and inform the user about the limitation
        onError?.call(
          'Only images and videos are supported in this version. Please select an image or video file.',
        );
        pickedFile = await imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1200,
          maxHeight: 1200,
          requestFullMetadata: false,
        );
        break;
    }

    if (pickedFile == null) {
      return; // User canceled the picker
    }

    file = File(pickedFile.path);
    fileName = path.basename(pickedFile.path);

    // Determine MIME type based on file extension and content
    mimeType = lookupMimeType(file.path);

    // Fallback MIME type based on file type
    if (mimeType == null) {
      final extension = path.extension(fileName).toLowerCase();
      if (extension.contains('.jpg') || extension.contains('.jpeg')) {
        mimeType = 'image/jpeg';
      } else if (extension.contains('.png')) {
        mimeType = 'image/png';
      } else if (extension.contains('.mp4')) {
        mimeType = 'video/mp4';
      } else if (extension.contains('.mov')) {
        mimeType = 'video/quicktime';
      } else {
        mimeType = 'application/octet-stream';
      }
    }

    try {
      // Validate that the file exists and is readable
      if (!await file.exists()) {
        throw Exception('Selected file does not exist');
      }

      // Check file size
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        // 10MB limit
        throw Exception('File size exceeds the maximum allowed (10MB)');
      }

      // Start upload
      _isUploading = true;
      _uploadProgress = 0.0;
      _statusMessage = 'Preparing upload...';
      onProgressUpdate?.call(_uploadProgress);

      AppLogger.i(
        'FileUploadService',
        'Starting file upload: $fileName ($fileSize bytes)',
      );

      // Calculate total chunks
      final totalChunks = (fileSize / chunkSize).ceil();

      // Upload chunks
      for (int chunkIndex = 1; chunkIndex <= totalChunks; chunkIndex++) {
        // Calculate chunk boundaries
        final startPos = ((chunkIndex - 1) * chunkSize).toInt();
        int endPos = startPos + chunkSize;
        if (endPos > fileSize) endPos = fileSize;

        // Read chunk
        final reader = await file.open(mode: FileMode.read);
        await reader.setPosition(startPos);
        final buffer = await reader.read(endPos - startPos);
        await reader.close();

        // Validate buffer data
        if (buffer.isEmpty) {
          throw Exception('Empty data chunk read from file');
        }

        // Convert to base64 with proper padding
        final base64data = base64Encode(buffer);

        // Validate base64 data
        if (base64data.isEmpty) {
          throw Exception('Failed to encode image data to base64');
        }

        // Create chunk payload
        final chunk = {
          'chatRoomId': chatRoomId,
          'chunkIndex': chunkIndex,
          'totalChunks': totalChunks,
          'fileName': fileName,
          'contentType': mimeType,
          'fileSize': fileSize,
          'data': base64data,
        };

        AppLogger.i(
          'FileUploadService',
          'Sending chunk $chunkIndex/$totalChunks for $fileName',
        );

        // Send chunk
        _webSocketService.sendCustomMessage(
          destination: '/app/file.chunk',
          body: jsonEncode(chunk),
        );

        // Update progress (for UI feedback even before server responds)
        _uploadProgress = chunkIndex / totalChunks;
        _statusMessage =
            'Uploading: ${(_uploadProgress * 100).toInt()}% ($chunkIndex/$totalChunks)';
        onProgressUpdate?.call(_uploadProgress);

        // Small delay to prevent overwhelming the server
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      _isUploading = false;
      final errorMsg = 'Error uploading file: $e';
      AppLogger.e('FileUploadService', errorMsg);
      onError?.call(errorMsg);
    }
  }
}
