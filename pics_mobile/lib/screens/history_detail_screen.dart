import 'package:flutter/material.dart';
import 'package:pics_mobile/services/pdf_service.dart';
import '../models/history_detail.dart';
import '../services/history_service.dart';
import '../widgets/gradient_app_bar.dart';
import 'dart:developer' as developer;
import '../services/file_service.dart';

class HistoryDetailScreen extends StatefulWidget {
  const HistoryDetailScreen({super.key, required this.id, this.eqNumb});

  final String id;
  final String? eqNumb;

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  late Future<HistoryApiResponse> _futureDetail;

  @override
  void initState() {
    super.initState();
    _futureDetail = HistoryService.fetchHistoryDetail(widget.id.toString());
  }

  void _retry() {
    setState(() {
      _futureDetail = HistoryService.fetchHistoryDetail(widget.id.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.eqNumb ?? 'History Detail';
    return Scaffold(
      appBar: GradientAppBar(title: title),
      body: FutureBuilder<HistoryApiResponse>(
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
                      'Gagal memuat detail history',
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

          final response = snapshot.data!;
          final byDate = response.byDate;

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // Equipment header
              _EquipmentHeaderCard(response: response, id: widget.id.toString(),),
              const SizedBox(height: 8),

              if (byDate.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Tidak ada detail untuk unit ini'),
                  ),
                )
              else
                for (final dateEntry in byDate.entries) ...[
                  _DateHeader(dateString: dateEntry.key),
                  for (final item in dateEntry.value)
                    _PocCard(item: item),
                ],
            ],
          );
        },
      ),
    );
  }
}

// ─── Equipment header ────────────────────────────────────────────────────────

class _EquipmentHeaderCard extends StatelessWidget {
  const _EquipmentHeaderCard({required this.response, required this.id});
  final HistoryApiResponse response;
  final String id;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0D2550),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.construction, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                Expanded( 
                  child: Text(
                    response.equipmentCode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.description, 
                    color: Colors.white, 
                    size: 40,
                  ), 
                  onPressed: ()async {
                    developer.log('Cetak detail history');
                    try {
                      // await FileService.downloadFile(id);

                      final data = [
                        {
                          "code_unit": "HT140-0373",
                          "actual_end_time": "2026-04-15 16:16:37",
                          "poc": "BAGIAN BAWAH"
                        },
                        {
                          "code_unit": "HT140-0373",
                          "actual_end_time": "2026-04-16 16:16:37",
                          "poc": "BAGIAN ATAS"
                        },
                        {
                          "code_unit": "HT140-0373",
                          "actual_end_time": "2026-04-17 16:16:37",
                          "poc": "HUB DRUM"
                        },
                        {
                          "code_unit": "HT140-0373",
                          "actual_end_time": "2026-04-17 16:16:37",
                          "poc": "TEMPERATURE"
                        },
                        {
                          "code_unit": "HT140-0373",
                          "actual_end_time": "2026-04-17 16:16:37",
                          "poc": "VIBRATION"
                        },
                        {
                          "id_result": 51083,
                          "schedule_id": 67137,
                          "result_ids": [51083, 51084, 51085, 51086, 51087, 51088, 51089, 51090, 51091, 51092, 51093, 51094, 51095, 51096, 51097, 51098, 51099, 51100, 51101, 51102, 51103, 51104, 51105, 51106, 51107, 51108, 51109, 51110, 51111, 51112],
                          "section": "PLANT PRIME MOVER",
                          "code_unit": "HT140-0373",
                          "actual_end_time": "2026-04-15 16:16:37",
                          "poc": "BAGIAN BAWAH",
                          "hm_km": null,
                          "nrp_name": "{\"nrp\":\"0115118\",\"nama\":\"EKO BUDIANTO\"}",
                          "start_time": "2026-04-15 17:05:20",
                          "end_time": "2026-04-26 11:39:39",
                          "status": "finish",
                          "data": {
                            "BAGIAN BAWAH": [
                              [
                                "ENGINE",
                                [
                                  [
                                    "193",
                                    {
                                      "details_items": "Fuel Filter and Housing",
                                      "activity": "Check",
                                      "value": "no leak fuel, no crack"
                                    },
                                    "o",
                                    0],
                                  [
                                    "194",
                                    {
                                      "details_items": "Stay and Bolt Bottom Guard",
                                      "activity": "Check",
                                      "value": "Condition"
                                    },
                                    "o",
                                    0],
                                  [
                                    "195",
                                    {
                                      "details_items": "Oil Sump",
                                      "activity": "Check",
                                      "value": "no leak, no crack"
                                    },
                                    "o",
                                    0],
                                  [
                                    "196",
                                    {
                                      "details_items": "Mounting Starting Motor",
                                      "activity": "Check",
                                      "value": "condition"
                                    },
                                    "o",
                                    0],
                                  [
                                    "192",
                                    {
                                      "details_items": "Filter Oil ",
                                      "activity": "Check",
                                      "value": "condition"
                                    },
                                    "o",
                                    0]
                                ]
                              ],
                              [
                                "CLUTCH",
                                [
                                  [
                                    "233",
                                    {
                                      "details_items": "Stroke Clutch",
                                      "activity": "Measure",
                                      "value": "mm"
                                    },
                                    "25",
                                    0],
                                  [
                                    "231",
                                    {
                                      "details_items": "Basic Clutch",
                                      "activity": "Measure",
                                      "value": "mm"
                                    },
                                    "25",
                                    0],
                                  [
                                    "293",
                                    {
                                      "details_items": "erg",
                                      "activity": "Add",
                                      "value": "\u003C 0.2 mm"
                                    },
                                    "V",
                                    0]
                                ]
                              ],
                              [
                                "AIR SYSTEM",
                                [
                                  [
                                    "230",
                                    {
                                      "details_items": "Chamber Brake",
                                      "activity": "Check",
                                      "value": "no leak no crack"
                                    },
                                    "o",
                                    0],
                                  [
                                    "229",
                                    {
                                      "details_items": "Hose ",
                                      "activity": "Check",
                                      "value": "festo max 2 per meter"
                                    },
                                    "o",
                                    0]
                                ]
                              ],
                              [
                                "OTHER ATTACHMENT",
                                [
                                  [
                                    "227",
                                    {
                                      "details_items": "Hydraulic Hose",
                                      "activity": "Check",
                                      "value": "no leak, no crack"
                                    },
                                    "o",
                                    0],
                                  [
                                    "226",
                                    {
                                      "details_items": "PTO and Hydraulic Pump",
                                      "activity": "Check",
                                      "value": "no leak, no crack"
                                    },
                                    "o",
                                    0]
                                ]
                              ],
                              [
                                "TRANSMISSION",
                                [
                                  [
                                    "208",
                                    {
                                      "details_items": "Seal Output Transmisi",
                                      "activity": "Check",
                                      "value": "no leak"
                                    },
                                    "o",
                                    0],
                                  [
                                    "207",
                                    {
                                      "details_items": "Oil Level Transmisi",
                                      "activity": "Check",
                                      "value": "level"
                                    },
                                    "o",
                                    0],
                                  [
                                    "206",
                                    {
                                      "details_items": "Servo Clutch",
                                      "activity": "Check",
                                      "value": "no leak"
                                    },
                                    "o",
                                    0],
                                  [
                                    "205",
                                    {
                                      "details_items": "Oil Cooler and Hose",
                                      "activity": "Check",
                                      "value": "no leak"
                                    },
                                    "o",
                                    0],
                                  [
                                    "203",
                                    {
                                      "details_items": "Air Syestem T/M",
                                      "activity": "Check",
                                      "value": "condition"
                                    },
                                    "o",
                                    0],
                                  [
                                    "204",
                                    {
                                      "details_items": "Balancer Shaft",
                                      "activity": "Check",
                                      "value": "no Worn"
                                    },
                                    "o",
                                    0]
                                ]
                              ],
                              [
                                "STEERING",
                                [
                                  [
                                    "198",
                                    {
                                      "details_items": "Shaft Steering",
                                      "activity": "Check",
                                      "value": "condition"
                                    },
                                    "o",
                                    0],
                                  [
                                    "199",
                                    {
                                      "details_items": "Drag Link",
                                      "activity": "Check",
                                      "value": "no worn (Max. 2 mm)"
                                    },
                                    "o",
                                    0],
                                  [
                                    "200",
                                    {
                                      "details_items": "Tie Rod",
                                      "activity": "Check",
                                      "value": "no worn (Max. 2 mm)"
                                    },
                                    "o",
                                    0],
                                  [
                                    "201",
                                    {
                                      "details_items": "Stay Stabilizer",
                                      "activity": "Check",
                                      "value": "no worn (Max. 2 mm)"
                                    },
                                    "o",
                                    0],
                                  [
                                    "202",
                                    {
                                      "details_items": "Steering and Fuel Pump",
                                      "activity": "Check",
                                      "value": "no leak"
                                    },
                                    "o",
                                    0]
                                ]
                              ],
                              [
                                "UNDERCARRIAGE",
                                [
                                  [
                                    "224",
                                    {
                                      "details_items": "Bushing Spring front and rear rh/lh",
                                      "activity": "Check",
                                      "value": "no worn"
                                    },
                                    "o",
                                    0],
                                  [
                                    "212",
                                    {
                                      "details_items": "Propeller Shaft Rear",
                                      "activity": "Measure Cross Joint",
                                      "value": "\u003C 0.2 mm"
                                    },
                                    "o",
                                    0],
                                  [
                                    "214",
                                    {
                                      "details_items": "Seal Input Differential Front",
                                      "activity": "Check",
                                      "value": "no leak"
                                    },
                                    "o",
                                    0],
                                  [
                                    "215",
                                    {
                                      "details_items": "Seal Output Differential Front",
                                      "activity": "Check",
                                      "value": "no leak"
                                    },
                                    "o",
                                    0],
                                  [
                                    "217",
                                    {
                                      "details_items": "Linning Brake",
                                      "activity": "Check",
                                      "value": "condition"
                                    },
                                    "x",
                                    0],
                                  [
                                    "218",
                                    {
                                      "details_items": "Suhu Front Hub ",
                                      "activity": "Check",
                                      "value": "\u003C 77 Â°C"
                                    },
                                    "x",
                                    0],
                                  [
                                    "222",
                                    {
                                      "details_items": "Slack Adjuster",
                                      "activity": "Check",
                                      "value": "no loose, no broken"
                                    },
                                    "x",
                                    0]
                                ]
                              ]
                            ]
                          },
                          "validation_by": "0115118",
                          "validator_name": "EKO BUDIANTO",
                          "validation_time": "2026-04-26 11:39:39"
                        },
                      ];

                      final pdfBytes = await PdfService.generatePdfFromList(data);
                      await FileService.savePdf(pdfBytes);

                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Download berhasil')),
                      );
                    } catch (e) {
                      developer.log('Error saat download: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal download: $e')),
                      );
                    }
                    
                  },)
              ],
            ),
            const SizedBox(height: 6),
            Text(
              response.section,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            const Divider(color: Colors.white24),
            const SizedBox(height: 4),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.play_circle_outline,
                  label: _fmtDateTime(response.firstStartTime),
                  color: Colors.greenAccent,
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.stop_circle_outlined,
                  label: _fmtDateTime(response.lastEndTime),
                  color: Colors.orangeAccent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Date header ─────────────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.dateString});
  final String dateString;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4, left: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _formatDateLabel(dateString),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.teal.shade800,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  String _formatDateLabel(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      const months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

// ─── POC card ────────────────────────────────────────────────────────────────

class _PocCard extends StatelessWidget {
  const _PocCard({required this.item});
  final HistoryDetailItem item;

  @override
  Widget build(BuildContext context) {
    final categories =
        item.data.values.expand((cats) => cats).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor:
              item.status == 'finish' ? Colors.teal : Colors.orange,
          radius: 18,
          child: Icon(
            item.status == 'finish' ? Icons.check : Icons.hourglass_bottom,
            color: Colors.white,
            size: 16,
          ),
        ),
        title: Text(
          item.poc,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.inspectorName != null)
              Text(
                '${item.inspectorName} (${item.inspectorNrp ?? '-'})',
                style: const TextStyle(fontSize: 12),
              ),
            Text(
              '${_fmtTime(item.startTime)} – ${_fmtTime(item.endTime)}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _StatusBadge(status: item.status),
            if (item.validatorName != null) ...[
              const SizedBox(height: 2),
              Text(
                item.validatorName!,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ],
        ),
        children: [
          const Divider(height: 1),
          for (final cat in categories) _CategorySection(category: cat),
        ],
      ),
    );
  }
}

// ─── Category section ─────────────────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.category});
  final HistoryCategory category;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: Colors.grey.shade100,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text(
            category.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.teal.shade700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        for (int i = 0; i < category.items.length; i++)
          _InspectionItemRow(
            item: category.items[i],
            isEven: i.isEven,
          ),
      ],
    );
  }
}

// ─── Inspection item row ──────────────────────────────────────────────────────

class _InspectionItemRow extends StatelessWidget {
  const _InspectionItemRow({required this.item, required this.isEven});
  final HistoryInspectionItem item;
  final bool isEven;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isEven ? Colors.white : Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.detailsItems,
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  '${item.activity} · ${item.expectedValue}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _ActualValueBadge(value: item.actualValue),
        ],
      ),
    );
  }
}

// ─── Actual value badge ───────────────────────────────────────────────────────

class _ActualValueBadge extends StatelessWidget {
  const _ActualValueBadge({required this.value});
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) {
      return const Text('-', style: TextStyle(color: Colors.grey));
    }
    final lower = value!.toLowerCase();
    if (lower == 'v') {
      return const Icon(Icons.check_circle, color: Colors.green, size: 20);
    } else if (lower == 'x') {
      return const Icon(Icons.cancel, color: Colors.red, size: 20);
    } else if (lower == 'o') {
      return const Icon(
        Icons.radio_button_checked,
        color: Colors.orange,
        size: 20,
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Text(
        value!,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.teal.shade800,
        ),
      ),
    );
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final isFinish = status == 'finish';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isFinish ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isFinish ? Colors.green.shade300 : Colors.orange.shade300,
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isFinish ? Colors.green.shade800 : Colors.orange.shade800,
        ),
      ),
    );
  }
}

// ─── Info chip ────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 11),
        ),
      ],
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _fmtDateTime(String dt) {
  if (dt.length < 16) return dt;
  return dt.substring(0, 16);
}

String _fmtTime(String dt) {
  if (dt.length < 16) return dt;
  return dt.substring(11, 16);
}


