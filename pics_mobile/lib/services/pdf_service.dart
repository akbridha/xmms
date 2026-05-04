import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;


class PdfService {



    static Future<List<int>> generatePdfFromList(List<Map<String, dynamic>> data) async{
     final pdf = pw.Document();
     
      pw.TableRow _row(String label, String value) {
        return pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                label,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(value),
            ),
          ],
        );
      }

    pdf.addPage(
  pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    build: (context) {
      List<pw.Widget> widgets = [];
      
      // Header
      widgets.add(pw.Text(
        'PI HISTORY REPORT',
        style: pw.TextStyle(fontSize: 18),
      ));
      widgets.add(pw.SizedBox(height: 20));
      
      // Loop data
      for (var i = 0; i < data.length; i++) {
        final item = data[i];
        
        // Tambahkan tabel
        widgets.add(
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.grey300,
              border: pw.TableBorder.all(),
            ),
            child: pw.Center(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('DATA', style: pw.TextStyle(fontSize: 14)),
                  pw.SizedBox(height: 8),
                  pw.Table(
                    columnWidths: {
                      0: const pw.FlexColumnWidth(2),
                      1: const pw.FlexColumnWidth(4),
                    },
                    children: [
                      _row('Code Unit', item['code_unit'] ?? ''),
                      _row('End Time', item['actual_end_time'] ?? ''),
                      _row('POC', item['poc'] ?? ''),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
        
        // Tambahkan jarak antar tabel (kecuali setelah tabel terakhir)
        if (i < data.length - 1) {
          widgets.add(pw.SizedBox(height: 20));
        }
      }
      
      return widgets;
    },
  ),
);

    return pdf.save();
  }
}