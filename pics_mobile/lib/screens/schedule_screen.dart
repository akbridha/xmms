import 'package:flutter/material.dart';
import '../models/schedule.dart';
import '../services/schedule_service.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late Future<List<Schedule>> _futureSchedules;
  DateTime? _selectedDate;
  int _rowLimit = 25;
  static const List<int> _rowLimitOptions = [5, 25, 50, 100];

  @override
  void initState() {
    super.initState();
    _futureSchedules = ScheduleService.fetchSchedules();
  }

  void _retry() {
    setState(() {
      _futureSchedules = ScheduleService.fetchSchedules();
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
      helpText: 'Pilih tanggal jadwal',
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = DateUtils.dateOnly(pickedDate);
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
    });
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FutureBuilder<List<Schedule>>(
        future: _futureSchedules,
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
                      'Gagal memuat jadwal',
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

          final schedules = snapshot.data!;
          final filteredSchedules = _selectedDate == null
              ? schedules
              : schedules.where((schedule) {
                  final parsedDate = DateTime.tryParse(schedule.date);
                  if (parsedDate == null) {
                    return false;
                  }

                  final normalized = DateUtils.dateOnly(parsedDate);
                  return normalized == _selectedDate;
                }).toList();
          final limitedSchedules = filteredSchedules.take(_rowLimit).toList();

          if (schedules.isEmpty) {
            return const Center(child: Text('Tidak ada jadwal'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedDate == null
                            ? 'Filter: Semua tanggal'
                            : 'Filter: ${_formatDate(_selectedDate!)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.date_range),
                      label: const Text('Pilih Tanggal'),
                    ),
                    const SizedBox(width: 8),
                    if (_selectedDate != null)
                      IconButton(
                        onPressed: _clearDateFilter,
                        tooltip: 'Hapus filter',
                        icon: const Icon(Icons.clear),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Row(
                  children: [
                    Text(
                      'Menampilkan ${limitedSchedules.length} dari ${filteredSchedules.length} data',
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
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _rowLimit = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              if (filteredSchedules.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('Tidak ada jadwal pada tanggal ini'),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: limitedSchedules.length,
                    itemBuilder: (context, index) {
                      final schedule = limitedSchedules[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: schedule.valid == 1
                                ? Colors.green
                                : Colors.grey,
                            child: Icon(
                              schedule.valid == 1 ? Icons.check : Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(schedule.equipmentCode),
                          subtitle: Text(schedule.date),
                          trailing: Text(
                            schedule.valid == 1 ? 'Valid' : 'Invalid',
                            style: TextStyle(
                              color: schedule.valid == 1
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
