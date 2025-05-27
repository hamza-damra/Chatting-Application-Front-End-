import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/file_access_service.dart';
import '../core/services/token_service.dart';
import '../utils/file_type_helper.dart';
import '../utils/logger.dart';
import '../widgets/shimmer_widgets.dart';

class StorageStatsScreen extends StatefulWidget {
  const StorageStatsScreen({super.key});

  @override
  State<StorageStatsScreen> createState() => _StorageStatsScreenState();
}

class _StorageStatsScreenState extends State<StorageStatsScreen>
    with TickerProviderStateMixin {
  late FileAccessService _fileAccessService;
  bool _isLoading = true;
  String? _error;
  FileStorageStats? _stats;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Initialize file access service
    final tokenService = Provider.of<TokenService>(context, listen: false);
    _fileAccessService = FileAccessService(tokenService: tokenService);

    // Load storage stats
    _loadStorageStats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadStorageStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await _fileAccessService.getFileStorageStats();

      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      AppLogger.e('StorageStatsScreen', 'Error loading storage stats: $e');
      if (mounted) {
        setState(() {
          _error = _getErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('SocketException') ||
        error.toString().contains('NetworkException')) {
      return 'Network connection error. Please check your internet connection and try again.';
    } else if (error.toString().contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    } else if (error.toString().contains('401') ||
        error.toString().contains('Unauthorized')) {
      return 'Authentication error. Please log in again.';
    } else {
      return 'Unable to load storage statistics. Please try again later.';
    }
  }

  List<PieChartSectionData> _getSizeChartSections() {
    if (_stats == null || _stats!.fileSizeByCategory.isEmpty) {
      return [
        PieChartSectionData(
          value: 1,
          title: 'No data',
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          radius: 80,
          titleStyle: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ];
    }

    final colors = _getModernColors();
    final totalSize = _stats!.fileSizeByCategory.values.fold(
      0,
      (a, b) => a + b,
    );

    int colorIndex = 0;
    return _stats!.fileSizeByCategory.entries.map((entry) {
      final color = colors[colorIndex % colors.length];
      final percentage = (entry.value / totalSize * 100);
      colorIndex++;

      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: percentage > 5 ? '${percentage.toStringAsFixed(1)}%' : '',
        color: color,
        radius: 80,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
        badgeWidget:
            percentage > 15
                ? Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                )
                : null,
        badgePositionPercentageOffset: 1.3,
      );
    }).toList();
  }

  List<Color> _getModernColors() {
    final theme = Theme.of(context);
    return [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEF4444), // Red
      const Color(0xFFEC4899), // Pink
    ];
  }

  List<PieChartSectionData> _getCountChartSections() {
    if (_stats == null || _stats!.fileCountByCategory.isEmpty) {
      return [
        PieChartSectionData(
          value: 1,
          title: 'No data',
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          radius: 80,
          titleStyle: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ];
    }

    final colors = _getModernColors();
    final totalCount = _stats!.fileCountByCategory.values.fold(
      0,
      (a, b) => a + b,
    );

    int colorIndex = 0;
    return _stats!.fileCountByCategory.entries.map((entry) {
      final color = colors[colorIndex % colors.length];
      final percentage = (entry.value / totalCount * 100);
      colorIndex++;

      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: percentage > 5 ? '${percentage.toStringAsFixed(1)}%' : '',
        color: color,
        radius: 80,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
        badgeWidget:
            percentage > 15
                ? Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                )
                : null,
        badgePositionPercentageOffset: 1.3,
      );
    }).toList();
  }

  Widget _buildStorageStatsCard() {
    if (_stats == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Storage Overview',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildModernStatItem(
                    icon: Icons.folder_outlined,
                    value: _stats!.totalFiles.toString(),
                    label: 'Total Files',
                    theme: theme,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
                Expanded(
                  child: _buildModernStatItem(
                    icon: Icons.storage_outlined,
                    value: FileTypeHelper.formatFileSize(_stats!.totalSize),
                    label: 'Total Size',
                    theme: theme,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatItem({
    required IconData icon,
    required String value,
    required String label,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCategoryTable() {
    if (_stats == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colors = _getModernColors();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.category_outlined,
                  color: theme.colorScheme.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Files by Category',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._stats!.fileCountByCategory.entries.map((entry) {
            final category = entry.key;
            final count = entry.value;
            final size = FileTypeHelper.formatFileSize(
              _stats!.fileSizeByCategory[category] ?? 0,
            );
            final colorIndex = _stats!.fileCountByCategory.keys
                .toList()
                .indexOf(category);
            final color = colors[colorIndex % colors.length];

            return _buildCategoryItem(
              category: category,
              count: count,
              size: size,
              color: color,
              theme: theme,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryItem({
    required String category,
    required int count,
    required String size,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            FileTypeHelper.getIconForFileType(category),
            color: color,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count files',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            size,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ShimmerWidgets.authLoadingShimmer(context: context);
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadStorageStats,
              icon: const Icon(Icons.refresh),
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

  Widget _buildChartCard({
    required String title,
    required IconData icon,
    required Widget chart,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: theme.colorScheme.tertiary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(height: 220, child: chart),
          if (_stats != null && _stats!.fileCountByCategory.isNotEmpty)
            _buildChartLegend(),
        ],
      ),
    );
  }

  Widget _buildChartLegend() {
    final theme = Theme.of(context);
    final colors = _getModernColors();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children:
            _stats!.fileCountByCategory.entries.map((entry) {
              final colorIndex = _stats!.fileCountByCategory.keys
                  .toList()
                  .indexOf(entry.key);
              final color = colors[colorIndex % colors.length];

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    entry.key,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Statistics'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body:
          _isLoading
              ? _buildLoadingState()
              : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                onRefresh: _loadStorageStats,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildStorageStatsCard(),
                        _buildChartCard(
                          title: 'Storage Size Distribution',
                          icon: Icons.pie_chart_outline,
                          chart: PieChart(
                            PieChartData(
                              sections: _getSizeChartSections(),
                              centerSpaceRadius: 30,
                              sectionsSpace: 2,
                              pieTouchData: PieTouchData(
                                touchCallback: (
                                  FlTouchEvent event,
                                  pieTouchResponse,
                                ) {
                                  // Add touch interaction if needed
                                },
                              ),
                            ),
                          ),
                        ),
                        _buildChartCard(
                          title: 'File Count Distribution',
                          icon: Icons.donut_small_outlined,
                          chart: PieChart(
                            PieChartData(
                              sections: _getCountChartSections(),
                              centerSpaceRadius: 30,
                              sectionsSpace: 2,
                              pieTouchData: PieTouchData(
                                touchCallback: (
                                  FlTouchEvent event,
                                  pieTouchResponse,
                                ) {
                                  // Add touch interaction if needed
                                },
                              ),
                            ),
                          ),
                        ),
                        _buildCategoryTable(),
                        const SizedBox(height: 100), // Space for FAB
                      ],
                    ),
                  ),
                ),
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadStorageStats,
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }
}
