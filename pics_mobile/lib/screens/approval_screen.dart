import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/validation_item.dart';
import '../services/validation_service.dart';
import '../widgets/filter_header_card.dart';
import 'validation_detail_screen.dart';

class ApprovalScreen extends StatefulWidget {
  const ApprovalScreen({super.key});

  @override
  State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen> {
  Future<List<ValidationItem>>? _futureValidations;
  DateTime _selectedDate = DateTime.now();
  String _selectedSection = 'All';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatDisplayDate(DateTime date) {
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }

  void _fetchData() {
    setState(() {
      _futureValidations = ValidationService.fetchValidationList();
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
      helpText: 'Pilih tanggal',
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = DateUtils.dateOnly(pickedDate);
      });
    }
  }

  List<ValidationItem> _applyFilters(List<ValidationItem> items) {
    var filtered = items;

    // Filter by section
    if (_selectedSection != 'All') {
      filtered = filtered.where((item) => item.section == _selectedSection).toList();
    }

    // Filter by date
    final selectedDateStr = _formatDate(_selectedDate);
    filtered = filtered.where((item) => item.date == selectedDateStr).toList();

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approval'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing data...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: FilterHeaderCard(
              title: 'Filter Approval',
              subtitle: 'Saring data approval berdasarkan section dan tanggal.',
              icon: Icons.rule_folder_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Section', style: FilterHeaderCard.labelStyle),
                  const SizedBox(height: 8),
                  FilterControlSurface(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSection,
                        isExpanded: true,
                        dropdownColor: FilterHeaderCard.menuColor,
                        style: FilterHeaderCard.valueStyle,
                        iconEnabledColor: FilterHeaderCard.foregroundColor,
                        items: [
                          const DropdownMenuItem<String>(
                            value: 'All',
                            child: Text(
                              'All',
                              style: FilterHeaderCard.valueStyle,
                            ),
                          ),
                          ...AppConfig.sections.map(
                            (s) => DropdownMenuItem<String>(
                              value: s,
                              child: Text(
                                s,
                                overflow: TextOverflow.ellipsis,
                                style: FilterHeaderCard.valueStyle,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedSection = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
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
                            _formatDisplayDate(_selectedDate),
                            style: FilterHeaderCard.valueStyle.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
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
    if (_futureValidations == null) {
      return const Center(
        child: Text('Loading...'),
      );
    }

    return FutureBuilder<List<ValidationItem>>(
      future: _futureValidations,
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
                    'Gagal memuat data approval',
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

        final allItems = snapshot.data!;
        final filteredItems = _applyFilters(allItems);

        if (filteredItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'Tidak ada data approval',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Pilih tanggal atau section lain',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _fetchData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredItems.length,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemBuilder: (context, index) {
            final item = filteredItems[index];
            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              child: ListTile(
                onTap: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute<bool>(
                      builder: (_) => ValidationDetailScreen(validationItem: item),
                    ),
                  );
                  if (result == true && mounted) {
                    _fetchData();
                  }
                },
                title: Text(
                  item.eqNumb,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      _formatDisplayDate(DateTime.parse(item.date)),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Durasi: ${item.totalDuration}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue[700],
                          ),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          },
        );
      },
    );
  }
}
