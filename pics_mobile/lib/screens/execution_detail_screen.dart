import 'package:flutter/material.dart';
import '../models/execution.dart';
import '../services/sync_service.dart';
import 'execution_form_screen.dart';

class ExecutionDetailScreen extends StatefulWidget {
  final Execution execution;

  const ExecutionDetailScreen({super.key, required this.execution});

  @override
  State<ExecutionDetailScreen> createState() => _ExecutionDetailScreenState();
}

class _ExecutionDetailScreenState extends State<ExecutionDetailScreen> {
  int _unsyncedCount = 0;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadUnsyncedCount();
  }

  Future<void> _loadUnsyncedCount() async {
    final count = await widget.execution.getUnsyncedCount();
    if (mounted) {
      setState(() {
        _unsyncedCount = count;
      });
    }
  }

  Future<void> _handleSync() async {
    if (_isSyncing || _unsyncedCount == 0) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      final result =
          await SyncService.syncBySchedule(widget.execution.scheduleId);

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
    final hasUnsynced = _unsyncedCount > 0;

    return FloatingActionButton.extended(
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
                    ? 'Sync ($�unsyncedCount)'
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
    final pocStatus = widget.execution.partOfCheckStatus.entries.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.execution.eqNumb),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      floatingActionButton: _buildSyncButton(),
      body: ListView(
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
                    '${widget.execution.eqNumb} • ${widget.execution.date}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'SCHEDULE ID: ${widget.execution.scheduleId}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PROGRESS POC: ${widget.execution.fulfilledPocCount}/${widget.execution.targetPocCount}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'TOTAL RESULT: ${widget.execution.resultRowCount}',
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
                                section: widget.execution.section,
                                partOfCheck: entry.key,
                                idSchedule: widget.execution.scheduleId,
                              ),
                            ),
                          );

                          // Reload unsynced count after returning from form
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
      ),
    );
  }
}
