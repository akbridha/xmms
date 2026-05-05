import 'dart:io';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;


// class PdfService {



//     static Future<List<int>> generatePdfFromList(List<Map<String, dynamic>> data) async{
//      final pdf = pw.Document();
     
//       pw.TableRow _row(String label, String value) {
//         return pw.TableRow(
//           children: [
//             pw.Padding(
//               padding: const pw.EdgeInsets.all(4),
//               child: pw.Text(
//                 label,
//                 style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//               ),
//             ),
//             pw.Padding(
//               padding: const pw.EdgeInsets.all(4),
//               child: pw.Text(value),
//             ),
//           ],
//         );
//       }

//     pdf.addPage(
//   pw.MultiPage(
//     pageFormat: PdfPageFormat.a4,
//     build: (context) {
//       List<pw.Widget> widgets = [];
      
//       // Header
//       widgets.add(pw.Text(
//         'PI HISTORY REPORT',
//         style: pw.TextStyle(fontSize: 18),
//       ));
//       widgets.add(pw.SizedBox(height: 20));
      
//       // Loop data
//       for (var i = 0; i < data.length; i++) {
//         final item = data[i];
        
//         // Tambahkan tabel
//         widgets.add(
//           pw.Container(
//             decoration: pw.BoxDecoration(
//               color: PdfColors.grey300,
//               border: pw.TableBorder.all(),
//             ),
//             child: pw.Center(
//               child: pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                 children: [
//                   pw.Text('DATA', style: pw.TextStyle(fontSize: 14)),
//                   pw.SizedBox(height: 8),
//                   pw.Table(
//                     columnWidths: {
//                       0: const pw.FlexColumnWidth(2),
//                       1: const pw.FlexColumnWidth(4),
//                     },
//                     children: [
//                       _row('Code Unit', item['code_unit'] ?? ''),
//                       _row('End Time', item['end_time'] ?? ''),
//                       _row('POC', item['poc'] ?? ''),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
        
//         // Tambahkan jarak antar tabel (kecuali setelah tabel terakhir)
//         if (i < data.length - 1) {
//           widgets.add(pw.SizedBox(height: 20));
//         }
//       }
      
//       return widgets;
//     },
//   ),
// );

//     return pdf.save();
//   }
// }


import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {
  static Future<List<int>> generatePdfFromList(List<Map<String, dynamic>> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        maxPages: 1000,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          final List<pw.Widget> widgets = [];

          for (var i = 0; i < data.length; i++) {
            final item = data[i];

            // --- Header laporan per POC ---
            widgets.add(pw.Text(
              'PI HISTORY REPORT',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ));
            widgets.add(pw.SizedBox(height: 16));
            widgets.add(_infoTable(item));
            widgets.add(pw.SizedBox(height: 20));

            // --- Detail data sebagai list widget terpisah ---
            widgets.addAll(_buildDetailDataAsList(item['data'], item['poc']));

            // Pemisah antar POC (kecuali yang terakhir)
            if (i < data.length - 1) {
              widgets.add(pw.Divider(thickness: 2, height: 30));
            }
          }
          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  // Tabel informasi utama
  static pw.Widget _infoTable(Map<String, dynamic> item) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey500),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      padding: const pw.EdgeInsets.all(8),
      child: pw.Table(
        columnWidths: {
          0: const pw.FlexColumnWidth(1.5),
          1: const pw.FlexColumnWidth(3),
        },
        children: [
          _row('Code Unit', item['code_unit'] ?? '-'),
          _row('Section', item['section'] ?? '-'),
          _row('POC', item['poc'] ?? '-'),
          _row('Start Time', item['start_time'] ?? '-'),
          _row('End Time', item['end_time'] ?? '-'),
          _row('Actual End Time', item['actual_end_time'] ?? '-'),
          _row('Status', item['status'] ?? '-'),
          _row('Validator', '${item['validator_name'] ?? '-'} (${item['validation_by'] ?? '-'})'),
          _row('Validation Time', item['validation_time'] ?? '-'),
        ],
      ),
    );
  }

  // Mengembalikan List widget untuk detail data (bukan Column)
  static List<pw.Widget> _buildDetailDataAsList(dynamic dataMap, String pocName) {
    final List<pw.Widget> widgets = [];

    if (dataMap == null) {
      widgets.add(pw.Text('Tidak ada data detail', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)));
      return widgets;
    }

    dataMap.forEach((pocKey, pocValue) {
      widgets.add(pw.Text(
        'POC: $pocKey',
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
      ));
      widgets.add(pw.SizedBox(height: 8));

      if (pocValue is! List) return;
      for (var group in pocValue) {
        if (group is! List || group.length < 2) continue;
        final headerLabel = group[0] as String? ?? 'Tanpa Label';
        final detailItems = group[1] as List? ?? [];

        widgets.add(pw.Text(
          ' $headerLabel',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ));
        widgets.add(pw.SizedBox(height: 6));

        if (detailItems.isEmpty) {
          widgets.add(pw.Text('(Tidak ada item)', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)));
          widgets.add(pw.SizedBox(height: 8));
          continue;
        }

        widgets.add(_detailTable(detailItems));
        widgets.add(pw.SizedBox(height: 16));
      }
    });

    return widgets;
  }

  // Tabel detail item dengan 10 kolom Result (hanya kolom pertama yang terisi)
static pw.Widget _detailTable(List<dynamic> detailItems) {
  final List<pw.TableRow> rows = [];

  // Header: No, Details Items, Activity, lalu 10 kolom Result
  final List<pw.Widget> headerChildren = [
    _headerCell('No', fontSize: 7),
    _headerCell('Details Items', fontSize: 7),
    _headerCell('Activity', fontSize: 7),
  ];
  for (int i = 1; i <= 10; i++) {
    headerChildren.add(_headerCell('R$i', fontSize: 7));
  }

  rows.add(
    pw.TableRow(
      decoration: pw.BoxDecoration(color: PdfColors.grey300),
      children: headerChildren,
    ),
  );

  // Data rows
  for (var i = 0; i < detailItems.length; i++) {
    final List<pw.Widget> rowChildren = [];

    // Kolom No, Details Items, Activity
    rowChildren.add(_cell('${i + 1}', fontSize: 6));
    rowChildren.add(_cell(_getDetailItemName(detailItems[i]), fontSize: 6));
    rowChildren.add(_cell(_getDetailActivity(detailItems[i]), fontSize: 6));

    // Kolom Result pertama (dengan nilai result & duration)
    final resultText = _getDetailResult(detailItems[i]);
    final durationText = _getDetailDuration(detailItems[i]);
    rowChildren.add(
      pw.Padding(
        padding: const pw.EdgeInsets.all(2),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(resultText, style: const pw.TextStyle(fontSize: 6)),
            pw.Text(durationText, style: const pw.TextStyle(fontSize: 6)),
          ],
        ),
      ),
    );

    // Kolom Result ke-2 sampai ke-10 (kosong)
    for (int j = 2; j <= 10; j++) {
      rowChildren.add(_cell('', fontSize: 6));
    }

    rows.add(pw.TableRow(children: rowChildren));
  }

  // Lebar kolom: No (0.3), Details Items (2.5), Activity (1.0), 10 kolom Result masing-masing (0.4)
  final Map<int, pw.FlexColumnWidth> columnWidths = {
    0: const pw.FlexColumnWidth(0.3),
    1: const pw.FlexColumnWidth(2.5),
    2: const pw.FlexColumnWidth(1.0),
  };
  for (int i = 3; i < 13; i++) {
    columnWidths[i] = const pw.FlexColumnWidth(0.4);
  }

  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.3),
    columnWidths: columnWidths,
    children: rows,
  );
}

  // Helper ekstraktor
  static String _getDetailItemName(List<dynamic> detail) {
    if (detail.length < 2) return '-';
    final obj = detail[1];
    if (obj is Map) return obj['details_items']?.toString() ?? '-';
    return '-';
  }

  static String _getDetailActivity(List<dynamic> detail) {
    if (detail.length < 2) return '-';
    final obj = detail[1];
    if (obj is Map) return obj['activity']?.toString() ?? '-';
    return '-';
  }

  static String _getDetailValue(List<dynamic> detail) {
    if (detail.length < 2) return '-';
    final obj = detail[1];
    if (obj is Map) return obj['value']?.toString() ?? '-';
    return '-';
  }

  static String _getDetailResult(List<dynamic> detail) {
    if (detail.length < 3) return '-';
    return detail[2]?.toString() ?? '-';
  }

  static String _getDetailDuration(List<dynamic> detail) {
    if (detail.length < 4) return '-';
    return detail[3]?.toString() ?? '-';
  }

  // Styling
  static pw.Widget _headerCell(String text, {double fontSize = 8}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(2),
    child: pw.Text(
      text,
      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: fontSize),
      textAlign: pw.TextAlign.center,
    ),
  );
}

static pw.Widget _cell(String text, {double fontSize = 7}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(1),
    child: pw.Text(text, style: pw.TextStyle(fontSize: fontSize)),
  );
}

  static pw.TableRow _row(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(value),
        ),
      ],
    );
  }
}