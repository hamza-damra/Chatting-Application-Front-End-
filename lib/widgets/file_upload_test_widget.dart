import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/api_file_service.dart';
import '../utils/logger.dart';

class FileUploadTestWidget extends StatefulWidget {
  const FileUploadTestWidget({super.key});

  @override
  State<FileUploadTestWidget> createState() => _FileUploadTestWidgetState();
}

class _FileUploadTestWidgetState extends State<FileUploadTestWidget> {
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadResult = '';
  FileUploadResponse? _lastUploadResponse;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.upload_file, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'File Upload Test',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isUploading) ...[
              LinearProgressIndicator(value: _uploadProgress),
              const SizedBox(height: 8),
              Text('Uploading... ${(_uploadProgress * 100).toInt()}%'),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _testImageUpload,
                    icon: const Icon(Icons.image),
                    label: const Text('Test Image Upload'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _testCameraUpload,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Test Camera'),
                  ),
                ),
              ],
            ),
            if (_uploadResult.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      _uploadResult.contains('SUCCESS')
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        _uploadResult.contains('SUCCESS')
                            ? Colors.green.withOpacity(0.3)
                            : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload Result:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            _uploadResult.contains('SUCCESS')
                                ? Colors.green[800]
                                : Colors.red[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_uploadResult, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
            if (_lastUploadResponse != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'File Details:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'ID',
                      _lastUploadResponse!.id?.toString() ?? 'N/A',
                    ),
                    _buildDetailRow('File Name', _lastUploadResponse!.fileName),
                    _buildDetailRow(
                      'Original Name',
                      _lastUploadResponse!.originalFileName ?? 'N/A',
                    ),
                    _buildDetailRow(
                      'Content Type',
                      _lastUploadResponse!.contentType,
                    ),
                    _buildDetailRow(
                      'File Size',
                      '${_lastUploadResponse!.fileSize} bytes',
                    ),
                    _buildDetailRow(
                      'Storage Location',
                      _lastUploadResponse!.storageLocation ?? 'N/A',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'File URL:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                        fontSize: 12,
                      ),
                    ),
                    SelectableText(
                      _lastUploadResponse!.fileUrl,
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Future<void> _testImageUpload() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image != null) {
        final file = File(image.path);
        final fileName = file.path.split('/').last;

        // Check if file type is supported
        if (!_isImageFile(fileName)) {
          _setUploadResult(
            'ERROR: Unsupported image type. Please select JPG, PNG, or GIF files.',
          );
          return;
        }

        await _uploadFile(file);
      }
    } catch (e) {
      _setUploadResult('ERROR: Failed to pick image - $e');
    }
  }

  Future<void> _testCameraUpload() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image != null) {
        await _uploadFile(File(image.path));
      }
    } catch (e) {
      _setUploadResult('ERROR: Failed to capture image - $e');
    }
  }

  Future<void> _uploadFile(File file) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadResult = '';
      _lastUploadResponse = null;
    });

    try {
      final apiFileService = Provider.of<ApiFileService>(
        context,
        listen: false,
      );

      AppLogger.i('FileUploadTestWidget', 'Starting test upload: ${file.path}');

      final response = await apiFileService.uploadFile(
        file: file,
        chatRoomId: 1, // Use a test chat room ID
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      setState(() {
        _lastUploadResponse = response;
      });

      _setUploadResult(
        'SUCCESS: File uploaded successfully!\n'
        'File URL: ${response.fileUrl}\n'
        'File Name: ${response.fileName}\n'
        'Content Type: ${response.contentType}\n'
        'File Size: ${response.fileSize} bytes',
      );

      AppLogger.i(
        'FileUploadTestWidget',
        'Upload successful: ${response.fileUrl}',
      );
    } catch (e) {
      _setUploadResult('ERROR: Upload failed - $e');
      AppLogger.e('FileUploadTestWidget', 'Upload failed: $e');
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  void _setUploadResult(String result) {
    setState(() {
      _uploadResult = result;
    });
  }

  bool _isImageFile(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif'].contains(extension);
  }
}
