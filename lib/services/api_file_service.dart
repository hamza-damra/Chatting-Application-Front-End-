import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import '../config/api_config.dart';
import '../core/services/token_service.dart';
import '../utils/logger.dart';

class ApiFileService {
  final TokenService _tokenService;
  late final Dio _dio;

  ApiFileService({required TokenService tokenService})
    : _tokenService = tokenService {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(
          seconds: 60,
        ), // Longer timeout for file uploads
      ),
    );

    // Add interceptor for automatic token handling
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_tokenService.accessToken != null) {
            options.headers['Authorization'] =
                'Bearer ${_tokenService.accessToken}';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Handle token refresh on 401 errors
          if (error.response?.statusCode == 401) {
            try {
              final refreshed = await _tokenService.refreshAccessToken();
              if (refreshed) {
                // Retry the request with the new token
                error.requestOptions.headers['Authorization'] =
                    'Bearer ${_tokenService.accessToken}';
                final response = await _dio.fetch(error.requestOptions);
                return handler.resolve(response);
              }
            } catch (e) {
              AppLogger.e('ApiFileService', 'Error refreshing token: $e');
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Upload a file via REST API with real progress tracking using Dio
  Future<FileUploadResponse> uploadFile({
    required File file,
    required int chatRoomId,
    Function(double)? onProgress,
  }) async {
    try {
      AppLogger.i(
        'ApiFileService',
        'Starting file upload via REST API with Dio',
      );

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

      // Validate file size (1GB limit)
      if (fileSize > 1024 * 1024 * 1024) {
        throw Exception('File size exceeds 1GB limit');
      }

      // Create FormData for multipart upload
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: MediaType.parse(contentType),
        ),
        'chatRoomId': chatRoomId.toString(),
      });

      AppLogger.i(
        'ApiFileService',
        'Sending Dio multipart request to: ${ApiConfig.filesEndpoint}/upload',
      );

      // Send request with progress tracking
      final response = await _dio.post(
        '${ApiConfig.filesEndpoint}/upload',
        data: formData,
        onSendProgress: (int sent, int total) {
          if (onProgress != null && total > 0) {
            final progress = sent / total;
            AppLogger.d(
              'ApiFileService',
              'Upload progress: ${(progress * 100).toStringAsFixed(1)}% ($sent/$total bytes)',
            );
            onProgress(progress);
          }
        },
        options: Options(
          headers: {'Accept': 'application/json'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      AppLogger.i(
        'ApiFileService',
        'Upload response status: ${response.statusCode}',
      );
      AppLogger.d('ApiFileService', 'Upload response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final fileUploadResponse = FileUploadResponse.fromJson(response.data);
        AppLogger.i(
          'ApiFileService',
          'File uploaded successfully: ${fileUploadResponse.fileUrl}',
        );

        return fileUploadResponse;
      } else {
        String errorMessage = 'File upload failed: ${response.statusCode}';
        if (response.data != null) {
          try {
            final errorData = response.data;
            if (errorData is Map<String, dynamic>) {
              errorMessage =
                  errorData['message'] ?? errorData['error'] ?? errorMessage;
            } else {
              errorMessage = '$errorMessage - ${response.data}';
            }
          } catch (e) {
            errorMessage = '$errorMessage - ${response.data}';
          }
        }
        throw Exception(errorMessage);
      }
    } on DioException catch (e) {
      AppLogger.e('ApiFileService', 'Dio upload error: ${e.message}');

      String errorMessage = 'File upload failed';
      if (e.response?.data != null) {
        try {
          final errorData = e.response!.data;
          if (errorData is Map<String, dynamic>) {
            errorMessage =
                errorData['message'] ??
                errorData['error'] ??
                e.message ??
                errorMessage;
          }
        } catch (_) {
          errorMessage = e.message ?? errorMessage;
        }
      } else {
        errorMessage = e.message ?? errorMessage;
      }

      throw Exception(errorMessage);
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
