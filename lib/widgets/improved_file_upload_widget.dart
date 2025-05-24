import 'package:flutter/material.dart';
import '../services/improved_file_upload_service.dart';

class ImprovedFileUploadWidget extends StatefulWidget {
  final Function(String, String) onFileUploaded;
  final ImprovedFileUploadService webSocketService;
  final int roomId;

  const ImprovedFileUploadWidget({
    super.key,
    required this.onFileUploaded,
    required this.webSocketService,
    required this.roomId,
  });

  @override
  State<ImprovedFileUploadWidget> createState() =>
      _ImprovedFileUploadWidgetState();
}

class _ImprovedFileUploadWidgetState extends State<ImprovedFileUploadWidget> {
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _currentFileName = '';
  bool _showOptions = false;

  void _handleProgress(double progress) {
    if (mounted) {
      setState(() {
        _uploadProgress = progress;
      });
    }
  }

  void _handleUploadComplete(String url, String contentType) {
    if (mounted) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
        _showOptions = false;
      });
      widget.onFileUploaded(url, contentType);
    }
  }

  void _handleUploadError(String error) {
    if (mounted) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickAndUploadImage() async {
    setState(() {
      _isUploading = true;
      _currentFileName = 'image';
      _showOptions = false;
    });

    try {
      final result = await widget.webSocketService.pickAndUploadImage(
        roomId: widget.roomId,
        onProgress: _handleProgress,
      );

      _handleUploadComplete(result.url, result.contentType);
    } catch (e) {
      _handleUploadError(e.toString());
    }
  }

  Future<void> _pickAndUploadVideo() async {
    setState(() {
      _isUploading = true;
      _currentFileName = 'video';
      _showOptions = false;
    });

    try {
      final result = await widget.webSocketService.pickAndUploadVideo(
        roomId: widget.roomId,
        onProgress: _handleProgress,
      );

      _handleUploadComplete(result.url, result.contentType);
    } catch (e) {
      _handleUploadError(e.toString());
    }
  }

  Future<void> _pickAndUploadAudio() async {
    setState(() {
      _isUploading = true;
      _currentFileName = 'audio';
      _showOptions = false;
    });

    try {
      final result = await widget.webSocketService.pickAndUploadAudio(
        roomId: widget.roomId,
        onProgress: _handleProgress,
      );

      _handleUploadComplete(result.url, result.contentType);
    } catch (e) {
      _handleUploadError(e.toString());
    }
  }

  Future<void> _pickAndUploadDocument() async {
    setState(() {
      _isUploading = true;
      _currentFileName = 'document';
      _showOptions = false;
    });

    try {
      final result = await widget.webSocketService.pickAndUploadDocument(
        roomId: widget.roomId,
        onProgress: _handleProgress,
      );

      _handleUploadComplete(result.url, result.contentType);
    } catch (e) {
      _handleUploadError(e.toString());
    }
  }

  Future<void> _pickAndUploadAnyFile() async {
    setState(() {
      _isUploading = true;
      _currentFileName = 'file';
      _showOptions = false;
    });

    try {
      final result = await widget.webSocketService.pickAndUploadAnyFile(
        roomId: widget.roomId,
        onProgress: _handleProgress,
      );

      _handleUploadComplete(result.url, result.contentType);
    } catch (e) {
      _handleUploadError(e.toString());
    }
  }

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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Uploading $_currentFileName',
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
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                widget.webSocketService.cancelUpload();
                setState(() {
                  _isUploading = false;
                });
              },
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOptions() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          _buildOptionItem(
            icon: Icons.image,
            label: 'Image',
            onTap: _pickAndUploadImage,
          ),
          _buildOptionItem(
            icon: Icons.videocam,
            label: 'Video',
            onTap: _pickAndUploadVideo,
          ),
          _buildOptionItem(
            icon: Icons.audiotrack,
            label: 'Audio',
            onTap: _pickAndUploadAudio,
          ),
          _buildOptionItem(
            icon: Icons.insert_drive_file,
            label: 'Document',
            onTap: _pickAndUploadDocument,
          ),
          _buildOptionItem(
            icon: Icons.attach_file,
            label: 'Any File',
            onTap: _pickAndUploadAnyFile,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(width: 16.0),
            Text(label),
          ],
        ),
      ),
    );
  }
}
