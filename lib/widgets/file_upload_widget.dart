import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../services/websocket_file_uploader.dart';
import '../services/websocket_service.dart';
import '../utils/logger.dart';

class FileUploadWidget extends StatefulWidget {
  final int chatRoomId;
  final WebSocketService webSocketService;
  final VoidCallback? onUploadStart;
  final VoidCallback? onUploadComplete;
  final Function(String)? onUploadError;

  const FileUploadWidget({
    super.key,
    required this.chatRoomId,
    required this.webSocketService,
    this.onUploadStart,
    this.onUploadComplete,
    this.onUploadError,
  });

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  late WebSocketFileUploader _fileUploader;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadingFileName;

  @override
  void initState() {
    super.initState();
    _fileUploader = WebSocketFileUploader(widget.webSocketService);
    _setupWebSocketSubscriptions();
  }

  void _setupWebSocketSubscriptions() {
    // Subscribe to file upload completion
    widget.webSocketService.subscribeToCustomTopic('/user/queue/files', (
      frame,
    ) {
      AppLogger.i('FileUploadWidget', 'File upload completed: ${frame.body}');
      _handleUploadComplete();
    });

    // Subscribe to upload progress
    widget.webSocketService.subscribeToCustomTopic(
      '/user/queue/files.progress',
      (frame) {
        if (frame.body != null) {
          try {
            final progress = Map<String, dynamic>.from(
              frame.body as Map? ?? {},
            );
            _handleUploadProgress(progress);
          } catch (e) {
            AppLogger.e('FileUploadWidget', 'Error parsing progress: $e');
          }
        }
      },
    );

    // Subscribe to upload errors
    widget.webSocketService.subscribeToCustomTopic('/user/queue/errors', (
      frame,
    ) {
      AppLogger.e('FileUploadWidget', 'Upload error: ${frame.body}');
      if (frame.body != null) {
        try {
          final error = Map<String, dynamic>.from(frame.body as Map? ?? {});
          _handleUploadError(error['message'] ?? 'Unknown error');
        } catch (e) {
          _handleUploadError('Upload failed');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isUploading) _buildProgressIndicator(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildUploadButton(
              icon: Icons.image,
              label: 'Image',
              onTap: () => _pickAndUploadImage(),
            ),
            _buildUploadButton(
              icon: Icons.videocam,
              label: 'Video',
              onTap: () => _pickAndUploadVideo(),
            ),
            _buildUploadButton(
              icon: Icons.insert_drive_file,
              label: 'Document',
              onTap: () => _pickAndUploadFile(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUploadButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isUploading ? null : onTap,
      child: Opacity(
        opacity: _isUploading ? 0.5 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _handleUploadProgress(Map<String, dynamic> progress) {
    if (mounted) {
      setState(() {
        int current = progress['chunkIndex'] ?? 0;
        int total = progress['totalChunks'] ?? 1;
        _uploadProgress = current / total;
      });
    }
  }

  void _handleUploadComplete() {
    if (mounted) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
        _uploadingFileName = null;
      });

      widget.onUploadComplete?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _handleUploadError(String error) {
    if (mounted) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
        _uploadingFileName = null;
      });

      widget.onUploadError?.call(error);

      // Create user-friendly error message
      String userFriendlyError = error;
      if (error.contains('not a participant') ||
          error.contains('ChatRoomAccessDeniedException') ||
          error.contains('You are not a participant')) {
        userFriendlyError =
            'You don\'t have permission to upload files to this chat room.';
      } else if (error.contains('Access denied') || error.contains('403')) {
        userFriendlyError =
            'Access denied. You may not have permission for this action.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $userFriendlyError'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Uploading ${_uploadingFileName ?? "file"}...',
                  style: const TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();

      // Show options for camera or gallery
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Select Image Source'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Camera'),
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Gallery'),
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                ],
              ),
            ),
      );

      if (source != null) {
        final XFile? image = await picker.pickImage(source: source);
        if (image != null) {
          File file = File(image.path);
          await _uploadFile(file);
        }
      }
    } catch (e) {
      AppLogger.e('FileUploadWidget', 'Error picking image: $e');
      _handleUploadError('Failed to pick image');
    }
  }

  Future<void> _pickAndUploadVideo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        await _uploadFile(file);
      }
    } catch (e) {
      AppLogger.e('FileUploadWidget', 'Error picking video: $e');
      _handleUploadError('Failed to pick video');
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        await _uploadFile(file);
      }
    } catch (e) {
      AppLogger.e('FileUploadWidget', 'Error picking file: $e');
      _handleUploadError('Failed to pick file');
    }
  }

  Future<void> _uploadFile(File file) async {
    try {
      // Validate file first
      bool isValid = await _fileUploader.validateFile(file);
      if (!isValid) {
        _handleUploadError('Invalid file or file too large');
        return;
      }

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
        _uploadingFileName = file.path.split('/').last;
      });

      widget.onUploadStart?.call();

      AppLogger.i('FileUploadWidget', 'Starting upload for: ${file.path}');

      await _fileUploader.uploadFile(
        file: file,
        chatRoomId: widget.chatRoomId,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _uploadProgress = progress;
            });
          }
        },
        onComplete: (uploadId) {
          AppLogger.i(
            'FileUploadWidget',
            'Upload completed with ID: $uploadId',
          );
          // The WebSocket subscription will handle the UI update
        },
        onError: (error) {
          AppLogger.e('FileUploadWidget', 'Upload error: $error');
          _handleUploadError(error);
        },
      );
    } catch (e) {
      AppLogger.e('FileUploadWidget', 'Upload error: $e');
      _handleUploadError(e.toString());
    }
  }
}
