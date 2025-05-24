import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../services/api_file_service.dart';
import '../../../services/websocket_service.dart';
import '../../../utils/logger.dart';

/// Professional file upload handler that follows the proper REST API + WebSocket flow
class ProfessionalFileUploadHandler {
  final ApiFileService _apiFileService;
  final WebSocketService _webSocketService;
  final int chatRoomId;

  ProfessionalFileUploadHandler({
    required this.chatRoomId,
    required ApiFileService apiFileService,
    required WebSocketService webSocketService,
  })  : _apiFileService = apiFileService,
        _webSocketService = webSocketService;

  /// Pick and upload an image from gallery
  Future<void> pickAndUploadImage({
    required Function(double) onProgress,
    required Function() onComplete,
    required Function(String) onError,
  }) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image != null) {
        await _uploadFileWithRestApi(
          file: File(image.path),
          onProgress: onProgress,
          onComplete: onComplete,
          onError: onError,
        );
      }
    } catch (e) {
      AppLogger.e('ProfessionalFileUploadHandler', 'Error picking image: $e');
      onError('Failed to pick image: $e');
    }
  }

  /// Capture and upload an image from camera
  Future<void> captureAndUploadImage({
    required Function(double) onProgress,
    required Function() onComplete,
    required Function(String) onError,
  }) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image != null) {
        await _uploadFileWithRestApi(
          file: File(image.path),
          onProgress: onProgress,
          onComplete: onComplete,
          onError: onError,
        );
      }
    } catch (e) {
      AppLogger.e('ProfessionalFileUploadHandler', 'Error capturing image: $e');
      onError('Failed to capture image: $e');
    }
  }

  /// Pick and upload a video from gallery
  Future<void> pickAndUploadVideo({
    required Function(double) onProgress,
    required Function() onComplete,
    required Function(String) onError,
  }) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );

      if (video != null) {
        await _uploadFileWithRestApi(
          file: File(video.path),
          onProgress: onProgress,
          onComplete: onComplete,
          onError: onError,
        );
      }
    } catch (e) {
      AppLogger.e('ProfessionalFileUploadHandler', 'Error picking video: $e');
      onError('Failed to pick video: $e');
    }
  }

  /// Pick and upload a document
  Future<void> pickAndUploadDocument({
    required Function(double) onProgress,
    required Function() onComplete,
    required Function(String) onError,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        await _uploadFileWithRestApi(
          file: File(result.files.single.path!),
          onProgress: onProgress,
          onComplete: onComplete,
          onError: onError,
        );
      }
    } catch (e) {
      AppLogger.e('ProfessionalFileUploadHandler', 'Error picking document: $e');
      onError('Failed to pick document: $e');
    }
  }

  /// Upload file using the proper REST API + WebSocket flow
  Future<void> _uploadFileWithRestApi({
    required File file,
    required Function(double) onProgress,
    required Function() onComplete,
    required Function(String) onError,
  }) async {
    try {
      AppLogger.i(
        'ProfessionalFileUploadHandler',
        'Starting REST API upload for: ${file.path}',
      );

      // Step 1: Upload file via REST API to get the file URL
      final uploadResponse = await _apiFileService.uploadFile(
        file: file,
        chatRoomId: chatRoomId,
        onProgress: onProgress,
      );

      AppLogger.i(
        'ProfessionalFileUploadHandler',
        'File uploaded successfully via REST API: ${uploadResponse.fileUrl}',
      );

      // Step 2: Send the file URL as a message via WebSocket
      final success = await _webSocketService.sendMessage(
        roomId: chatRoomId,
        content: uploadResponse.fileUrl,
        contentType: uploadResponse.contentType,
      );

      if (success) {
        AppLogger.i(
          'ProfessionalFileUploadHandler',
          'File message sent successfully via WebSocket',
        );
        onComplete();
      } else {
        throw Exception('Failed to send file message via WebSocket');
      }
    } catch (e) {
      AppLogger.e(
        'ProfessionalFileUploadHandler',
        'Error in file upload flow: $e',
      );
      onError('Upload failed: $e');
    }
  }
}
