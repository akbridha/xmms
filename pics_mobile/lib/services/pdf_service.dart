import 'package:pdf/pdf.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;

class PdfService {
  static Future<List<int>> generatePdfFromList(List<Map<String, dynamic>> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        maxPages: 1000,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(10),
        build: (context) {
          final List<pw.Widget> widgets = [];

          for (var i = 0; i < data.length; i++) {
            final item = data[i];

            widgets.add(pw.Text(
              'PI HISTORY REPORT',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ));
            widgets.add(pw.SizedBox(height: 8));
            widgets.add(_infoTable(item));
            widgets.add(pw.SizedBox(height: 12));
            widgets.addAll(_buildDetailDataAsList(item['data'], item['poc']));

            if (i < data.length - 1) {
              widgets.add(pw.Divider(thickness: 1, height: 15));
            }
          }
          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _infoTable(Map<String, dynamic> item) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey500, width: 0.5),
        borderRadius: pw.BorderRadius.circular(2),
      ),
      padding: const pw.EdgeInsets.all(4),
      child: pw.Table(
        columnWidths: {
          0: const pw.FlexColumnWidth(1.2),
          1: const pw.FlexColumnWidth(3),
        },
        children: [
          _row('Code Unit', item['code_unit'] ?? '-'),
          _row('Section', item['section'] ?? '-'),
          _row('POC', item['poc'] ?? '-'),
          _row('Start Time', item['start_time'] ?? '-'),
          _row('End Time', item['end_time'] ?? '-'),
          _row('Status', item['status'] ?? '-'),
          _row('Validator', '${item['validator_name'] ?? '-'} (${item['validation_by'] ?? '-'})'),
        ],
      ),
    );
  }

  static List<pw.Widget> _buildDetailDataAsList(dynamic dataMap, String pocName) {
    final List<pw.Widget> widgets = [];
    if (dataMap == null) return widgets;

    dataMap.forEach((pocKey, pocValue) {
      widgets.add(pw.Text(
        'POC: $pocKey',
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      ));
      widgets.add(pw.SizedBox(height: 4));

      if (pocValue is! List) return;
      for (var group in pocValue) {
        if (group is! List || group.length < 2) continue;
        final headerLabel = group[0] as String? ?? 'Tanpa Label';
        final detailItems = group[1] as List? ?? [];

        widgets.add(pw.Text(
          '  $headerLabel',
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ));
        widgets.add(pw.SizedBox(height: 2));

        if (detailItems.isEmpty) {
          widgets.add(pw.Text('(Tidak ada item)', style: pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic)));
          widgets.add(pw.SizedBox(height: 4));
          continue;
        }

        widgets.add(_detailTable(detailItems));
        widgets.add(pw.SizedBox(height: 8));
      }
    });
    return widgets;
  }

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

      // No, Detail, Activity
      rowChildren.add(_cell('${i + 1}', fontSize: 6));
      rowChildren.add(_cell(_getDetailItemName(detailItems[i]), fontSize: 6));
      rowChildren.add(_cell(_getDetailActivity(detailItems[i]), fontSize: 6));

      // Kolom Result pertama dengan icon berwarna + duration
      final resultText = _getDetailResult(detailItems[i]);
      final durationText = _getDetailDuration(detailItems[i]);
      rowChildren.add(_getResultWithDuration(resultText, durationText));

      // Kolom Result ke-2 sampai ke-10 (kosong)
      for (int j = 2; j <= 10; j++) {
        rowChildren.add(_cell('', fontSize: 6));
      }

      rows.add(pw.TableRow(children: rowChildren));
    }

    // Lebar kolom
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

static pw.Widget _getResultWithDuration(String resultValue, String duration) {
  final lowerValue = resultValue.toLowerCase().trim();
  
  // Tentukan widget untuk result
  pw.Widget resultWidget;
  switch (lowerValue) {
    case 'o':
      resultWidget = pw.Icon(
        pw.IconData(0xe5ca),
        size: 8,
        color: PdfColors.yellow,
      );
      break;
    case 'x':
      resultWidget = pw.Text('✗', style: pw.TextStyle(color: PdfColors.red, fontSize: 8));
      break;
    case 'v':
      resultWidget = pw.Text('✓', style: pw.TextStyle(color: PdfColors.green, fontSize: 8));
      break;
    default:
      resultWidget = pw.Text(resultValue, style: const pw.TextStyle(fontSize: 6));
  }
  
  // Gabungkan dalam Column vertikal
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      resultWidget,
      pw.SizedBox(height: 2), // jarak antara result dan duration
      pw.Text(duration, style: const pw.TextStyle(fontSize: 6)),
    ],
  );
}

  static pw.Widget _getResultWidget(String result, String duration) {
    final lowerResult = result.toLowerCase();
    pw.PdfColor? bgColor;
    if (lowerResult == 'o') {
      bgColor = PdfColors.yellow;
    } else if (lowerResult == 'x') {
      bgColor = PdfColors.red;
    } else if (lowerResult == 'v') {
      bgColor = PdfColors.green;
    }

    if (bgColor != null) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 8,
            height: 8,
            decoration: pw.BoxDecoration(
              color: bgColor,
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: PdfColors.black, width: 0.2),
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(duration, style: const pw.TextStyle(fontSize: 6)),
        ],
      );
    } else {
      // Tampilkan teks result dan duration
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(result, style: const pw.TextStyle(fontSize: 6)),
          pw.Text(duration, style: const pw.TextStyle(fontSize: 6)),
        ],
      );
    }
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

  static String _getDetailResult(List<dynamic> detail) {
    if (detail.length < 3) return '-';
    return detail[2]?.toString() ?? '-';
  }

  static String _getDetailDuration(List<dynamic> detail) {
    if (detail.length < 4) return '-';
    return detail[3]?.toString() ?? '-';
  }

  // Styling dengan ukuran kecil
  static pw.Widget _headerCell(String text, {double fontSize = 7}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(2),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: fontSize),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _cell(String text, {double fontSize = 6}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(1),
      child: pw.Text(text, style: pw.TextStyle(fontSize: fontSize)),
    );
  }

  static pw.TableRow _row(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(2),
          child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(2),
          child: pw.Text(value, style: pw.TextStyle(fontSize: 8)),
        ),
      ],
    );
  }
}