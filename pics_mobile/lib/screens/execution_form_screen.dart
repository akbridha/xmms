import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../widgets/gradient_app_bar.dart';
import '../models/form_item.dart';
import '../services/execution_service.dart';

class ExecutionFormScreen extends StatefulWidget {
  final String section;
  final String partOfCheck;
  final String idSchedule;

  const ExecutionFormScreen({
    super.key,
    required this.section,
    required this.partOfCheck,
    required this.idSchedule,
  });

  @override
  State<ExecutionFormScreen> createState() => _ExecutionFormScreenState();
}

class _ExecutionFormScreenState extends State<ExecutionFormScreen> {
  late Future<FormClaimResponse> _futureForm;
  List<FormItem> _items = [];
  bool _submitting = false;
  bool _showErrors = false;
  bool _isEditMode = false; // Track if form is in edit mode

  static const List<String> _checkOptions = ['v', 'x', 'o'];
  static const Map<String, String> _checkLabels = {
    'v': '✓ Good',
    'x': '✗ Bad',
    'o': '○ Good after Replace',
  };

  @override
  void initState() {
    super.initState();
    _futureForm = _fetchForm();
  }

  Future<FormClaimResponse> _fetchForm() async {
    final response = await ExecutionService.fetchFormItems(
      section: widget.section,
      partOfCheck: widget.partOfCheck,
      idSchedule: widget.idSchedule,
    );
    _items = response.items;
    
    // Check if any item has pre-filled data (edit mode)
    _isEditMode = _items.any((item) => 
      item.inputValue != null && item.inputValue!.isNotEmpty
    );
    
    return response;
  }

  void _retry() {
    setState(() {
      _futureForm = _fetchForm();
    });
  }

  bool get _allFilled => _items.where((item) => item.hasInput).every(
      (item) => item.inputValue != null && item.inputValue!.isNotEmpty);

  Future<void> _submit() async {
    // Stop all running timers
    for (final item in _items) {
      item.stopTimer();
    }

    if (!_allFilled) {
      setState(() => _showErrors = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi semua item sebelum submit')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final message = await ExecutionService.saveForm(
        idSchedule: widget.idSchedule,
        partOfCheck: widget.partOfCheck,
        items: _items,
        inspector: AppConfig.getInspector(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(title: widget.partOfCheck),
      body: FutureBuilder<FormClaimResponse>(
        future: _futureForm,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal memuat form',
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

          final claim = snapshot.data!;

          if (_items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inbox, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(claim.message),
                  const SizedBox(height: 8),
                  const Text('Tidak ada item inspeksi'),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Header info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: _isEditMode 
                    ? Colors.orange[100]
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Row(
                  children: [
                    if (_isEditMode)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.orange[900],
                        ),
                      ),
                    Expanded(
                      child: Text(
                        _isEditMode
                            ? 'Mode Edit • ${claim.message} • Schedule: ${claim.idSchedule}'
                            : '${claim.message} • Schedule: ${claim.idSchedule}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _isEditMode ? Colors.orange[900] : null,
                          fontWeight: _isEditMode ? FontWeight.w600 : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Form items
              Expanded(child: _buildItemList()),
              // Submit button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _submitting 
                            ? 'Menyimpan...' 
                            : (_isEditMode ? 'Update' : 'Submit'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItemList() {
    // Group items by 'item' field
    final grouped = <String, List<int>>{};
    for (int i = 0; i < _items.length; i++) {
      grouped.putIfAbsent(_items[i].item, () => []).add(i);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: grouped.length,
      itemBuilder: (context, groupIndex) {
        final groupKey = grouped.keys.elementAt(groupIndex);
        final indices = grouped[groupKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                groupKey,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            ...indices.map((i) => _buildFormItemCard(_items[i])),
          ],
        );
      },
    );
  }

  Widget _buildFormItemCard(FormItem item) {
    final hasError = _showErrors && item.hasInput && !item.isFilled;
    final hasHistory = item.history.isNotEmpty;

    // Build the main content (same for both expandable and non-expandable)
    final contentColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.detailsItems,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            if (hasError)
              const Icon(Icons.error, color: Colors.red, size: 20),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                '${item.activity} • ${item.value}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ),
            if (item.durationMs > 0)
              Text(
                '${(item.durationMs / 1000).toStringAsFixed(1)}s',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (item.isCheck) _buildCheckInput(item),
        if (item.isMeasure) _buildMeasureInput(item),
      ],
    );

    if (!hasHistory) {
      // No history - return regular card
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: hasError
            ? RoundedRectangleBorder(
                side: const BorderSide(color: Colors.red, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: contentColumn,
        ),
      );
    } else {
      // Has history - return expandable card
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: hasError
            ? RoundedRectangleBorder(
                side: const BorderSide(color: Colors.red, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            childrenPadding: const EdgeInsets.only(
              left: 12,
              right: 12,
              bottom: 12,
            ),
            title: contentColumn,
            children: [
              _buildHistorySection(item.history, item.isMeasure),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildCheckInput(FormItem item) {
    return Row(
      children: _checkOptions.map((option) {
        final selected = item.inputValue == option;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(_checkLabels[option]!),
            selected: selected,
            onSelected: (_) {
              setState(() {
                item.startTimer();
                item.inputValue = option;
                item.stopTimer();
              });
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMeasureInput(FormItem item) {
    return TextFormField(
      initialValue: item.inputValue, // Pre-fill with existing value in edit mode
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: 'Masukkan nilai ${item.value}',
        border: const OutlineInputBorder(),
        isDense: true,
        errorText: (_showErrors && !item.isFilled) ? 'Wajib diisi' : null,
      ),
      onTap: () {
        item.startTimer();
      },
      onChanged: (val) {
        item.inputValue = val;
      },
      onEditingComplete: () {
        item.stopTimer();
        FocusScope.of(context).nextFocus();
      },
    );
  }

  Widget _buildHistorySection(List<dynamic> history, bool isMeasure) {
    if (history.isEmpty) return const SizedBox.shrink();

    // Sort history by date descending (most recent first)
    final sortedHistory = List.from(history);
    sortedHistory.sort((a, b) => b.date.compareTo(a.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Text(
          'Riwayat Inspeksi',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 50,
            minHeight: 0,
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: sortedHistory.length,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              final entry = sortedHistory[index];
              final dateStr = _formatHistoryDate(entry.date);
              final resultStr = _formatHistoryResult(entry.result, isMeasure);

              return Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[300]!, width: 0.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dateStr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 9,
                            color: Colors.grey[600],
                            height: 1.0,
                          ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      resultStr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _getResultColor(entry.result),
                            height: 1.0,
                          ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatHistoryDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  String _formatHistoryResult(String result, bool isMeasure) {
    if (isMeasure) {
      // For measure items, show the numeric value
      return result;
    } else {
      // For check items, show icon based on value
      final lowerResult = result.toLowerCase();
      if (lowerResult == 'v') return '✓';
      if (lowerResult == 'x') return '✗';
      if (lowerResult == 'o') return '○';
      return result; // Fallback to original value
    }
  }

  Color _getResultColor(String result) {
    final lowerResult = result.toLowerCase();
    if (lowerResult == 'v') return Colors.green;
    if (lowerResult == 'x') return Colors.red;
    if (lowerResult == 'o') return Colors.orange;
    return Colors.black87; // Default for numeric values
  }
}
