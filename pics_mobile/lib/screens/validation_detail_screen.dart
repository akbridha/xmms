import 'package:flutter/material.dart';
import '../models/validation_item.dart' as models;
import '../models/validation_detail.dart';
import '../services/validation_service.dart';

class ValidationDetailScreen extends StatefulWidget {
  final models.ValidationItem validationItem;

  const ValidationDetailScreen({super.key, required this.validationItem});

  @override
  State<ValidationDetailScreen> createState() => _ValidationDetailScreenState();
}

class _ValidationDetailScreenState extends State<ValidationDetailScreen> {
  Future<ValidationDetail>? _futureDetail;
  bool _isProcessing = false;
  String? _selectedPoc;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  void _loadDetail() {
    setState(() {
      _futureDetail = ValidationService.fetchValidationDetail(
        widget.validationItem.scheduleId.toString(),
      );
    });
  }

  String _formatDisplayDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatDisplayDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '${dateTime.day} ${monthNames[dateTime.month - 1]} ${dateTime.year} $hour:$minute';
    } catch (e) {
      return dateTimeStr;
    }
  }

  Future<void> _handleApproval(bool isApproved) async {
    // Check if POC is selected
    if (_selectedPoc == null || _selectedPoc!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih POC terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isApproved ? 'Approve Validation' : 'Reject Validation'),
        content: Text(
          isApproved
              ? 'Apakah Anda yakin ingin menyetujui validation ini?'
              : 'Apakah Anda yakin ingin menolak validation ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: isApproved ? Colors.green : Colors.red,
            ),
            child: Text(isApproved ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // TODO: Replace with actual NRP from user session/SharedPreferences
      const userNrp = '0000000'; // Placeholder NRP
      
      final success = await ValidationService.submitApprovalAction(
        scheduleId: widget.validationItem.scheduleId.toString(),
        poc: _selectedPoc!,
        nrp: userNrp,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isApproved
                  ? 'Validation berhasil disetujui'
                  : 'Validation berhasil ditolak',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Return true to signal parent to refresh
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Approval'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Expanded(child: _buildContent()),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_futureDetail == null) {
      return const Center(child: Text('Loading...'));
    }

    return FutureBuilder<ValidationDetail>(
      future: _futureDetail,
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
                    'Gagal memuat detail',
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
                    onPressed: _loadDetail,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        }

        final detail = snapshot.data!;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INFORMASI UMUM',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Equipment', widget.validationItem.eqNumb),
                    _buildInfoRow('Section', widget.validationItem.section),
                    _buildInfoRow(
                      'Tanggal',
                      _formatDisplayDate(widget.validationItem.date),
                    ),
                    _buildInfoRow(
                      'Total Durasi',
                      widget.validationItem.totalDuration,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // POC Selection
            if (detail.data.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PILIH POC UNTUK APPROVAL',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ...detail.data.map((resultData) {
                        return RadioListTile<String>(
                          value: resultData.poc,
                          groupValue: _selectedPoc,
                          onChanged: (value) {
                            setState(() {
                              _selectedPoc = value;
                            });
                          },
                          title: Text(
                            resultData.poc,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Status: ${resultData.status}\n'
                            'Start: ${_formatDisplayDateTime(resultData.startTime)}\n'
                            'End: ${_formatDisplayDateTime(resultData.endTime)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // POC Details
            ...detail.data.map((resultData) {
              return _buildPocSection(resultData);
            }),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPocSection(ValidationResultData resultData) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          resultData.poc,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Status: ${resultData.status} • Code: ${resultData.codeUnit}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Metadata
                _buildInfoRow('Section', resultData.section),
                _buildInfoRow('NRP/Name', resultData.nrpName),
                _buildInfoRow('Start Time', _formatDisplayDateTime(resultData.startTime)),
                _buildInfoRow('End Time', _formatDisplayDateTime(resultData.endTime)),
                if (resultData.hmKm != null)
                  _buildInfoRow('HM/KM', resultData.hmKm!),
                const Divider(height: 24),

                // Categories and Items
                ...resultData.data.entries.map((entry) {
                  final pocName = entry.key;
                  final categories = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pocName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                      ),
                      const SizedBox(height: 8),
                      ...categories.map((category) {
                        return _buildCategorySection(category);
                      }),
                      const SizedBox(height: 16),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(ValidationCategory category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ...category.items.map((item) {
            return _buildItemRow(item);
          }),
        ],
      ),
    );
  }

  Widget _buildItemRow(DetailValidationItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.details.detailsItems,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${item.details.activity}: ${item.details.value}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.flag == 0 ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: item.flag == 0 ? Colors.green : Colors.orange,
                  ),
                ),
                child: Text(
                  item.inputValue,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: item.flag == 0 ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : () => _handleApproval(false),
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.close),
                label: const Text('Reject'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : () => _handleApproval(true),
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: const Text('Approve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
