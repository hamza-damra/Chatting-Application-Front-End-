import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/improved_chat_service.dart';
import '../utils/logger.dart';

class RestApiFileUploadWidget extends StatefulWidget {
  final int chatRoomId;
  final ImprovedChatService chatService;
  final VoidCallback? onUploadStart;
  final VoidCallback? onUploadComplete;
  final Function(String)? onUploadError;

  const RestApiFileUploadWidget({
    super.key,
    required this.chatRoomId,
    required this.chatService,
    this.onUploadStart,
    this.onUploadComplete,
    this.onUploadError,
  });

  @override
  State<RestApiFileUploadWidget> createState() =>
      _RestApiFileUploadWidgetState();
}

class _RestApiFileUploadWidgetState extends State<RestApiFileUploadWidget> {
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _currentFileName = '';
  bool _showOptions = false;

  @override
  Widget build(BuildContext context) {
    if (_isUploading) {
      return _buildProgressIndicator();
    }

    return Column(
      children: [
        IconButton(
          icon: const Icon(Icons.attach_file),
          onPressed: () {
            setState(() {
              _showOptions = !_showOptions;
            });
          },
        ),
        if (_showOptions) _buildAttachmentOptions(),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(value: _uploadProgress),
          const SizedBox(height: 8),
          Text(
            'Uploading $_currentFileName...',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            '${(_uploadProgress * 100).toInt()}%',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOptions() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOptionButton(
            icon: Icons.photo,
            label: 'Photo',
            onTap: _pickAndUploadImage,
          ),
          _buildOptionButton(
            icon: Icons.camera_alt,
            label: 'Camera',
            onTap: _captureAndUploadImage,
          ),
          _buildOptionButton(
            icon: Icons.videocam,
            label: 'Video',
            onTap: _pickAndUploadVideo,
          ),
          _buildOptionButton(
            icon: Icons.insert_drive_file,
            label: 'File',
            onTap: _pickAndUploadDocument,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: Icon(icon), onPressed: onTap),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image != null) {
        await _uploadFile(File(image.path), 'image');
      }
    } catch (e) {
      _handleUploadError('Failed to pick image: $e');
    }
  }

  Future<void> _captureAndUploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image != null) {
        await _uploadFile(File(image.path), 'image');
      }
    } catch (e) {
      _handleUploadError('Failed to capture image: $e');
    }
  }

  Future<void> _pickAndUploadVideo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );

      if (video != null) {
        await _uploadFile(File(video.path), 'video');
      }
    } catch (e) {
      _handleUploadError('Failed to pick video: $e');
    }
  }

  Future<void> _pickAndUploadDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        await _uploadFile(File(result.files.single.path!), 'document');
      }
    } catch (e) {
      _handleUploadError('Failed to pick document: $e');
    }
  }

  Future<void> _uploadFile(File file, String fileType) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _currentFileName = file.path.split('/').last;
      _showOptions = false;
    });

    widget.onUploadStart?.call();

    try {
      AppLogger.i(
        'RestApiFileUploadWidget',
        'Starting $fileType upload: ${file.path}',
      );

      bool success = false;

      switch (fileType) {
        case 'image':
          success = await widget.chatService.sendImageMessage(
            chatRoomId: widget.chatRoomId,
            imageFile: file,
            onUploadProgress: _updateProgress,
          );
          break;
        case 'video':
          success = await widget.chatService.sendVideoMessage(
            chatRoomId: widget.chatRoomId,
            videoFile: file,
            onUploadProgress: _updateProgress,
          );
          break;
        case 'document':
          success = await widget.chatService.sendDocumentMessage(
            chatRoomId: widget.chatRoomId,
            documentFile: file,
            onUploadProgress: _updateProgress,
          );
          break;
        default:
          success = await widget.chatService.sendFileMessage(
            chatRoomId: widget.chatRoomId,
            file: file,
            onUploadProgress: _updateProgress,
          );
      }

      if (success) {
        AppLogger.i(
          'RestApiFileUploadWidget',
          'File uploaded and message sent successfully',
        );
        widget.onUploadComplete?.call();
      } else {
        throw Exception('Failed to send message after upload');
      }
    } catch (e) {
      AppLogger.e('RestApiFileUploadWidget', 'Upload error: $e');
      _handleUploadError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
          _currentFileName = '';
        });
      }
    }
  }

  void _updateProgress(double progress) {
    if (mounted) {
      setState(() {
        _uploadProgress = progress;
      });
    }
  }

  void _handleUploadError(String error) {
    AppLogger.e('RestApiFileUploadWidget', 'Upload error: $error');
    widget.onUploadError?.call(error);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
