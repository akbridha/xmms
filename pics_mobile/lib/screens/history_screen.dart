import 'dart:developer';

import 'package:flutter/material.dart';
import '../models/history.dart';
import '../services/history_service.dart';
import '../widgets/filter_header_card.dart';
import '../widgets/gradient_app_bar.dart';
import 'history_detail_screen.dart';
import 'dart:developer'as cetak;

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<History>> _futureHistories;
  DateTime? _selectedDate;
  int _rowLimit = 25;
  static const List<int> _rowLimitOptions = [5, 25, 50, 100];

  @override
  void initState() {
    super.initState();
    _futureHistories = HistoryService.fetchHistories();
  }

  void _retry() {
    setState(() {
      _futureHistories = HistoryService.fetchHistories();
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
      helpText: 'Pilih tanggal history',
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
      appBar: const GradientAppBar(title: 'History'),
      body: FutureBuilder<List<History>>(
        future: _futureHistories,
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
                      'Gagal memuat history',
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

          final histories = snapshot.data!;
          final filteredHistories = _selectedDate == null
              ? histories
              : histories.where((h) {
                  final parsedDate = DateTime.tryParse(h.date);
                  if (parsedDate == null) return false;
                  return DateUtils.dateOnly(parsedDate) == _selectedDate;
                }).toList();
          final limitedHistories =
              filteredHistories.take(_rowLimit).toList();

          if (histories.isEmpty) {
            return const Center(child: Text('Tidak ada data history'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: FilterHeaderCard(
                  title: 'History',
                  subtitle: 'Pilih tanggal untuk fokus pada history yang relevan.',
                  icon: Icons.history_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tanggal', style: FilterHeaderCard.labelStyle),
                      const SizedBox(height: 8),
                      FilterControlSurface(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _selectedDate == null
                                    ? 'Semua tanggal'
                                    : _formatDate(_selectedDate!),
                                style: FilterHeaderCard.valueStyle.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _pickDate,
                            style: FilterHeaderCard.actionButtonStyle,
                            icon: const Icon(Icons.date_range),
                            label: const Text('Pilih Tanggal'),
                          ),
                          if (_selectedDate != null)
                            TextButton.icon(
                              onPressed: _clearDateFilter,
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    FilterHeaderCard.secondaryForegroundColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(Icons.close),
                              label: const Text('Hapus Filter'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Row(
                  children: [
                    Text(
                      'Menampilkan ${limitedHistories.length} dari ${filteredHistories.length} data',
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
              if (filteredHistories.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('Tidak ada history pada tanggal ini'),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: limitedHistories.length,
                    itemBuilder: (context, index) {
                      final history = limitedHistories[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal,
                            child: const Icon(
                              Icons.history,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(history.eqNumb),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(history.date),
                              if (history.section != null)
                                Text(
                                  history.section!,
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (history.status != null)
                                Text(
                                  history.status!,
                                  style: TextStyle(
                                    color: Colors.teal.shade700,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap: () {
                            // if (history.schedule_id == null) return;
                            // cetak.log("on tap listview history schedule_id: ${history.schedule_id}");
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => HistoryDetailScreen(
                                  id: history.schedule_id!,
                                  eqNumb: history.eqNumb,
                                ),
                              ),
                            );
                          },
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
