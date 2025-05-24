import 'package:flutter/material.dart';
import '../utils/logger.dart';

class FileAttachmentWidget extends StatelessWidget {
  final String? attachmentUrl;
  final String? contentType;
  final Function()? onTap;
  final double size;
  final bool showFileName;
  final String? fileName;

  const FileAttachmentWidget({
    super.key,
    required this.attachmentUrl,
    this.contentType,
    this.onTap,
    this.size = 200,
    this.showFileName = true,
    this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    if (attachmentUrl == null || attachmentUrl!.isEmpty) {
      return const SizedBox();
    }

    final fileType = _getFileType();
    final displayName = fileName ?? _getDisplayName();
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: size,
          minWidth: 120,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // File type icon
            Container(
              height: size * 0.6,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _getColorForFileType(fileType),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Icon(
                  _getIconForFileType(fileType),
                  size: size * 0.3,
                  color: Colors.white,
                ),
              ),
            ),
            
            // File name
            if (showFileName && displayName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  displayName,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getFileType() {
    if (contentType != null) {
      return contentType!;
    }
    
    final extension = attachmentUrl!.split('.').last.toLowerCase();
    
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg', 'bmp'].contains(extension)) {
      return 'image';
    } else if (['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'].contains(extension)) {
      return 'document';
    } else if (['mp3', 'wav', 'ogg', 'aac', 'flac'].contains(extension)) {
      return 'audio';
    } else if (['mp4', 'mpeg', 'webm', 'mov', 'avi'].contains(extension)) {
      return 'video';
    } else {
      return 'other';
    }
  }

  String _getDisplayName() {
    if (attachmentUrl == null) return '';
    
    try {
      final uri = Uri.parse(attachmentUrl!);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        return pathSegments.last;
      }
    } catch (e) {
      AppLogger.e('FileAttachmentWidget', 'Error parsing URL: $e');
    }
    
    // Fallback: just use the last part of the URL
    final parts = attachmentUrl!.split('/');
    return parts.isNotEmpty ? parts.last : 'File';
  }

  IconData _getIconForFileType(String fileType) {
    if (fileType.contains('image')) {
      return Icons.image;
    } else if (fileType.contains('pdf')) {
      return Icons.picture_as_pdf;
    } else if (fileType.contains('doc')) {
      return Icons.description;
    } else if (fileType.contains('sheet') || fileType.contains('xls')) {
      return Icons.table_chart;
    } else if (fileType.contains('presentation') || fileType.contains('ppt')) {
      return Icons.slideshow;
    } else if (fileType.contains('audio')) {
      return Icons.audiotrack;
    } else if (fileType.contains('video')) {
      return Icons.videocam;
    } else if (fileType.contains('zip') || fileType.contains('rar') || fileType.contains('tar')) {
      return Icons.archive;
    } else if (fileType.contains('text') || fileType.contains('txt')) {
      return Icons.text_snippet;
    } else {
      return Icons.insert_drive_file;
    }
  }

  Color _getColorForFileType(String fileType) {
    if (fileType.contains('image')) {
      return Colors.blue;
    } else if (fileType.contains('pdf')) {
      return Colors.red;
    } else if (fileType.contains('doc')) {
      return Colors.indigo;
    } else if (fileType.contains('sheet') || fileType.contains('xls')) {
      return Colors.green;
    } else if (fileType.contains('presentation') || fileType.contains('ppt')) {
      return Colors.orange;
    } else if (fileType.contains('audio')) {
      return Colors.purple;
    } else if (fileType.contains('video')) {
      return Colors.pink;
    } else if (fileType.contains('zip') || fileType.contains('rar') || fileType.contains('tar')) {
      return Colors.brown;
    } else if (fileType.contains('text') || fileType.contains('txt')) {
      return Colors.teal;
    } else {
      return Colors.grey;
    }
  }
}
