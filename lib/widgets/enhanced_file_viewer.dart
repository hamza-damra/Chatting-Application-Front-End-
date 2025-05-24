import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/file_type_helper.dart';
import 'shimmer_widgets.dart';
import '../screens/file_viewers/text_file_viewer_screen.dart';
import 'video_player_widget.dart';

class EnhancedFileViewer extends StatefulWidget {
  final String fileUrl;
  final String? contentType;
  final String? fileName;

  const EnhancedFileViewer({
    super.key,
    required this.fileUrl,
    this.contentType,
    this.fileName,
  });

  @override
  State<EnhancedFileViewer> createState() => _EnhancedFileViewerState();
}

class _EnhancedFileViewerState extends State<EnhancedFileViewer> {
  @override
  Widget build(BuildContext context) {
    if (_isImageFile()) {
      return _buildImageViewer(context);
    } else if (_isVideoFile()) {
      return _buildVideoViewer(context);
    } else if (_isPdfFile()) {
      return _buildPdfViewer(context);
    } else if (_isTextFile()) {
      return _buildTextFileViewer(context);
    } else {
      return _buildGenericFileViewer(context);
    }
  }

  bool _isImageFile() {
    if (widget.contentType != null &&
        widget.contentType!.startsWith('image/')) {
      return true;
    }
    return FileTypeHelper.isImageFile(widget.fileUrl);
  }

  bool _isVideoFile() {
    if (widget.contentType != null &&
        widget.contentType!.startsWith('video/')) {
      return true;
    }
    return FileTypeHelper.isVideoFile(widget.fileUrl);
  }

  bool _isPdfFile() {
    if (widget.contentType != null && widget.contentType!.contains('pdf')) {
      return true;
    }
    return widget.fileUrl.toLowerCase().endsWith('.pdf');
  }

  bool _isTextFile() {
    // Check by content type first
    if (FileTypeHelper.isTextFileByContentType(widget.contentType)) {
      return true;
    }
    // Check by file extension
    final fileName =
        widget.fileName ?? FileTypeHelper.getFileNameFromUrl(widget.fileUrl);
    return FileTypeHelper.isTextFile(fileName);
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) return;

      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open file externally'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildImageViewer(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            widget.fileUrl,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return ShimmerWidgets.imageShimmer(
                width: 200,
                height: 200,
                borderRadius: BorderRadius.circular(8),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: Icon(Icons.broken_image, size: 40)),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: () async {
            if (mounted) {
              await _launchUrl(context, widget.fileUrl);
            }
          },
          icon: const Icon(Icons.open_in_new, size: 16),
          label: const Text('View Full Image'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _buildVideoViewer(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 200,
            height: 200,
            child: VideoPlayerWidget(
              videoUrl: widget.fileUrl,
              heroTag: 'enhanced-video-${widget.fileUrl.hashCode}',
            ),
          ),
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: () async {
            if (mounted) {
              await _launchUrl(context, widget.fileUrl);
            }
          },
          icon: const Icon(Icons.open_in_new, size: 16),
          label: const Text('Open in Video Player'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _buildPdfViewer(BuildContext context) {
    // In a real app, we would download the PDF and show it with PDFView
    // For this example, we'll just show a placeholder with an open button
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.picture_as_pdf, size: 40, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            widget.fileName ??
                FileTypeHelper.getFileNameFromUrl(widget.fileUrl),
            style: const TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () async {
              if (mounted) {
                await _launchUrl(context, widget.fileUrl);
              }
            },
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Open PDF'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFileViewer(BuildContext context) {
    final fileName =
        widget.fileName ?? FileTypeHelper.getFileNameFromUrl(widget.fileUrl);
    final extension = FileTypeHelper.getFileExtension(fileName);

    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getTextFileIcon(extension),
            size: 40,
            color: _getTextFileColor(extension),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              fileName,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => TextFileViewerScreen(
                        fileUrl: widget.fileUrl,
                        fileName: fileName,
                        contentType: widget.contentType,
                      ),
                ),
              );
            },
            icon: const Icon(Icons.visibility, size: 16),
            label: const Text('View Text'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericFileViewer(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getIconForFile(),
                size: 24,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.fileName ??
                      FileTypeHelper.getFileNameFromUrl(widget.fileUrl),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () async {
              if (mounted) {
                await _launchUrl(context, widget.fileUrl);
              }
            },
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Open File'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForFile() {
    if (widget.contentType != null) {
      if (widget.contentType!.startsWith('image/')) {
        return Icons.image;
      } else if (widget.contentType!.startsWith('video/')) {
        return Icons.videocam;
      } else if (widget.contentType!.startsWith('audio/')) {
        return Icons.audiotrack;
      } else if (widget.contentType!.contains('pdf')) {
        return Icons.picture_as_pdf;
      } else if (widget.contentType!.contains('word') ||
          widget.contentType!.contains('document')) {
        return Icons.description;
      } else if (widget.contentType!.contains('excel') ||
          widget.contentType!.contains('sheet')) {
        return Icons.table_chart;
      } else if (widget.contentType!.contains('presentation') ||
          widget.contentType!.contains('powerpoint')) {
        return Icons.slideshow;
      }
    }

    // Fallback to file extension
    final extension =
        FileTypeHelper.getFileExtension(widget.fileUrl).toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp3':
      case 'wav':
      case 'ogg':
        return Icons.audiotrack;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.videocam;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  IconData _getTextFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'json':
        return Icons.data_object;
      case 'md':
        return Icons.article;
      case 'txt':
        return Icons.description;
      case 'log':
        return Icons.list_alt;
      case 'xml':
      case 'html':
      case 'htm':
        return Icons.code;
      case 'css':
        return Icons.style;
      case 'js':
      case 'ts':
      case 'dart':
      case 'java':
      case 'cpp':
      case 'c':
      case 'h':
      case 'py':
      case 'rb':
      case 'go':
      case 'rs':
      case 'php':
        return Icons.code;
      case 'yaml':
      case 'yml':
        return Icons.settings;
      case 'csv':
        return Icons.table_chart;
      case 'sql':
        return Icons.storage;
      default:
        return Icons.text_snippet;
    }
  }

  Color _getTextFileColor(String extension) {
    switch (extension.toLowerCase()) {
      case 'json':
        return Colors.orange;
      case 'md':
        return Colors.blue;
      case 'txt':
        return Colors.grey[700]!;
      case 'log':
        return Colors.brown;
      case 'xml':
      case 'html':
      case 'htm':
        return Colors.red;
      case 'css':
        return Colors.blue;
      case 'js':
      case 'ts':
        return Colors.yellow[700]!;
      case 'dart':
        return Colors.blue[600]!;
      case 'java':
        return Colors.orange[700]!;
      case 'py':
        return Colors.green[600]!;
      case 'yaml':
      case 'yml':
        return Colors.purple;
      case 'csv':
        return Colors.green;
      case 'sql':
        return Colors.indigo;
      default:
        return Colors.grey[600]!;
    }
  }
}
