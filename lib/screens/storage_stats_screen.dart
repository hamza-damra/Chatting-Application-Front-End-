import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/file_access_service.dart';
import '../core/services/token_service.dart';
import '../utils/file_type_helper.dart';
import '../utils/logger.dart';

class StorageStatsScreen extends StatefulWidget {
  const StorageStatsScreen({super.key});

  @override
  State<StorageStatsScreen> createState() => _StorageStatsScreenState();
}

class _StorageStatsScreenState extends State<StorageStatsScreen> {
  late FileAccessService _fileAccessService;
  bool _isLoading = true;
  String? _error;
  FileStorageStats? _stats;

  @override
  void initState() {
    super.initState();

    // Initialize file access service
    final tokenService = Provider.of<TokenService>(context, listen: false);
    _fileAccessService = FileAccessService(tokenService: tokenService);

    // Load storage stats
    _loadStorageStats();
  }

  Future<void> _loadStorageStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await _fileAccessService.getFileStorageStats();

      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.e('StorageStatsScreen', 'Error loading storage stats: $e');
      setState(() {
        _error = 'Failed to load storage statistics: $e';
        _isLoading = false;
      });
    }
  }

  List<PieChartSectionData> _getSizeChartSections() {
    if (_stats == null || _stats!.fileSizeByCategory.isEmpty) {
      return [
        PieChartSectionData(
          value: 1,
          title: 'No data',
          color: Colors.grey,
          radius: 100,
        ),
      ];
    }

    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];

    int colorIndex = 0;
    return _stats!.fileSizeByCategory.entries.map((entry) {
      final color = colors[colorIndex % colors.length];
      colorIndex++;

      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: entry.key,
        color: color,
        radius: 100,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      );
    }).toList();
  }

  List<PieChartSectionData> _getCountChartSections() {
    if (_stats == null || _stats!.fileCountByCategory.isEmpty) {
      return [
        PieChartSectionData(
          value: 1,
          title: 'No data',
          color: Colors.grey,
          radius: 100,
        ),
      ];
    }

    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];

    int colorIndex = 0;
    return _stats!.fileCountByCategory.entries.map((entry) {
      final color = colors[colorIndex % colors.length];
      colorIndex++;

      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: entry.key,
        color: color,
        radius: 100,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      );
    }).toList();
  }

  Widget _buildStorageStatsCard() {
    if (_stats == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Storage Overview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.folder,
                  value: _stats!.totalFiles.toString(),
                  label: 'Total Files',
                ),
                _buildStatItem(
                  icon: Icons.sd_storage,
                  value: FileTypeHelper.formatFileSize(_stats!.totalSize),
                  label: 'Total Size',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildCategoryTable() {
    if (_stats == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Files by Category',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DataTable(
              columns: const [
                DataColumn(label: Text('Category')),
                DataColumn(label: Text('Files')),
                DataColumn(label: Text('Size')),
              ],
              rows:
                  _stats!.fileCountByCategory.entries.map((entry) {
                    final category = entry.key;
                    final count = entry.value;
                    final size = FileTypeHelper.formatFileSize(
                      _stats!.fileSizeByCategory[category] ?? 0,
                    );

                    return DataRow(
                      cells: [
                        DataCell(Text(category)),
                        DataCell(Text(count.toString())),
                        DataCell(Text(size)),
                      ],
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Storage Statistics')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildStorageStatsCard(),

                    // Size distribution chart
                    Card(
                      margin: const EdgeInsets.all(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Storage Size Distribution',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: PieChart(
                                PieChartData(
                                  sections: _getSizeChartSections(),
                                  centerSpaceRadius: 40,
                                  sectionsSpace: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // File count distribution chart
                    Card(
                      margin: const EdgeInsets.all(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'File Count Distribution',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: PieChart(
                                PieChartData(
                                  sections: _getCountChartSections(),
                                  centerSpaceRadius: 40,
                                  sectionsSpace: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    _buildCategoryTable(),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadStorageStats,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
