import 'package:flutter/material.dart';

class FileTypeHelper {
  static IconData getIconForFileType(String fileType) {
    if (fileType.contains('image')) {
      return Icons.image;
    } else if (fileType.contains('video')) {
      return Icons.videocam;
    } else if (fileType.contains('audio')) {
      return Icons.audiotrack;
    } else if (fileType.contains('pdf')) {
      return Icons.picture_as_pdf;
    } else if (fileType.contains('doc') || fileType.contains('word')) {
      return Icons.description;
    } else if (fileType.contains('xls') || fileType.contains('sheet')) {
      return Icons.table_chart;
    } else if (fileType.contains('ppt') || fileType.contains('presentation')) {
      return Icons.slideshow;
    } else if (fileType.contains('zip') || fileType.contains('rar')) {
      return Icons.folder_zip;
    } else if (fileType.contains('text') || fileType.contains('txt')) {
      return Icons.text_snippet;
    } else {
      return Icons.insert_drive_file;
    }
  }

  static String getFileExtension(String fileName) {
    try {
      return fileName.split('.').last.toLowerCase();
    } catch (e) {
      return '';
    }
  }

  static bool isImageFile(String fileName) {
    final ext = getFileExtension(fileName);
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg'].contains(ext);
  }

  static bool isVideoFile(String fileName) {
    final ext = getFileExtension(fileName);
    return ['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm', 'mkv'].contains(ext);
  }

  static bool isAudioFile(String fileName) {
    final ext = getFileExtension(fileName);
    return ['mp3', 'wav', 'ogg', 'aac', 'flac', 'm4a'].contains(ext);
  }

  static bool isDocumentFile(String fileName) {
    final ext = getFileExtension(fileName);
    return [
      'pdf',
      'doc',
      'docx',
      'xls',
      'xlsx',
      'ppt',
      'pptx',
      'txt',
      'rtf',
    ].contains(ext);
  }

  static bool isTextFile(String fileName) {
    final ext = getFileExtension(fileName);
    return [
      'txt',
      'md',
      'json',
      'xml',
      'html',
      'htm',
      'css',
      'js',
      'ts',
      'dart',
      'java',
      'cpp',
      'c',
      'h',
      'py',
      'rb',
      'go',
      'rs',
      'php',
      'yaml',
      'yml',
      'log',
      'csv',
      'sql',
      'sh',
      'bat',
      'ini',
      'conf',
      'config',
      'properties',
      'gitignore',
      'dockerfile',
      'makefile',
      'readme',
      'license',
      'changelog',
    ].contains(ext);
  }

  static bool isTextFileByContentType(String? contentType) {
    if (contentType == null) return false;

    final type = contentType.toLowerCase();
    return type.startsWith('text/') ||
        type == 'application/json' ||
        type == 'application/xml' ||
        type == 'application/javascript' ||
        type == 'application/x-javascript' ||
        type.contains('text') ||
        type.contains('json') ||
        type.contains('xml');
  }

  static String getMimeType(String fileName) {
    final ext = getFileExtension(fileName);
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'svg':
        return 'image/svg+xml';
      case 'mp4':
        return 'video/mp4';
      case 'webm':
        return 'video/webm';
      case 'mov':
        return 'video/quicktime';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'ogg':
        return 'audio/ogg';
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
      case 'txt':
        return 'text/plain';
      case 'md':
        return 'text/markdown';
      case 'json':
        return 'application/json';
      case 'xml':
        return 'application/xml';
      case 'html':
      case 'htm':
        return 'text/html';
      case 'css':
        return 'text/css';
      case 'js':
        return 'application/javascript';
      case 'ts':
        return 'application/typescript';
      case 'yaml':
      case 'yml':
        return 'application/x-yaml';
      case 'csv':
        return 'text/csv';
      case 'log':
        return 'text/plain';
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/x-rar-compressed';
      default:
        return 'application/octet-stream';
    }
  }

  /// Formats a file size [bytes] into a human-readable string.
  ///
  /// Examples:
  ///  -  500 → "500 B"
  ///  - 15360 → "15.00 KB"
  ///  - 1048576 → "1.00 MB"
  static String formatFileSize(int bytes, {int decimals = 2}) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    final kb = bytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(decimals)} KB';
    }
    final mb = kb / 1024;
    if (mb < 1024) {
      return '${mb.toStringAsFixed(decimals)} MB';
    }
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(decimals)} GB';
  }

  /// Extracts the filename from a URL
  static String getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        return pathSegments.last;
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return 'File';
  }
}
