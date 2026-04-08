import 'package:flutter/material.dart';
import '../config/app_config.dart';
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

  static const List<String> _checkOptions = ['v', 'x', 'o'];
  static const Map<String, String> _checkLabels = {
    'v': '✓ Good',
    'x': '✗ Bad',
    'o': '○ Good with note',
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
    return response;
  }

  void _retry() {
    setState(() {
      _futureForm = _fetchForm();
    });
  }

  bool get _allFilled => _items.every((item) =>
      item.inputValue != null && item.inputValue!.isNotEmpty);

  Future<void> _submit() async {
    if (!_allFilled) {
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
        inspector: AppConfig.currentInspector,
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
      appBar: AppBar(
        title: Text(widget.partOfCheck),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
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
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Text(
                  '${claim.message} • Schedule: ${claim.idSchedule}',
                  style: Theme.of(context).textTheme.bodySmall,
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
                      label: Text(_submitting ? 'Menyimpan...' : 'Submit'),
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.detailsItems,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${item.activity} • ${item.value}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            if (item.isCheck) _buildCheckInput(item),
            if (item.isMeasure) _buildMeasureInput(item),
          ],
        ),
      ),
    );
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
                item.inputValue = option;
              });
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMeasureInput(FormItem item) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Masukkan nilai ${item.value}',
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (val) {
        item.inputValue = val;
      },
    );
  }
}
