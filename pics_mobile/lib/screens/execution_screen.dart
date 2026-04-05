import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/execution.dart';
import '../services/execution_service.dart';
import 'execution_detail_screen.dart';

class ExecutionScreen extends StatefulWidget {
  const ExecutionScreen({super.key});

  @override
  State<ExecutionScreen> createState() => _ExecutionScreenState();
}

class _ExecutionScreenState extends State<ExecutionScreen> {
  Future<List<Execution>>? _futureExecutions;
  DateTime? _selectedDate;
  String _selectedSection = AppConfig.sections.first;
  int _rowLimit = 25;
  static const List<int> _rowLimitOptions = [5, 25, 50, 100];

  String _formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  void _fetchData() {
    if (_selectedDate == null) return;
    setState(() {
      _futureExecutions = ExecutionService.fetchExecutions(
        section: _selectedSection,
        date: _formatDate(_selectedDate!),
      );
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
      helpText: 'Pilih tanggal eksekusi',
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = DateUtils.dateOnly(pickedDate);
      });
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eksekusi'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Section dropdown
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                const Text('Section: '),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedSection,
                    isExpanded: true,
                    items: AppConfig.sections
                        .map(
                          (s) => DropdownMenuItem<String>(
                            value: s,
                            child: Text(s, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedSection = value;
                      });
                      _fetchData();
                    },
                  ),
                ),
              ],
            ),
          ),
          // Date picker
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? 'Tanggal: Belum dipilih'
                        : 'Tanggal: ${_formatDate(_selectedDate!)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.date_range),
                  label: const Text('Pilih Tanggal'),
                ),
              ],
            ),
          ),
          // Content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_futureExecutions == null) {
      return const Center(
        child: Text('Pilih section dan tanggal untuk memuat data'),
      );
    }

    return FutureBuilder<List<Execution>>(
      future: _futureExecutions,
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
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Gagal memuat data eksekusi',
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
                    onPressed: _fetchData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        }

        final executions = snapshot.data!;
        final limitedExecutions = executions.take(_rowLimit).toList();

        if (executions.isEmpty) {
          return const Center(child: Text('Tidak ada data eksekusi'));
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  Text(
                    'Menampilkan ${limitedExecutions.length} dari ${executions.length} data',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  const Text('Baris: '),
                  DropdownButton<int>(
                    value: _rowLimit,
                    items: _rowLimitOptions
                        .map(
                          (limit) => DropdownMenuItem<int>(
                            value: limit,
                            child: Text(limit.toString()),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _rowLimit = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: limitedExecutions.length,
                itemBuilder: (context, index) {
                  final execution = limitedExecutions[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ExecutionDetailScreen(execution: execution),
                          ),
                        );
                      },
                      leading: CircleAvatar(
                        backgroundColor:
                            execution.hasResults ? Colors.green : Colors.grey,
                        child: Icon(
                          execution.hasResults
                              ? Icons.check
                              : Icons.pending_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(execution.eqNumb),
                      subtitle: Text(
                        '${execution.date} • POC: ${execution.pocCount}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
