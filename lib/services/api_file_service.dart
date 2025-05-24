import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import '../config/api_config.dart';
import '../core/services/token_service.dart';
import '../utils/logger.dart';

class ApiFileService {
  final TokenService _tokenService;

  ApiFileService({required TokenService tokenService})
    : _tokenService = tokenService;

  /// Upload a file via REST API
  Future<FileUploadResponse> uploadFile({
    required File file,
    required int chatRoomId,
    Function(double)? onProgress,
  }) async {
    try {
      AppLogger.i('ApiFileService', 'Starting file upload via REST API');

      // Ensure we have a valid token
      await _ensureValidToken();

      // Validate file exists
      if (!await file.exists()) {
        throw Exception('File does not exist: ${file.path}');
      }

      // Get file info
      final fileName = path.basename(file.path);
      final fileSize = await file.length();
      final contentType = _getContentType(fileName);

      AppLogger.i(
        'ApiFileService',
        'Uploading file: $fileName ($fileSize bytes) - Type: $contentType',
      );

      // Validate file type is supported
      if (!_isFileTypeSupported(fileName)) {
        throw Exception(
          'File type not supported. Supported types: JPG, PNG, GIF, PDF, TXT, DOC, DOCX, MP3, WAV, MP4, MOV',
        );
      }

      // Validate file size (10MB limit)
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('File size exceeds 10MB limit');
      }

      // Create multipart request to the exact backend endpoint
      final uploadUrl = '${ApiConfig.baseUrl}${ApiConfig.filesEndpoint}/upload';
      AppLogger.d('ApiFileService', 'Upload URL: $uploadUrl');

      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer ${_tokenService.accessToken}',
        'Accept': 'application/json',
      });

      // Add file with explicit content type
      final mediaType = MediaType.parse(contentType);
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: fileName,
        contentType: mediaType,
      );

      // Log the actual content type being sent
      AppLogger.d(
        'ApiFileService',
        'Multipart file content type: ${multipartFile.contentType}',
      );
      AppLogger.d('ApiFileService', 'Expected content type: $contentType');
      AppLogger.d('ApiFileService', 'MediaType: ${mediaType.toString()}');

      request.files.add(multipartFile);

      // Add chat room ID
      request.fields['chatRoomId'] = chatRoomId.toString();

      AppLogger.i(
        'ApiFileService',
        'Sending multipart request to: ${request.url}',
      );
      AppLogger.d('ApiFileService', 'Request headers: ${request.headers}');
      AppLogger.d('ApiFileService', 'Request fields: ${request.fields}');

      // Send request with progress tracking
      var streamedResponse = await request.send();

      // Get response body
      var responseBody = await streamedResponse.stream.bytesToString();

      AppLogger.i(
        'ApiFileService',
        'Upload response status: ${streamedResponse.statusCode}',
      );
      AppLogger.d('ApiFileService', 'Upload response body: $responseBody');

      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 201) {
        var jsonResponse = json.decode(responseBody);

        final response = FileUploadResponse.fromJson(jsonResponse);
        AppLogger.i(
          'ApiFileService',
          'File uploaded successfully: ${response.fileUrl}',
        );

        return response;
      } else {
        String errorMessage =
            'File upload failed: ${streamedResponse.statusCode}';
        if (responseBody.isNotEmpty) {
          try {
            var errorJson = json.decode(responseBody);
            errorMessage =
                errorJson['message'] ?? errorJson['error'] ?? errorMessage;
          } catch (e) {
            errorMessage = '$errorMessage - $responseBody';
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      AppLogger.e('ApiFileService', 'File upload error: $e');
      throw Exception('File upload failed: $e');
    }
  }

  /// Ensure we have a valid token
  Future<void> _ensureValidToken() async {
    if (_tokenService.accessToken == null) {
      throw Exception('No access token available');
    }

    if (_tokenService.isTokenExpired) {
      AppLogger.i('ApiFileService', 'Token expired, attempting refresh');
      final refreshed = await _tokenService.refreshAccessToken();
      if (!refreshed) {
        throw Exception('Failed to refresh access token');
      }
    }
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
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/mp4'; // Backend expects video/mp4 or video/mpeg
      case '.avi':
        return 'video/mpeg';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.txt':
        return 'text/plain';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.m4a':
        return 'audio/mp4';
      default:
        return 'application/octet-stream';
    }
  }

  /// Validate if file type is supported by backend
  bool _isFileTypeSupported(String fileName) {
    final extension = path.extension(fileName).toLowerCase();

    // Based on backend validation, these are the supported types
    const supportedExtensions = {
      // Images
      '.jpg', '.jpeg', '.png', '.gif',
      // Documents
      '.pdf', '.txt', '.doc', '.docx',
      // Audio
      '.mp3', '.wav',
      // Video
      '.mp4', '.mov',
    };

    return supportedExtensions.contains(extension);
  }
}

class FileUploadResponse {
  final int? id;
  final String fileName;
  final String? originalFileName;
  final String fileUrl;
  final String? downloadUrl;
  final String contentType;
  final int fileSize;
  final String? uploadedAt;
  final String? storageLocation;

  FileUploadResponse({
    this.id,
    required this.fileName,
    this.originalFileName,
    required this.fileUrl,
    this.downloadUrl,
    required this.contentType,
    required this.fileSize,
    this.uploadedAt,
    this.storageLocation,
  });

  factory FileUploadResponse.fromJson(Map<String, dynamic> json) {
    return FileUploadResponse(
      id: json['id'],
      fileName: json['fileName'] ?? json['name'] ?? 'unknown',
      originalFileName: json['originalFileName'],
      fileUrl: json['fileUrl'] ?? json['url'] ?? json['downloadUrl'] ?? '',
      downloadUrl: json['downloadUrl'],
      contentType:
          json['contentType'] ?? json['mimeType'] ?? 'application/octet-stream',
      fileSize: json['fileSize'] ?? json['size'] ?? 0,
      uploadedAt: json['uploadedAt'],
      storageLocation: json['storageLocation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'originalFileName': originalFileName,
      'fileUrl': fileUrl,
      'downloadUrl': downloadUrl,
      'contentType': contentType,
      'fileSize': fileSize,
      'uploadedAt': uploadedAt,
      'storageLocation': storageLocation,
    };
  }
}
