import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../utils/logger.dart';
import 'websocket_service.dart';

/// Result class for file upload operations
class FileUploadResult {
  final String url;
  final String contentType;

  FileUploadResult({required this.url, required this.contentType});
}

/// A service for handling file uploads with progress tracking
class ImprovedFileUploadService {
  final String baseUrl;
  final Map<String, String> headers;
  final WebSocketService webSocketService;
  bool _isCancelled = false;

  // Constants for file upload
  static const int chunkSize = 64 * 1024; // 64KB chunks as recommended
  static const int maxFileSize = 1024 * 1024 * 1024; // 1GB max file size

  // File type categories
  static const Map<String, List<String>> supportedFileTypes = {
    'image': ['jpg', 'jpeg', 'png', 'gif'],
    'document': ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
    'audio': ['mp3', 'wav'],
    'video': ['mp4', 'mpeg'],
  };

  ImprovedFileUploadService({
    required this.baseUrl,
    required this.headers,
    required this.webSocketService,
  });

  /// Pick and upload an image file
  Future<FileUploadResult> pickAndUploadImage({
    required int roomId,
    required void Function(double) onProgress,
  }) async {
    _isCancelled = false;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) {
      throw Exception('No image selected');
    }

    // Validate file size
    final fileSize = await File(image.path).length();
    if (fileSize > maxFileSize) {
      throw Exception('File size exceeds limit of 1GB');
    }

    // Extract extension and normalize it
    final extension =
        path.extension(image.path).replaceAll('.', '').toLowerCase();

    // Server might only accept specific image formats
    // Convert extension to a standard format
    String contentType;
    if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
      // Special handling for jpg - use jpeg MIME type instead since that's what servers expect
      if (extension == 'jpg') {
        contentType = 'image/jpeg';
      } else {
        contentType = 'image/$extension';
      }
    } else {
      // Default to png if not a common format
      contentType = 'image/png';
    }

    return _uploadFileWithWebSocket(
      file: File(image.path),
      fileName: path.basename(image.path),
      contentType: contentType,
      roomId: roomId,
      onProgress: onProgress,
    );
  }

  /// Pick and upload an image file from camera
  Future<FileUploadResult> captureAndUploadImage({
    required int roomId,
    required void Function(double) onProgress,
  }) async {
    _isCancelled = false;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image == null) {
      throw Exception('No image captured');
    }

    // Validate file size
    final fileSize = await File(image.path).length();
    if (fileSize > maxFileSize) {
      throw Exception('File size exceeds limit of 1GB');
    }

    // Extract extension and normalize it
    final extension =
        path.extension(image.path).replaceAll('.', '').toLowerCase();

    // Server might only accept specific image formats
    final imageType = extension == 'jpg' ? 'jpeg' : extension;
    final contentType = 'image/$imageType';

    return _uploadFileWithWebSocket(
      file: File(image.path),
      fileName: path.basename(image.path),
      contentType: contentType,
      roomId: roomId,
      onProgress: onProgress,
    );
  }

  /// Pick and upload a video file
  Future<FileUploadResult> pickAndUploadVideo({
    required int roomId,
    required void Function(double) onProgress,
  }) async {
    _isCancelled = false;

    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);

    if (video == null) {
      throw Exception('No video selected');
    }

    // Validate file size
    final fileSize = await File(video.path).length();
    if (fileSize > maxFileSize) {
      throw Exception('File size exceeds limit of 1GB');
    }

    return _uploadFileWithWebSocket(
      file: File(video.path),
      fileName: path.basename(video.path),
      contentType: 'video/${path.extension(video.path).replaceAll('.', '')}',
      roomId: roomId,
      onProgress: onProgress,
    );
  }

  /// Pick and upload an audio file
  Future<FileUploadResult> pickAndUploadAudio({
    required int roomId,
    required void Function(double) onProgress,
  }) async {
    _isCancelled = false;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      throw Exception('No audio file selected');
    }

    final file = File(result.files.first.path!);

    // Validate file size
    final fileSize = await file.length();
    if (fileSize > maxFileSize) {
      throw Exception('File size exceeds limit of 1GB');
    }

    return _uploadFileWithWebSocket(
      file: file,
      fileName: result.files.first.name,
      contentType:
          'audio/${path.extension(result.files.first.path!).replaceAll('.', '')}',
      roomId: roomId,
      onProgress: onProgress,
    );
  }

  /// Pick and upload a document file (PDF, DOC, etc.)
  Future<FileUploadResult> pickAndUploadDocument({
    required int roomId,
    required void Function(double) onProgress,
  }) async {
    _isCancelled = false;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      throw Exception('No document selected');
    }

    final file = File(result.files.first.path!);

    // Validate file size
    final fileSize = await file.length();
    if (fileSize > maxFileSize) {
      throw Exception('File size exceeds limit of 1GB');
    }

    final extension =
        path
            .extension(result.files.first.path!)
            .replaceAll('.', '')
            .toLowerCase();
    String contentType = 'application/octet-stream';

    // Determine the content type based on extension
    if (extension == 'pdf') {
      contentType = 'application/pdf';
    } else if (extension == 'doc' || extension == 'docx') {
      contentType = 'application/msword';
    } else if (extension == 'xls' || extension == 'xlsx') {
      contentType = 'application/vnd.ms-excel';
    } else if (extension == 'txt') {
      contentType = 'text/plain';
    }

    // Log the content type we're using
    AppLogger.i(
      'FileUploadService',
      'Uploading document with content type: $contentType for extension: $extension',
    );

    return _uploadFileWithWebSocket(
      file: file,
      fileName: result.files.first.name,
      contentType: contentType,
      roomId: roomId,
      onProgress: onProgress,
    );
  }

  /// Pick and upload any file type
  Future<FileUploadResult> pickAndUploadAnyFile({
    required int roomId,
    required void Function(double) onProgress,
  }) async {
    _isCancelled = false;

    final result = await FilePicker.platform.pickFiles(allowMultiple: false);

    if (result == null || result.files.isEmpty) {
      throw Exception('No file selected');
    }

    final file = File(result.files.first.path!);

    // Validate file size
    final fileSize = await file.length();
    if (fileSize > maxFileSize) {
      throw Exception('File size exceeds limit of 1GB');
    }

    // Get file extension and determine proper MIME type
    final extension = result.files.first.extension?.toLowerCase() ?? '';
    String contentType;

    // Common MIME types that the server accepts
    if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
      // Special handling for jpg - use jpeg MIME type instead since that's what servers expect
      if (extension == 'jpg') {
        contentType = 'image/jpeg';
      } else {
        contentType = 'image/$extension';
      }
    } else if (['mp4', 'mpeg', 'mov'].contains(extension)) {
      contentType = 'video/$extension';
    } else if (['mp3', 'wav', 'ogg'].contains(extension)) {
      contentType = 'audio/$extension';
    } else if (extension == 'pdf') {
      contentType = 'application/pdf';
    } else if (['doc', 'docx'].contains(extension)) {
      contentType = 'application/msword';
    } else if (['xls', 'xlsx'].contains(extension)) {
      contentType = 'application/vnd.ms-excel';
    } else if (extension == 'txt') {
      contentType = 'text/plain';
    } else {
      // Default
      contentType = 'application/octet-stream';
    }

    return _uploadFileWithWebSocket(
      file: file,
      fileName: result.files.first.name,
      contentType: contentType,
      roomId: roomId,
      onProgress: onProgress,
    );
  }

  /// Internal method to upload file using WebSocket chunking
  Future<FileUploadResult> _uploadFileWithWebSocket({
    required File file,
    required String fileName,
    required String contentType,
    required int roomId,
    required void Function(double) onProgress,
  }) async {
    _isCancelled = false;

    // The file path might be different from the original filename
    // Let's use the provided fileName instead of extracting from the file path
    final sanitizedFileName = fileName.replaceAll(' ', '_');

    try {
      final result = await webSocketService.uploadFileWithProgress(
        file: file,
        fileName: sanitizedFileName,
        contentType: contentType,
        roomId: roomId,
        onProgress: onProgress,
        onCancel: () => _isCancelled,
      );

      if (result.isEmpty) {
        throw Exception('File upload failed - empty result from server');
      }

      return FileUploadResult(url: result, contentType: contentType);
    } catch (e) {
      // Rethrow with more context
      throw Exception('File upload failed: $e');
    }
  }

  /// Cancel the current upload operation
  void cancelUpload() {
    _isCancelled = true;
    // Additional cleanup can be added here if needed
  }
}
