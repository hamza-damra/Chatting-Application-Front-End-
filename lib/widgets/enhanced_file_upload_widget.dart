import 'package:flutter/material.dart';
import '../services/multi_type_file_upload_service.dart';
import '../services/websocket_service.dart';
import '../utils/logger.dart';

class EnhancedFileUploadWidget extends StatefulWidget {
  final int chatRoomId;
  final WebSocketService webSocketService;
  final Function(dynamic)? onUploadComplete;
  final bool showFileTypeOptions;

  const EnhancedFileUploadWidget({
    super.key,
    required this.chatRoomId,
    required this.webSocketService,
    this.onUploadComplete,
    this.showFileTypeOptions = true,
  });

  @override
  State<EnhancedFileUploadWidget> createState() => _EnhancedFileUploadWidgetState();
}

class _EnhancedFileUploadWidgetState extends State<EnhancedFileUploadWidget> {
  late final MultiTypeFileUploadService _uploadService;
  bool _isUploading = false;
  double _progress = 0.0;
  String _status = '';
  String? _currentUploadId;
  FileCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _uploadService = MultiTypeFileUploadService(
      webSocketService: widget.webSocketService,
    );
  }

  void _updateProgress(int current, int total) {
    setState(() {
      _progress = current / total;
      _status = 'Uploading: ${(_progress * 100).toStringAsFixed(1)}%';
    });
  }

  void _handleUploadComplete(dynamic result) {
    setState(() {
      _isUploading = false;
      _status = 'Upload complete!';
      _progress = 1.0;
      _currentUploadId = null;
    });
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('File uploaded successfully'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
    
    widget.onUploadComplete?.call(result);
    
    // Reset state after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _progress = 0.0;
          _status = '';
        });
      }
    });
  }

  void _handleError(String error) {
    setState(() {
      _isUploading = false;
      _status = 'Error: $error';
      _currentUploadId = null;
    });
    
    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
    
    // Log the error
    AppLogger.e('EnhancedFileUploadWidget', error);
  }

  Future<void> _pickAndUploadFile({FileCategory? category}) async {
    if (_isUploading) {
      // Already uploading, show warning
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload in progress. Please wait.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _status = 'Preparing upload...';
      _progress = 0.0;
    });

    try {
      await _uploadService.pickAndUploadFile(
        widget.chatRoomId,
        category: category,
        onProgress: _updateProgress,
        onComplete: _handleUploadComplete,
        onError: _handleError,
      );
      
      // Store the upload ID for potential cancellation
      _currentUploadId = _uploadService.currentUploadId;
    } catch (e) {
      _handleError(e.toString());
    }
  }

  Future<void> _captureAndUploadImage() async {
    if (_isUploading) {
      // Already uploading, show warning
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload in progress. Please wait.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _status = 'Preparing camera...';
      _progress = 0.0;
    });

    try {
      await _uploadService.uploadImageFromCamera(
        widget.chatRoomId,
        onProgress: _updateProgress,
        onComplete: _handleUploadComplete,
        onError: _handleError,
      );
      
      // Store the upload ID for potential cancellation
      _currentUploadId = _uploadService.currentUploadId;
    } catch (e) {
      _handleError(e.toString());
    }
  }

  void _cancelUpload() {
    if (_currentUploadId != null) {
      _uploadService.cancelUpload(_currentUploadId);
      setState(() {
        _isUploading = false;
        _status = 'Upload cancelled';
        _progress = 0.0;
        _currentUploadId = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload cancelled'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isUploading) ...[
          // Upload progress indicator
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Theme.of(context).primaryColor),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
                minHeight: 10,
              ),
            ),
          ),
          
          // Status text and cancel button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _status,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                onPressed: _cancelUpload,
                icon: const Icon(Icons.cancel, color: Colors.red),
                label: const Text('Cancel', style: TextStyle(color: Colors.red)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(80, 36),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ] else if (widget.showFileTypeOptions) ...[
          // File type selection buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFileTypeButton(
                  icon: Icons.image,
                  label: 'Image',
                  category: FileCategory.image,
                ),
                _buildFileTypeButton(
                  icon: Icons.insert_drive_file,
                  label: 'Document',
                  category: FileCategory.document,
                ),
                _buildFileTypeButton(
                  icon: Icons.audiotrack,
                  label: 'Audio',
                  category: FileCategory.audio,
                ),
                _buildFileTypeButton(
                  icon: Icons.video_library,
                  label: 'Video',
                  category: FileCategory.video,
                ),
                _buildFileTypeButton(
                  icon: Icons.attach_file,
                  label: 'Any File',
                  category: null,
                ),
                _buildCameraButton(),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFileTypeButton({
    required IconData icon,
    required String label,
    required FileCategory? category,
  }) {
    final isSelected = _selectedCategory == category;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _selectedCategory = category;
          });
          _pickAndUploadFile(category: category);
        },
        icon: Icon(
          icon,
          color: isSelected ? Colors.white : Theme.of(context).primaryColor,
          size: 20,
        ),
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).primaryColor,
            fontSize: 12,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? Theme.of(context).primaryColor
              : Colors.white,
          foregroundColor: isSelected
              ? Colors.white
              : Theme.of(context).primaryColor,
          elevation: isSelected ? 4 : 1,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Theme.of(context).primaryColor),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton.icon(
        onPressed: _captureAndUploadImage,
        icon: const Icon(
          Icons.camera_alt,
          color: Colors.white,
          size: 20,
        ),
        label: const Text(
          'Camera',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
