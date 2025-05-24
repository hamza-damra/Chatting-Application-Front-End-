import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../utils/logger.dart';
import '../../core/services/token_service.dart';
import '../../widgets/shimmer_widgets.dart';

class TextFileViewerScreen extends StatefulWidget {
  final String fileUrl;
  final String? fileName;
  final String? contentType;

  const TextFileViewerScreen({
    super.key,
    required this.fileUrl,
    this.fileName,
    this.contentType,
  });

  @override
  State<TextFileViewerScreen> createState() => _TextFileViewerScreenState();
}

class _TextFileViewerScreenState extends State<TextFileViewerScreen> {
  String? _fileContent;
  bool _isLoading = true;
  String? _error;
  double _fontSize = 14.0;
  bool _wordWrap = true;

  @override
  void initState() {
    super.initState();
    _loadFileContent();
  }

  Future<void> _loadFileContent() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      AppLogger.i(
        'TextFileViewer',
        'Loading file content from: ${widget.fileUrl}',
      );

      // Get TokenService from Provider
      final tokenService = Provider.of<TokenService>(context, listen: false);

      // Prepare headers with authentication
      final headers = <String, String>{'User-Agent': 'Flutter App'};

      // Add Authorization header if token is available
      final token = tokenService.accessToken;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        AppLogger.d(
          'TextFileViewer',
          'Added Authorization header with Bearer token',
        );
      }

      final response = await http.get(
        Uri.parse(widget.fileUrl),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Try to decode as UTF-8 first
        String content;
        try {
          content = utf8.decode(response.bodyBytes);
        } catch (e) {
          // If UTF-8 fails, use latin1 as fallback
          content = latin1.decode(response.bodyBytes);
        }

        setState(() {
          _fileContent = content;
          _isLoading = false;
        });

        AppLogger.i('TextFileViewer', 'File content loaded successfully');
      } else if (response.statusCode == 401) {
        // Try to refresh token and retry
        AppLogger.w('TextFileViewer', 'Received 401, attempting token refresh');
        final refreshed = await tokenService.performTokenRefresh();
        if (refreshed) {
          // Retry with new token
          final newToken = tokenService.accessToken;
          if (newToken != null) {
            headers['Authorization'] = 'Bearer $newToken';
            final retryResponse = await http.get(
              Uri.parse(widget.fileUrl),
              headers: headers,
            );

            if (retryResponse.statusCode == 200) {
              // Try to decode as UTF-8 first
              String content;
              try {
                content = utf8.decode(retryResponse.bodyBytes);
              } catch (e) {
                // If UTF-8 fails, use latin1 as fallback
                content = latin1.decode(retryResponse.bodyBytes);
              }

              setState(() {
                _fileContent = content;
                _isLoading = false;
              });

              AppLogger.i(
                'TextFileViewer',
                'File content loaded successfully after token refresh',
              );
              return;
            }
          }
        }
        throw Exception('Failed to load file: ${response.statusCode}');
      } else {
        throw Exception('Failed to load file: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.e('TextFileViewer', 'Error loading file content: $e');
      setState(() {
        _error = 'Failed to load file: $e';
        _isLoading = false;
      });
    }
  }

  String _getDisplayFileName() {
    if (widget.fileName != null && widget.fileName!.isNotEmpty) {
      return widget.fileName!;
    }

    // Extract filename from URL
    final uri = Uri.parse(widget.fileUrl);
    final segments = uri.pathSegments;
    if (segments.isNotEmpty) {
      return segments.last;
    }

    return 'Text File';
  }

  String _getFileExtension() {
    final fileName = _getDisplayFileName();
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot != -1 && lastDot < fileName.length - 1) {
      return fileName.substring(lastDot + 1).toLowerCase();
    }
    return '';
  }

  TextStyle _getTextStyle() {
    final extension = _getFileExtension();

    // Use monospace font for code files
    if ([
      'json',
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
      'css',
      'html',
      'xml',
      'yaml',
      'yml',
    ].contains(extension)) {
      return TextStyle(
        fontFamily: 'monospace',
        fontSize: _fontSize,
        height: 1.4,
      );
    }

    // Use regular font for text files
    return TextStyle(fontSize: _fontSize, height: 1.5);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getDisplayFileName()),
        actions: [
          // Font size controls
          IconButton(
            icon: const Icon(Icons.text_decrease),
            onPressed:
                _fontSize > 10
                    ? () {
                      setState(() {
                        _fontSize = (_fontSize - 2).clamp(10.0, 24.0);
                      });
                    }
                    : null,
            tooltip: 'Decrease font size',
          ),
          IconButton(
            icon: const Icon(Icons.text_increase),
            onPressed:
                _fontSize < 24
                    ? () {
                      setState(() {
                        _fontSize = (_fontSize + 2).clamp(10.0, 24.0);
                      });
                    }
                    : null,
            tooltip: 'Increase font size',
          ),
          // Word wrap toggle
          IconButton(
            icon: Icon(_wordWrap ? Icons.wrap_text : Icons.notes),
            onPressed: () {
              setState(() {
                _wordWrap = !_wordWrap;
              });
            },
            tooltip: _wordWrap ? 'Disable word wrap' : 'Enable word wrap',
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFileContent,
            tooltip: 'Reload file',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: ShimmerWidgets.fileLoadingShimmer());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading file',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadFileContent,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_fileContent == null || _fileContent!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('File is empty'),
          ],
        ),
      );
    }

    return Column(
      children: [
        // File info bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getFileIcon(),
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_getDisplayFileName()} • ${_fileContent!.length} characters • ${_fileContent!.split('\n').length} lines',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                'Font: ${_fontSize.toInt()}px',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        // File content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              _fileContent!,
              style: _getTextStyle(),
              textAlign: TextAlign.left,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getFileIcon() {
    final extension = _getFileExtension();

    switch (extension) {
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
      default:
        return Icons.description;
    }
  }
}
