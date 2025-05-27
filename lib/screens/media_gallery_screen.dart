import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../config/api_config.dart';
import '../services/file_access_service.dart';
import '../core/services/token_service.dart';
import '../utils/logger.dart';
import '../widgets/shimmer_widgets.dart';
import '../widgets/image_viewer.dart';

class MediaGalleryScreen extends StatefulWidget {
  const MediaGalleryScreen({super.key});

  @override
  State<MediaGalleryScreen> createState() => _MediaGalleryScreenState();
}

class _MediaGalleryScreenState extends State<MediaGalleryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late FileAccessService _fileAccessService;

  List<String> _images = [];
  List<String> _documents = [];
  List<String> _audio = [];
  List<String> _video = [];
  bool _isLoading = true;
  String? _error;
  FileStorageStats? _stats;

  // Selection mode for multi-select
  bool _isSelectionMode = false;
  final Set<String> _selectedFiles = {};

  // Search functionality
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Initialize file access service
    final tokenService = Provider.of<TokenService>(context, listen: false);
    _fileAccessService = FileAccessService(tokenService: tokenService);

    // Load files
    _loadFiles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _searchController.dispose();
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

      // Start fade animation
      _fadeController.forward();
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

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDark
                  ? [
                    theme.colorScheme.surface,
                    theme.colorScheme.surface.withAlpha(230),
                  ]
                  : [Colors.white, theme.colorScheme.primary.withAlpha(13)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withAlpha(26),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.storage_rounded,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Storage Overview',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your media collection',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildStatRow(
              icon: Icons.folder_rounded,
              label: 'Total Files',
              value: '${_stats!.totalFiles}',
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              icon: Icons.data_usage_rounded,
              label: 'Total Size',
              value: _formatFileSize(_stats!.totalSize),
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            Text(
              'Files by Category',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ..._stats!.fileCountByCategory.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildCategoryRow(
                  category: entry.key,
                  count: entry.value,
                  size: _stats!.fileSizeByCategory[entry.key] ?? 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryRow({
    required String category,
    required int count,
    required int size,
  }) {
    final theme = Theme.of(context);
    final IconData icon;
    final Color color;

    switch (category.toLowerCase()) {
      case 'image':
        icon = Icons.image_rounded;
        color = Colors.purple;
        break;
      case 'video':
        icon = Icons.video_library_rounded;
        color = Colors.red;
        break;
      case 'audio':
        icon = Icons.audio_file_rounded;
        color = Colors.orange;
        break;
      case 'document':
        icon = Icons.description_rounded;
        color = Colors.blue;
        break;
      default:
        icon = Icons.folder_rounded;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(51)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '$count files',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatFileSize(size),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    if (_images.isEmpty) {
      return _buildEmptyState(
        icon: Icons.image_rounded,
        title: 'No Images Found',
        subtitle: 'Your image gallery is empty',
      );
    }

    final filteredImages =
        _searchQuery.isEmpty
            ? _images
            : _images
                .where(
                  (image) =>
                      image.toLowerCase().contains(_searchQuery.toLowerCase()),
                )
                .toList();

    if (filteredImages.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off_rounded,
        title: 'No Results',
        subtitle: 'No images match your search',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFiles,
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        padding: const EdgeInsets.all(16),
        itemCount: filteredImages.length,
        itemBuilder: (context, index) {
          final filename = filteredImages[index];
          final imageUrl =
              '${ApiConfig.baseUrl}${ApiConfig.filesEndpoint}/category/image/$filename';
          final heroTag = 'gallery_image_$filename';

          return _buildImageCard(
            filename: filename,
            imageUrl: imageUrl,
            heroTag: heroTag,
            index: index,
          );
        },
      ),
    );
  }

  Widget _buildImageCard({
    required String filename,
    required String imageUrl,
    required String heroTag,
    required int index,
  }) {
    final theme = Theme.of(context);
    final isSelected = _selectedFiles.contains(filename);

    return GestureDetector(
      onTap: () => _onImageTap(filename, imageUrl, heroTag),
      onLongPress: () => _toggleSelection(filename),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withAlpha(26),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Hero(
              tag: heroTag,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        height: 150 + (index % 3) * 50, // Varied heights
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ShimmerWidgets.imageShimmer(
                          width: double.infinity,
                          height: double.infinity,
                          context: context,
                        ),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image_rounded,
                              color: theme.colorScheme.onErrorContainer,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Failed to load',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                ),
              ),
            ),

            // Selection overlay
            if (_isSelectionMode)
              Positioned(
                top: 8,
                right: 8,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surface.withAlpha(179),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.outline.withAlpha(77),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isSelected ? Icons.check_rounded : Icons.circle_outlined,
                    color:
                        isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                    size: 16,
                  ),
                ),
              ),

            // Filename overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withAlpha(179)],
                  ),
                ),
                child: Text(
                  filename,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for image interactions
  void _onImageTap(String filename, String imageUrl, String heroTag) {
    if (_isSelectionMode) {
      _toggleSelection(filename);
    } else {
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (context, animation, secondaryAnimation) {
            return FadeTransition(
              opacity: animation,
              child: ImageViewer(imageUrl: imageUrl, heroTag: heroTag),
            );
          },
        ),
      );
    }
  }

  void _toggleSelection(String filename) {
    setState(() {
      if (_selectedFiles.contains(filename)) {
        _selectedFiles.remove(filename);
        if (_selectedFiles.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedFiles.add(filename);
        _isSelectionMode = true;
      }
    });
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileList(List<String> files, IconData icon) {
    if (files.isEmpty) {
      return _buildEmptyState(
        icon: icon,
        title: 'No Files Found',
        subtitle: 'This category is empty',
      );
    }

    final filteredFiles =
        _searchQuery.isEmpty
            ? files
            : files
                .where(
                  (file) =>
                      file.toLowerCase().contains(_searchQuery.toLowerCase()),
                )
                .toList();

    if (filteredFiles.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off_rounded,
        title: 'No Results',
        subtitle: 'No files match your search',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFiles,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredFiles.length,
        itemBuilder: (context, index) {
          final filename = filteredFiles[index];
          return _buildFileCard(filename: filename, icon: icon, index: index);
        },
      ),
    );
  }

  Widget _buildFileCard({
    required String filename,
    required IconData icon,
    required int index,
  }) {
    final theme = Theme.of(context);
    final isSelected = _selectedFiles.contains(filename);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        shadowColor: theme.colorScheme.shadow.withAlpha(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onFileTap(filename),
          onLongPress: () => _toggleSelection(filename),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border:
                  isSelected
                      ? Border.all(color: theme.colorScheme.primary, width: 2)
                      : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getFileTypeColor(icon).withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: _getFileTypeColor(icon), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        filename,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getFileTypeLabel(icon),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isSelectionMode)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      isSelected ? Icons.check_rounded : Icons.circle_outlined,
                      color:
                          isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                      size: 16,
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onFileTap(String filename) {
    if (_isSelectionMode) {
      _toggleSelection(filename);
    } else {
      // Handle file opening based on type
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening $filename'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Color _getFileTypeColor(IconData icon) {
    if (icon == Icons.description) return Colors.blue;
    if (icon == Icons.audio_file) return Colors.orange;
    if (icon == Icons.video_file) return Colors.red;
    return Colors.grey;
  }

  String _getFileTypeLabel(IconData icon) {
    if (icon == Icons.description) return 'Document';
    if (icon == Icons.audio_file) return 'Audio File';
    if (icon == Icons.video_file) return 'Video File';
    return 'File';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Media Gallery',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              onPressed: () {
                setState(() {
                  _selectedFiles.clear();
                  _isSelectionMode = false;
                });
              },
              icon: const Icon(Icons.clear_rounded),
              tooltip: 'Clear selection',
            ),
            IconButton(
              onPressed: () {
                // Handle bulk actions
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${_selectedFiles.length} files selected'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.more_vert_rounded),
              tooltip: 'More actions',
            ),
          ] else ...[
            IconButton(
              onPressed: () {
                // Toggle search
                setState(() {
                  if (_searchQuery.isNotEmpty) {
                    _searchQuery = '';
                    _searchController.clear();
                  }
                });
              },
              icon: Icon(
                _searchQuery.isNotEmpty
                    ? Icons.search_off_rounded
                    : Icons.search_rounded,
              ),
              tooltip: 'Search',
            ),
          ],
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_searchQuery.isNotEmpty ? 120 : 48),
          child: Column(
            children: [
              if (_searchQuery.isNotEmpty || _searchController.text.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search files...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon:
                          _searchController.text.isNotEmpty
                              ? IconButton(
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                                icon: const Icon(Icons.clear_rounded),
                              )
                              : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              TabBar(
                controller: _tabController,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                indicatorColor: theme.colorScheme.primary,
                indicatorWeight: 3,
                tabs: const [
                  Tab(icon: Icon(Icons.image_rounded), text: 'Images'),
                  Tab(icon: Icon(Icons.description_rounded), text: 'Documents'),
                  Tab(icon: Icon(Icons.audio_file_rounded), text: 'Audio'),
                  Tab(icon: Icon(Icons.video_file_rounded), text: 'Video'),
                ],
              ),
            ],
          ),
        ),
      ),
      body:
          _isLoading
              ? Center(
                child: ShimmerWidgets.mediaPreviewShimmer(context: context),
              )
              : _error != null
              ? _buildErrorState()
              : FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    _buildStorageStats(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildImageGrid(),
                          _buildFileList(_documents, Icons.description_rounded),
                          _buildFileList(_audio, Icons.audio_file_rounded),
                          _buildFileList(_video, Icons.video_file_rounded),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      floatingActionButton:
          _isSelectionMode
              ? null
              : FloatingActionButton.extended(
                onPressed: _loadFiles,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withAlpha(51),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadFiles,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
