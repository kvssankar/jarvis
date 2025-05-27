import 'package:flutter/material.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shots_studio/utils/memory_utils.dart';

class PerformanceMonitor extends StatefulWidget {
  const PerformanceMonitor({super.key});

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  Map<String, dynamic> _cacheStats = {};

  @override
  void initState() {
    super.initState();
    _updateStats();
  }

  void _updateStats() {
    setState(() {
      _cacheStats = MemoryUtils.getImageCacheStats();
    });
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = 0;
    var size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return "${size.toStringAsFixed(1)} ${suffixes[i]}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Monitor'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _updateStats,
            tooltip: 'Refresh Stats',
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Image Cache Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              'Cache Size',
              '${_cacheStats['currentSize'] ?? 0} / ${_cacheStats['maximumSize'] ?? 0} images',
              Icons.image,
            ),
            _buildStatCard(
              'Memory Usage',
              '${_formatBytes(_cacheStats['currentSizeBytes'] ?? 0)} / ${_formatBytes(_cacheStats['maximumSizeBytes'] ?? 0)}',
              Icons.memory,
            ),
            _buildStatCard(
              'Pending Images',
              '${_cacheStats['pendingImageCount'] ?? 0}',
              Icons.hourglass_empty,
            ),
            const SizedBox(height: 24),
            const Text(
              'Memory Management',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await MemoryUtils.clearImageCacheAndGC();
                  _updateStats();
                  SnackbarService().showSuccess(context, 'Image cache cleared');
                },
                icon: const Icon(Icons.cleaning_services),
                label: const Text('Clear Image Cache'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade200,
                  foregroundColor: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Performance Tips',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Lower screenshot limits (50-100) for better performance\n'
                      '• Clear image cache if app becomes slow\n'
                      '• Restart app if memory usage becomes high\n'
                      '• Consider deleting unused screenshots',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.amber.shade200),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: Text(
          value,
          style: TextStyle(
            color: Colors.amber.shade200,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
