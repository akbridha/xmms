import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;


class PdfService {

    static Future<List<int>> generatePdfFromList(List<int> data) async{
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(

        pageFormat: PdfPageFormat.a4,
        build: (context){

          return pw.Column(
            crossAxisAlignment:pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Data History'),
              pw.SizedBox(height: 10),
              // pw.ListView.builder(
              //   itemCount: data.length,
              //   itemBuilder: (context, index) {
              //     return pw.Text('Item ${data[index]}');
              //   },
              // ),
              pw.Text('Data:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              

              pw.Table.fromTextArray(
                headers: ['Index', 'Value'],
                data: List.generate(data.length, (index) {
                  return [
                    index.toString(),
                    data[index].toString(),
                  ];
                }),
              ),
              pw.SizedBox(height: 20),


              pw.Text(
                'Total: ${data.reduce((a, b) => a + b)}',
                style: pw.TextStyle(fontSize: 14),
              ),


            ],
          );
        }
      )
    );
    return pdf.save();
  }
}