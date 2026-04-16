import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/gradient_app_bar.dart';
import '../config/app_config.dart';
import '../models/execution.dart';
import '../services/execution_service.dart';
import '../widgets/filter_header_card.dart';
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
  late TextEditingController _searchController;
  String _searchQuery = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // Auto-set date to today and fetch data for all users
    final user = AppConfig.loggedInUser;
    if (user != null) {
      _selectedDate = DateUtils.dateOnly(DateTime.now());
      // Delay fetch to allow widget to build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchData();
      });
    }
  }

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
        search: _searchQuery,
      );
    });
  }

  void _onSearchChanged(String value) {
    if (_searchQuery == value) return;
    setState(() {
      _searchQuery = value;
    });
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
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

  Widget _buildPocStatusIcons(Execution execution) {
    final statuses = execution.partOfCheckStatus.entries.toList();

    if (statuses.isEmpty) {
      final isDone = execution.hasResults;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isDone ? Colors.green : Colors.grey,
            size: 18,
          ),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: statuses
          .map(
            (entry) => Icon(
              entry.value ? Icons.check_circle : Icons.radio_button_unchecked,
              color: entry.value ? Colors.green : Colors.grey,
              size: 18,
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(
        title: 'Eksekusi',
        gradientColors: [kCalmTealEnd, kCalmTealMid, kCalmTealStart],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: FilterHeaderCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FilterControlSurface(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSection,
                        isExpanded: true,
                        dropdownColor: FilterHeaderCard.menuColor,
                        style: FilterHeaderCard.valueStyle,
                        iconEnabledColor: FilterHeaderCard.foregroundColor,
                        items: AppConfig.sections
                            .map(
                              (s) => DropdownMenuItem<String>(
                                value: s,
                                child: Text(
                                  s,
                                  overflow: TextOverflow.ellipsis,
                                  style: FilterHeaderCard.valueStyle,
                                ),
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
                  ),
                  const SizedBox(height: 8),
                  FilterControlSurface(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _selectedDate == null
                                ? 'Belum dipilih'
                                : _formatDate(_selectedDate!),
                            style: FilterHeaderCard.valueStyle.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilterControlSurface(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Ketik kata kunci',
                              border: InputBorder.none,
                              isDense: true,
                              suffixIcon:
                                  _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _searchController.clear();
                                            _onSearchChanged('');
                                          },
                                        )
                                      : null,
                            ),
                            onChanged: _onSearchChanged,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _fetchData(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _fetchData,
                        ),
                      ],
                    ),
                  ),
                  if (AppConfig.loggedInUser?.role == 'administrator') ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        style: FilterHeaderCard.actionButtonStyle,
                        icon: const Icon(Icons.date_range),
                        label: const Text('Pilih Tanggal'),
                      ),
                    ),
                  ],
                ],
              ),
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
                                ExecutionDetailScreen(eqNumb: execution.eqNumb),
                          ),
                        );
                      },
                      title: Text(execution.eqNumb),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${execution.date} • POC: ${execution.fulfilledPocCount}/${execution.targetPocCount} ',
                          ),
                          const SizedBox(height: 6),
                          _buildPocStatusIcons(execution),
                        ],
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
