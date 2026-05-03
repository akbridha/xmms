 import 'dart:io';
 import 'package:http/http.dart' as http;
 import '../config/app_config.dart';
 import 'package:path_provider/path_provider.dart';
 
  class FileService {

  static String _downloadUrl(String id) =>
  '${AppConfig.host}${AppConfig.historyDownloadPath}?id=$id';

    

  static Future<void> savePdf(List<int> bytes) async {
    final now = DateTime.now();

    final jam = now.hour.toString().padLeft(2, '0');
    final menit = now.minute.toString().padLeft(2, '0');

    final fileName = 'PI_HISTORY_${jam}.${menit}.pdf';

    // final dir = await getExternalStorageDirectory();
    final dir = Directory('/storage/emulated/0/Download');
    final file = File('${dir!.path}/$fileName');

    await file.writeAsBytes(bytes);

    print('Saved to: ${file.path}');
  }



  static Future<void> downloadFile(String id) async {
    // Implementasi fungsi download file jika diperlukan
  
    final url =  Uri.parse(_downloadUrl(id));
  
    final response = await http.get(url);

    if(response.statusCode == 200){
      final bytes = response.bodyBytes;
      // Simpan file ke storage atau lakukan tindakan lain dengan bytes
      final dir =  Directory('/storage/emulated/0/Download');

      final now = DateTime.now();

      // ambil jam & menit, lalu format jadi 2 digit (biar rapi)
      final jam = now.hour.toString().padLeft(2, '0');
      final menit = now.minute.toString().padLeft(2, '0');
      // buat nama file
      final fileName = 'PI_HISTORY_${jam}.${menit}.csv';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      print('File downloaded :${file.path} ');

      
    } else {
      throw Exception('Failed to download file: ${response.statusCode}');
    }
  }

}