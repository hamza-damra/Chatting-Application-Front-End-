import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/api_config.dart';
import '../services/file_access_service.dart';
import '../core/services/token_service.dart';
import '../utils/logger.dart';

class MediaGalleryScreen extends StatefulWidget {
  const MediaGalleryScreen({super.key});

  @override
  State<MediaGalleryScreen> createState() => _MediaGalleryScreenState();
}

class _MediaGalleryScreenState extends State<MediaGalleryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late FileAccessService _fileAccessService;

  List<String> _images = [];
  List<String> _documents = [];
  List<String> _audio = [];
  List<String> _video = [];
  bool _isLoading = true;
  String? _error;
  FileStorageStats? _stats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Initialize file access service
    final tokenService = Provider.of<TokenService>(context, listen: false);
    _fileAccessService = FileAccessService(tokenService: tokenService);

    // Load files
    _loadFiles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load storage stats
      _stats = await _fileAccessService.getFileStorageStats();

      // Load files by category
      final imagesTask = _fileAccessService.getFilesByCategory(
        FileCategory.image,
      );
      final documentsTask = _fileAccessService.getFilesByCategory(
        FileCategory.document,
      );
      final audioTask = _fileAccessService.getFilesByCategory(
        FileCategory.audio,
      );
      final videoTask = _fileAccessService.getFilesByCategory(
        FileCategory.video,
      );

      final results = await Future.wait([
        imagesTask,
        documentsTask,
        audioTask,
        videoTask,
      ]);

      setState(() {
        _images = results[0];
        _documents = results[1];
        _audio = results[2];
        _video = results[3];
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.e('MediaGalleryScreen', 'Error loading files: $e');
      setState(() {
        _error = 'Failed to load media files: $e';
        _isLoading = false;
      });
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Widget _buildStorageStats() {
    if (_stats == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Storage Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Total Files: ${_stats!.totalFiles}'),
            Text('Total Size: ${_formatFileSize(_stats!.totalSize)}'),
            const Divider(),
            const Text('Files by Category:'),
            ..._stats!.fileCountByCategory.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Text(
                  '${entry.key}: ${entry.value} files (${_formatFileSize(_stats!.fileSizeByCategory[entry.key] ?? 0)})',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    if (_images.isEmpty) {
      return const Center(child: Text('No images found'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _images.length,
      itemBuilder: (context, index) {
        final filename = _images[index];
        final imageUrl =
            '${ApiConfig.baseUrl}${ApiConfig.filesEndpoint}/category/image/$filename';

        return GestureDetector(
          onTap: () {
            // Show full-screen image
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (context) => Scaffold(
                      appBar: AppBar(title: Text(filename)),
                      body: Center(
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.contain,
                          placeholder:
                              (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                          errorWidget:
                              (context, url, error) =>
                                  const Center(child: Icon(Icons.error)),
                        ),
                      ),
                    ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder:
                  (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
              errorWidget:
                  (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFileList(List<String> files, IconData icon) {
    if (files.isEmpty) {
      return const Center(child: Text('No files found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final filename = files[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(icon, size: 36),
            title: Text(filename),
            subtitle: Text('Tap to view'),
            onTap: () {
              // Handle file opening based on type
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Opening $filename')));
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Gallery'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.image), text: 'Images'),
            Tab(icon: Icon(Icons.description), text: 'Documents'),
            Tab(icon: Icon(Icons.audio_file), text: 'Audio'),
            Tab(icon: Icon(Icons.video_file), text: 'Video'),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : Column(
                children: [
                  _buildStorageStats(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildImageGrid(),
                        _buildFileList(_documents, Icons.description),
                        _buildFileList(_audio, Icons.audio_file),
                        _buildFileList(_video, Icons.video_file),
                      ],
                    ),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadFiles,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
