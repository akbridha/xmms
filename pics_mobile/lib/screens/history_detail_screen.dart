import 'package:flutter/material.dart';
import '../models/history_detail.dart';
import '../services/history_service.dart';
import '../widgets/gradient_app_bar.dart';

class HistoryDetailScreen extends StatefulWidget {
  const HistoryDetailScreen({super.key, required this.eqNumb});

  final String eqNumb;

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  late Future<List<HistoryDetail>> _futureDetail;

  @override
  void initState() {
    super.initState();
    _futureDetail = HistoryService.fetchHistoryDetail(widget.eqNumb);
  }

  void _retry() {
    setState(() {
      _futureDetail = HistoryService.fetchHistoryDetail(widget.eqNumb);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(title: 'Detail History - ${widget.eqNumb}'),
      body: FutureBuilder<List<HistoryDetail>>(
        future: _futureDetail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal memuat detail history',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final details = snapshot.data!;

          if (details.isEmpty) {
            return const Center(
              child: Text('Tidak ada detail untuk unit ini'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: details.length,
            itemBuilder: (context, index) {
              final detail = details[index];
              final entries = detail.entries;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (details.length > 1) ...[
                        Text(
                          'Record ${index + 1}',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(color: Colors.teal),
                        ),
                        const Divider(height: 16),
                      ],
                      ...entries.map(
                        (entry) => _buildFieldRow(context, entry.key, entry.value),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFieldRow(BuildContext context, String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              _formatKey(key),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  /// Convert snake_case or camelCase keys to readable labels
  String _formatKey(String key) {
    return key
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (m) => ' ${m.group(0)}',
        )
        .replaceAll('_', ' ')
        .trim()
        .toLowerCase()
        .replaceFirstMapped(
          RegExp(r'^.'),
          (m) => m.group(0)!.toUpperCase(),
        );
  }
}
