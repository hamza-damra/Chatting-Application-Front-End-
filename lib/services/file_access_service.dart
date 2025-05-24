import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../config/api_config.dart';
import '../utils/logger.dart';
import '../core/services/token_service.dart';

enum FileCategory { image, document, audio, video, other }

class FileStorageStats {
  final int totalFiles;
  final int totalSize;
  final Map<String, int> fileCountByCategory;
  final Map<String, int> fileSizeByCategory;

  FileStorageStats({
    required this.totalFiles,
    required this.totalSize,
    required this.fileCountByCategory,
    required this.fileSizeByCategory,
  });

  factory FileStorageStats.fromJson(Map<String, dynamic> json) {
    return FileStorageStats(
      totalFiles: json['totalFiles'] ?? 0,
      totalSize: json['totalSize'] ?? 0,
      fileCountByCategory: Map<String, int>.from(
        json['fileCountByCategory'] ?? {},
      ),
      fileSizeByCategory: Map<String, int>.from(
        json['fileSizeByCategory'] ?? {},
      ),
    );
  }
}

class FileAccessService {
  final Dio _dio;
  final TokenService _tokenService;

  FileAccessService({required TokenService tokenService})
    : _tokenService = tokenService,
      _dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

  /// Get a file by category and filename
  Future<File> getFileByCategory({
    required FileCategory category,
    required String filename,
  }) async {
    try {
      final categoryStr = category.toString().split('.').last;
      final endpoint =
          '${ApiConfig.filesEndpoint}/category/$categoryStr/$filename';

      // Create a temporary file to store the downloaded file
      final tempDir = await getTemporaryDirectory();
      final localFile = File('${tempDir.path}/$filename');

      // Download the file
      final response = await _dio.get(
        endpoint,
        options: Options(
          headers: ApiConfig.getAuthHeaders(_tokenService.accessToken!),
          responseType: ResponseType.bytes,
        ),
      );

      // Write the file to local storage
      await localFile.writeAsBytes(response.data);

      return localFile;
    } catch (e) {
      AppLogger.e('FileAccessService', 'Error getting file by category: $e');
      rethrow;
    }
  }

  /// Get file storage statistics
  Future<FileStorageStats> getFileStorageStats() async {
    try {
      final response = await _dio.get(
        '${ApiConfig.filesEndpoint}/status',
        options: Options(
          headers: ApiConfig.getAuthHeaders(_tokenService.accessToken!),
        ),
      );

      return FileStorageStats.fromJson(response.data);
    } catch (e) {
      AppLogger.e('FileAccessService', 'Error getting file storage stats: $e');
      rethrow;
    }
  }

  /// Get all files by category
  Future<List<String>> getFilesByCategory(FileCategory category) async {
    try {
      final categoryStr = category.toString().split('.').last;
      final endpoint = '${ApiConfig.filesEndpoint}/category/$categoryStr';

      final response = await _dio.get(
        endpoint,
        options: Options(
          headers: ApiConfig.getAuthHeaders(_tokenService.accessToken!),
        ),
      );

      return List<String>.from(response.data);
    } catch (e) {
      AppLogger.e('FileAccessService', 'Error getting files by category: $e');
      return [];
    }
  }
}
