import 'package:flutter/material.dart';
import '../models/execution.dart';

class ExecutionDetailScreen extends StatelessWidget {
  final Execution execution;

  const ExecutionDetailScreen({super.key, required this.execution});

  @override
  Widget build(BuildContext context) {
    final pocStatus = execution.partOfCheckStatus.entries.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(execution.eqNumb),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
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
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Halaman ini read-only.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }
}
