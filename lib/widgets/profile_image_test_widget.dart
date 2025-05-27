import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/api_auth_provider.dart';
import '../utils/logger.dart';
import '../core/services/token_service.dart';
import 'package:http/http.dart' as http;

/// A test widget for debugging profile image upload issues
class ProfileImageTestWidget extends StatefulWidget {
  const ProfileImageTestWidget({super.key});

  @override
  State<ProfileImageTestWidget> createState() => _ProfileImageTestWidgetState();
}

class _ProfileImageTestWidgetState extends State<ProfileImageTestWidget> {
  File? _selectedImage;
  String _testResults = '';
  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _testResults = 'Image selected: ${image.path}';
        });
      }
    } catch (e) {
      setState(() {
        _testResults = 'Error picking image: $e';
      });
    }
  }

  Future<void> _testDirectUpload() async {
    if (_selectedImage == null) {
      setState(() {
        _testResults = 'Please select an image first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _testResults = 'Testing direct upload...';
    });

    try {
      final tokenService = Provider.of<TokenService>(context, listen: false);

      // Test 1: Basic file validation
      AppLogger.i('TEST', '=== DIRECT UPLOAD TEST ===');
      AppLogger.i('TEST', 'File path: ${_selectedImage!.path}');
      AppLogger.i('TEST', 'File exists: ${await _selectedImage!.exists()}');
      AppLogger.i('TEST', 'File size: ${await _selectedImage!.length()} bytes');

      // Test 2: Token validation
      AppLogger.i('TEST', 'Token available: ${tokenService.hasToken}');
      AppLogger.i('TEST', 'Token expired: ${tokenService.isTokenExpired}');

      if (!tokenService.hasToken) {
        setState(() {
          _testResults = 'ERROR: No authentication token available';
          _isLoading = false;
        });
        return;
      }

      // Test 3: Direct HTTP request (mimicking Postman)
      final url = 'http://abusaker.zapto.org:8080/api/users/me/profile-image';
      final request = http.MultipartRequest('POST', Uri.parse(url));

      // Add headers exactly like Postman
      request.headers.addAll({
        'Authorization': 'Bearer ${tokenService.accessToken}',
        'Accept': 'application/json',
      });

      // Add file exactly like Postman
      request.files.add(
        await http.MultipartFile.fromPath('file', _selectedImage!.path),
      );

      AppLogger.i('TEST', 'Sending direct request...');
      AppLogger.i('TEST', 'URL: $url');
      AppLogger.i('TEST', 'Headers: ${request.headers}');

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      AppLogger.i('TEST', 'Response status: ${response.statusCode}');
      AppLogger.i('TEST', 'Response headers: ${response.headers}');
      AppLogger.i('TEST', 'Response body: $responseBody');

      setState(() {
        _testResults = '''
DIRECT UPLOAD TEST RESULTS:
Status: ${response.statusCode}
Success: ${response.statusCode == 200}

Response Body:
$responseBody

Check console logs for detailed request/response info.
        ''';
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.e('TEST', 'Direct upload error: $e');
      setState(() {
        _testResults = 'Direct upload error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testViaProvider() async {
    if (_selectedImage == null) {
      setState(() {
        _testResults = 'Please select an image first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _testResults = 'Testing via ApiAuthProvider...';
    });

    try {
      final authProvider = Provider.of<ApiAuthProvider>(context, listen: false);

      AppLogger.i('TEST', '=== PROVIDER UPLOAD TEST ===');

      final success = await authProvider.setProfileImage(
        imageFile: _selectedImage!,
      );

      setState(() {
        _testResults = '''
PROVIDER UPLOAD TEST RESULTS:
Success: $success
Error: ${authProvider.error ?? 'None'}

Check console logs for detailed request/response info.
        ''';
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.e('TEST', 'Provider upload error: $e');
      setState(() {
        _testResults = 'Provider upload error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testBackendDebug() async {
    if (_selectedImage == null) {
      setState(() {
        _testResults = 'Please select an image first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _testResults = 'Testing backend debug endpoints...';
    });

    try {
      final tokenService = Provider.of<TokenService>(context, listen: false);

      AppLogger.i('TEST', '=== BACKEND DEBUG TEST ===');

      // Test 1: File system test
      final fileSystemUrl =
          'http://abusaker.zapto.org:8080/api/debug/file-system';
      final fileSystemResponse = await http.get(
        Uri.parse(fileSystemUrl),
        headers: {
          'Authorization': 'Bearer ${tokenService.accessToken}',
          'Accept': 'application/json',
        },
      );

      AppLogger.i('TEST', 'File system test: ${fileSystemResponse.statusCode}');
      AppLogger.i('TEST', 'File system response: ${fileSystemResponse.body}');

      // Test 2: Auth test
      final authUrl = 'http://abusaker.zapto.org:8080/api/debug/auth-test';
      final authResponse = await http.get(
        Uri.parse(authUrl),
        headers: {
          'Authorization': 'Bearer ${tokenService.accessToken}',
          'Accept': 'application/json',
        },
      );

      AppLogger.i('TEST', 'Auth test: ${authResponse.statusCode}');
      AppLogger.i('TEST', 'Auth response: ${authResponse.body}');

      // Test 3: Debug profile image upload
      final debugUrl =
          'http://abusaker.zapto.org:8080/api/debug/profile-image-debug';
      final request = http.MultipartRequest('POST', Uri.parse(debugUrl));

      request.headers.addAll({
        'Authorization': 'Bearer ${tokenService.accessToken}',
        'Accept': 'application/json',
      });

      request.files.add(
        await http.MultipartFile.fromPath('file', _selectedImage!.path),
      );

      final debugResponse = await request.send();
      final debugResponseBody = await debugResponse.stream.bytesToString();

      AppLogger.i('TEST', 'Debug upload test: ${debugResponse.statusCode}');
      AppLogger.i('TEST', 'Debug upload response: $debugResponseBody');

      setState(() {
        _testResults = '''
BACKEND DEBUG TEST RESULTS:

File System Test: ${fileSystemResponse.statusCode}
${fileSystemResponse.body}

Auth Test: ${authResponse.statusCode}
${authResponse.body}

Debug Upload Test: ${debugResponse.statusCode}
$debugResponseBody

Check console logs for detailed info.
        ''';
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.e('TEST', 'Backend debug error: $e');
      setState(() {
        _testResults = 'Backend debug error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile Image Upload Test',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Image preview
            if (_selectedImage != null)
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                ),
              ),

            const SizedBox(height: 16),

            // Buttons
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _pickImage,
                  child: const Text('Pick Image'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testDirectUpload,
                  child: const Text('Test Direct Upload'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testViaProvider,
                  child: const Text('Test Via Provider'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testBackendDebug,
                  child: const Text('Test Backend Debug'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Results
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_testResults.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _testResults,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
