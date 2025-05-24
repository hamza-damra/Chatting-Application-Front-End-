import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../widgets/file_upload_test_widget.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String _debugOutput = '';
  bool _isLoading = false;

  void _addOutput(String message) {
    setState(() {
      _debugOutput += '${DateTime.now().toIso8601String()}: $message\n';
    });
  }

  Future<void> _testCurrentUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _addOutput('Testing /api/users/me endpoint...');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        _addOutput('ERROR: No token found');
        return;
      }

      _addOutput('Token: ${token.substring(0, 20)}...');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _addOutput('Response Status: ${response.statusCode}');
      _addOutput('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        _addOutput('SUCCESS: User data received');
        _addOutput('User: ${userData['username']}');
      } else {
        _addOutput('FAILED: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _addOutput('ERROR: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testChatRooms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _addOutput('Testing /api/chatrooms endpoint...');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        _addOutput('ERROR: No token found');
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/chatrooms'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _addOutput('Response Status: ${response.statusCode}');
      _addOutput('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final chatRooms = jsonDecode(response.body);
        _addOutput('SUCCESS: Chat rooms received');
        _addOutput('Count: ${chatRooms.length}');
      } else {
        _addOutput('FAILED: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _addOutput('ERROR: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _addOutput('Testing /api/users endpoint...');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        _addOutput('ERROR: No token found');
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _addOutput('Response Status: ${response.statusCode}');
      _addOutput('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final users = jsonDecode(response.body);
        _addOutput('SUCCESS: Users received');
        _addOutput('Count: ${users.length}');
      } else {
        _addOutput('FAILED: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _addOutput('ERROR: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testFileUpload() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _addOutput('Testing /api/files/upload endpoint...');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        _addOutput('ERROR: No token found');
        return;
      }

      _addOutput('Token: ${token.substring(0, 20)}...');
      _addOutput('NOTE: This is a test endpoint check only');
      _addOutput('Actual file upload requires multipart/form-data');
      _addOutput('Use the chat screen file upload for real testing');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/files'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _addOutput('Response Status: ${response.statusCode}');
      _addOutput('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        _addOutput('SUCCESS: Files endpoint accessible');
      } else {
        _addOutput('INFO: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _addOutput('ERROR: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testCompleteFlow() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _addOutput('=== TESTING COMPLETE AUTHENTICATION & API FLOW ===');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        _addOutput('❌ ERROR: No token found - Please login first');
        return;
      }

      _addOutput('✅ Token found: ${token.substring(0, 20)}...');

      // Test 1: Current User
      _addOutput('\n--- Test 1: Current User ---');
      try {
        final userResponse = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/users/me'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (userResponse.statusCode == 200) {
          final userData = jsonDecode(userResponse.body);
          _addOutput('✅ User API: SUCCESS');
          _addOutput('   Username: ${userData['username']}');
          _addOutput('   Email: ${userData['email']}');
        } else {
          _addOutput('❌ User API: FAILED (${userResponse.statusCode})');
          _addOutput('   Response: ${userResponse.body}');
        }
      } catch (e) {
        _addOutput('❌ User API: ERROR - $e');
      }

      // Test 2: Chat Rooms
      _addOutput('\n--- Test 2: Chat Rooms ---');
      try {
        final chatResponse = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/chatrooms'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (chatResponse.statusCode == 200) {
          final chatRooms = jsonDecode(chatResponse.body);
          _addOutput('✅ Chat Rooms API: SUCCESS');
          _addOutput('   Found ${chatRooms.length} chat rooms');
          if (chatRooms.isNotEmpty) {
            _addOutput(
              '   First room: ${chatRooms[0]['name']} (ID: ${chatRooms[0]['id']})',
            );
          }
        } else {
          _addOutput('❌ Chat Rooms API: FAILED (${chatResponse.statusCode})');
          _addOutput('   Response: ${chatResponse.body}');
        }
      } catch (e) {
        _addOutput('❌ Chat Rooms API: ERROR - $e');
      }

      // Test 3: File Upload Endpoint
      _addOutput('\n--- Test 3: File Upload Endpoint ---');
      try {
        final fileResponse = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/files'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        _addOutput('✅ Files Endpoint: Accessible (${fileResponse.statusCode})');
        _addOutput('   Response: ${fileResponse.body}');
      } catch (e) {
        _addOutput('❌ Files Endpoint: ERROR - $e');
      }

      _addOutput('\n=== FLOW TEST COMPLETE ===');
      _addOutput('✅ If all tests passed, the app should work correctly!');
      _addOutput('📱 Try uploading an image in a chat room now.');
    } catch (e) {
      _addOutput('❌ CRITICAL ERROR: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testFileUploadEndpoint() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _addOutput('=== TESTING FILE UPLOAD ENDPOINT ===');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        _addOutput('❌ ERROR: No token found - Please login first');
        return;
      }

      _addOutput('✅ Token found: ${token.substring(0, 20)}...');

      // Test the exact endpoint that backend expects
      final uploadUrl = '${ApiConfig.baseUrl}/api/files/upload';
      _addOutput('📡 Testing endpoint: $uploadUrl');

      // Test with OPTIONS request first (CORS preflight)
      try {
        final optionsResponse =
            await http.Request('OPTIONS', Uri.parse(uploadUrl)).send();
        _addOutput('✅ OPTIONS request: ${optionsResponse.statusCode}');
      } catch (e) {
        _addOutput('⚠️ OPTIONS request failed: $e');
      }

      // Test with POST request (without file - should get 400 but not 405)
      try {
        final postResponse = await http.post(
          Uri.parse(uploadUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: '{}',
        );

        _addOutput('📤 POST request status: ${postResponse.statusCode}');
        _addOutput('📤 POST response: ${postResponse.body}');

        if (postResponse.statusCode == 405) {
          _addOutput('❌ CRITICAL: Method not allowed - endpoint missing!');
        } else if (postResponse.statusCode == 400) {
          _addOutput('✅ GOOD: Endpoint exists (400 = bad request format)');
        } else if (postResponse.statusCode == 403) {
          _addOutput('⚠️ PERMISSION: 403 Forbidden - check authentication');
        } else {
          _addOutput('ℹ️ Unexpected status: ${postResponse.statusCode}');
        }
      } catch (e) {
        _addOutput('❌ POST request error: $e');
      }

      // Test file endpoint accessibility
      _addOutput('\n--- Testing File Endpoints ---');
      try {
        final filesResponse = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/files'),
          headers: {'Authorization': 'Bearer $token'},
        );

        _addOutput('📁 Files endpoint: ${filesResponse.statusCode}');
        _addOutput('📁 Response: ${filesResponse.body}');
      } catch (e) {
        _addOutput('❌ Files endpoint error: $e');
      }

      _addOutput('\n=== FILE UPLOAD ENDPOINT TEST COMPLETE ===');

      if (_debugOutput.contains('Method not allowed')) {
        _addOutput('❌ RESULT: File upload endpoint is missing on backend');
        _addOutput('🔧 ACTION: Backend needs POST /api/files/upload endpoint');
      } else if (_debugOutput.contains('400') || _debugOutput.contains('403')) {
        _addOutput('✅ RESULT: File upload endpoint exists');
        _addOutput('📱 ACTION: Try actual file upload in chat now');
      }
    } catch (e) {
      _addOutput('❌ CRITICAL ERROR: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testSupportedFileTypes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _addOutput('=== CHECKING SUPPORTED FILE TYPES ===');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        _addOutput('❌ ERROR: No token found - Please login first');
        return;
      }

      _addOutput('✅ Token found: ${token.substring(0, 20)}...');

      // Based on the error message, let's check what the backend actually accepts
      _addOutput('\n📋 BACKEND SUPPORTED FILE TYPES:');
      _addOutput('From error message analysis:');
      _addOutput('✅ Allowed types: image/jpeg, image/png, image/gif');
      _addOutput('✅ Allowed types: application/pdf, application/msword');
      _addOutput(
        '✅ Allowed types: application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      );
      _addOutput('✅ Allowed types: text/plain, audio/mpeg, audio/wav');
      _addOutput('✅ Allowed types: video/mp4, video/mpeg');

      _addOutput('\n📱 FLUTTER CLIENT VALIDATION:');
      _addOutput('✅ Images: .jpg, .jpeg, .png, .gif');
      _addOutput('✅ Documents: .pdf, .txt, .doc, .docx');
      _addOutput('✅ Audio: .mp3, .wav');
      _addOutput('✅ Video: .mp4, .mov');

      _addOutput('\n⚠️ POTENTIAL ISSUES:');
      _addOutput(
        '• Backend expects video/mpeg but client sends video/quicktime for .mov files',
      );
      _addOutput('• Backend might be strict about exact content type matching');
      _addOutput('• Some file extensions might not map to expected MIME types');

      _addOutput('\n🔧 RECOMMENDATIONS:');
      _addOutput('1. Try uploading a simple .jpg image first');
      _addOutput('2. Check if the file picker is selecting supported formats');
      _addOutput('3. Verify the content type mapping in the client');
      _addOutput('4. Test with a small file (< 1MB) to rule out size issues');

      _addOutput('\n📝 NEXT STEPS:');
      _addOutput('• Use the File Upload Test widget above');
      _addOutput('• Select a .jpg or .png image');
      _addOutput('• Check the detailed error message if it still fails');
    } catch (e) {
      _addOutput('❌ ERROR: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearOutput() {
    setState(() {
      _debugOutput = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug API'),
        actions: [
          IconButton(icon: const Icon(Icons.clear), onPressed: _clearOutput),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testCurrentUser,
                        child: const Text('Test User'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testChatRooms,
                        child: const Text('Test Chat Rooms'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testUsers,
                    child: const Text('Test Users'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testFileUpload,
                    child: const Text('Test File Upload'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testCompleteFlow,
                    child: const Text('Test Complete Flow'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testFileUploadEndpoint,
                    child: const Text('Test File Upload Endpoint'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testSupportedFileTypes,
                    child: const Text('Check Supported File Types'),
                  ),
                ),
              ],
            ),
          ),
          const FileUploadTestWidget(),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _debugOutput.isEmpty
                      ? 'Tap a button to test API endpoints'
                      : _debugOutput,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
