import 'package:flutter/material.dart';
import '../models/execution.dart';
import '../widgets/gradient_app_bar.dart';
import '../services/execution_service.dart';
import '../services/sync_service.dart';
import 'execution_form_screen.dart';
import 'dart:developer' as log;

class ExecutionDetailScreen extends StatefulWidget {
  final String scheduleId;

  const ExecutionDetailScreen({super.key, required this.scheduleId});

  @override
  State<ExecutionDetailScreen> createState() => _ExecutionDetailScreenState();
}

class _ExecutionDetailScreenState extends State<ExecutionDetailScreen> {
  Execution? _execution;
  bool _isLoading = true;
  String? _errorMessage;
  int _unsyncedCount = 0;
  bool _isSyncing = false;

  @override
  void initState() {
    log.log('Loading execution detail for scheduleId: ${widget.scheduleId}');
    super.initState();
    _loadExecutionDetail();
  }

  Future<void> _loadExecutionDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final execution = await ExecutionService.fetchExecutionByScheduleId(
        widget.scheduleId,
      );

      if (!mounted) return;

      setState(() {
        _execution = execution;
      });

      await _loadUnsyncedCount();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUnsyncedCount() async {
    final execution = _execution;
    if (execution == null) return;

    final count = await execution.getUnsyncedCount();
    if (mounted) {
      setState(() {
        _unsyncedCount = count;
      });
    }
  }

  Future<void> _handleSync() async {
    if (_isSyncing || _unsyncedCount == 0) return;

    final execution = _execution;
    if (execution == null) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      final result =
          await SyncService.syncBySchedule(execution.scheduleId);

      if (!mounted) return;

      // Reload unsynced count
      await _loadUnsyncedCount();

      // Show result message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor:
              result.allSuccess ? Colors.green : result.hasFailures ? Colors.orange : null,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      log.log('Error occurred while syncing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saat sinkronisasi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Widget _buildSyncButton() {
    if (_execution == null) {
      return const SizedBox.shrink();
    }

    final hasUnsynced = _unsyncedCount > 0;

    return FloatingActionButton.extended(
      heroTag: 'sync_fab',
      onPressed: _isSyncing ? null : _handleSync,
      icon: _isSyncing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(
              hasUnsynced ? Icons.sync : Icons.check_circle,
              color: Colors.white,
            ),
      label: Row(
        children: [
          Text(
            _isSyncing
                ? 'Syncing...'
                : hasUnsynced
                    ? 'Sync ($_unsyncedCount)'
                    : 'Synced',
            style: const TextStyle(color: Colors.white),
          ),
          if (hasUnsynced && !_isSyncing) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _unsyncedCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      backgroundColor: hasUnsynced ? Colors.orange : Colors.green,
    );
  }

  @override
  Widget build(BuildContext context) {
    final execution = _execution;

    return Scaffold(
      appBar: GradientAppBar(title: _execution?.eqNumb ?? widget.scheduleId),
      floatingActionButton: execution == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'refresh_fab',
                  mini: true,
                  onPressed: _isLoading ? null : _loadExecutionDetail,
                  child: const Icon(Icons.refresh),
                ),
                const SizedBox(width: 12),
                _buildSyncButton(),
              ],
            ),
      body: _buildBody(execution),
    );
  }

  Widget _buildBody(Execution? execution) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                'Gagal memuat detail eksekusi',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadExecutionDetail,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (execution == null) {
      return const Center(child: Text('Data eksekusi tidak ditemukan'));
    }

    final pocStatus = execution.partOfCheckStatus.entries.toList();

    log.log(pocStatus.map((e) => '${e.key}: ${e.value}').join(', '));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DETAIL EKSEKUSI',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '${execution.eqNumb} • ${execution.date}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'SCHEDULE ID: ${execution.scheduleId}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'PROGRESS POC: ${execution.fulfilledPocCount}/${execution.targetPocCount}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'TOTAL RESULT: ${execution.resultRowCount}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STATUS PART OF CHECK',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (pocStatus.isEmpty)
                  Text(
                    'Belum ada konfigurasi PART OF CHECK untuk section ini.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else
                  ...pocStatus.map(
                    (entry) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        entry.value
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: entry.value ? Colors.green : Colors.grey,
                      ),
                      title: Text(entry.key),
                      subtitle: Text(entry.value ? 'SUDAH TERWAKILI' : 'BELUM'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute<bool>(
                            builder: (_) => ExecutionFormScreen(
                              section: execution.section,
                              partOfCheck: entry.key,
                              idSchedule: execution.scheduleId,
                            ),
                          ),
                        );

                        if (result == true && mounted) {
                          await _loadUnsyncedCount();
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Klik Part of Check untuk membuka form inspeksi.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
        ),
      ],
    );
  }
}
