import 'dart:io';
import '../services/api_file_service.dart';
import '../services/websocket_service.dart';
import '../utils/logger.dart';

class ImprovedChatService {
  final ApiFileService _fileService;
  final WebSocketService _webSocketService;

  ImprovedChatService({
    required ApiFileService fileService,
    required WebSocketService webSocketService,
  }) : _fileService = fileService,
       _webSocketService = webSocketService;

  /// Send a text message via WebSocket
  Future<bool> sendTextMessage({
    required int chatRoomId,
    required String content,
  }) async {
    try {
      AppLogger.i(
        'ImprovedChatService',
        'Sending text message to room $chatRoomId',
      );

      return await _webSocketService.sendMessage(
        roomId: chatRoomId,
        content: content,
        contentType: 'text/plain',
      );
    } catch (e) {
      AppLogger.e('ImprovedChatService', 'Error sending text message: $e');
      rethrow;
    }
  }

  /// Send an image message (upload file first, then send via WebSocket)
  Future<bool> sendImageMessage({
    required int chatRoomId,
    required File imageFile,
    Function(double)? onUploadProgress,
  }) async {
    try {
      AppLogger.i(
        'ImprovedChatService',
        'Starting image message flow for room $chatRoomId',
      );

      // Step 1: Upload file via REST API
      AppLogger.i(
        'ImprovedChatService',
        'Step 1: Uploading image via REST API',
      );
      final uploadResponse = await _fileService.uploadFile(
        file: imageFile,
        chatRoomId: chatRoomId,
        onProgress: onUploadProgress,
      );

      AppLogger.i(
        'ImprovedChatService',
        'Image uploaded successfully: ${uploadResponse.fileUrl}',
      );

      // Step 2: Send message with file URL via WebSocket
      AppLogger.i(
        'ImprovedChatService',
        'Step 2: Sending image message via WebSocket',
      );

      // ✅ CORRECT: Send the actual file URL, not a file path
      return await _webSocketService.sendMessage(
        roomId: chatRoomId,
        content: uploadResponse.fileUrl, // Use the actual file URL from server
        contentType: uploadResponse.contentType,
      );
    } catch (e) {
      AppLogger.e('ImprovedChatService', 'Error sending image message: $e');
      rethrow;
    }
  }

  /// Send a video message (upload file first, then send via WebSocket)
  Future<bool> sendVideoMessage({
    required int chatRoomId,
    required File videoFile,
    Function(double)? onUploadProgress,
  }) async {
    try {
      AppLogger.i(
        'ImprovedChatService',
        'Starting video message flow for room $chatRoomId',
      );

      // Step 1: Upload file via REST API
      final uploadResponse = await _fileService.uploadFile(
        file: videoFile,
        chatRoomId: chatRoomId,
        onProgress: onUploadProgress,
      );

      AppLogger.i(
        'ImprovedChatService',
        'Video uploaded successfully: ${uploadResponse.fileUrl}',
      );

      // Step 2: Send message with file URL via WebSocket
      return await _webSocketService.sendMessage(
        roomId: chatRoomId,
        content: uploadResponse.fileUrl,
        contentType: uploadResponse.contentType,
      );
    } catch (e) {
      AppLogger.e('ImprovedChatService', 'Error sending video message: $e');
      rethrow;
    }
  }

  /// Send a document message (upload file first, then send via WebSocket)
  Future<bool> sendDocumentMessage({
    required int chatRoomId,
    required File documentFile,
    Function(double)? onUploadProgress,
  }) async {
    try {
      AppLogger.i(
        'ImprovedChatService',
        'Starting document message flow for room $chatRoomId',
      );

      // Step 1: Upload file via REST API
      final uploadResponse = await _fileService.uploadFile(
        file: documentFile,
        chatRoomId: chatRoomId,
        onProgress: onUploadProgress,
      );

      AppLogger.i(
        'ImprovedChatService',
        'Document uploaded successfully: ${uploadResponse.fileUrl}',
      );

      // Step 2: Send message with file URL via WebSocket
      return await _webSocketService.sendMessage(
        roomId: chatRoomId,
        content: uploadResponse.fileUrl,
        contentType: uploadResponse.contentType,
      );
    } catch (e) {
      AppLogger.e('ImprovedChatService', 'Error sending document message: $e');
      rethrow;
    }
  }

  /// Send any file message (upload file first, then send via WebSocket)
  Future<bool> sendFileMessage({
    required int chatRoomId,
    required File file,
    Function(double)? onUploadProgress,
  }) async {
    try {
      AppLogger.i(
        'ImprovedChatService',
        'Starting file message flow for room $chatRoomId',
      );

      // Step 1: Upload file via REST API
      final uploadResponse = await _fileService.uploadFile(
        file: file,
        chatRoomId: chatRoomId,
        onProgress: onUploadProgress,
      );

      AppLogger.i(
        'ImprovedChatService',
        'File uploaded successfully: ${uploadResponse.fileUrl}',
      );

      // Step 2: Send message with file URL via WebSocket
      return await _webSocketService.sendMessage(
        roomId: chatRoomId,
        content: uploadResponse.fileUrl,
        contentType: uploadResponse.contentType,
      );
    } catch (e) {
      AppLogger.e('ImprovedChatService', 'Error sending file message: $e');
      rethrow;
    }
  }

  /// Check if WebSocket is connected
  bool get isConnected => _webSocketService.isConnected;

  /// Connect to WebSocket
  Future<void> connect() async {
    await _webSocketService.connect();
  }

  /// Disconnect from WebSocket
  void disconnect() {
    _webSocketService.disconnect();
  }
}
