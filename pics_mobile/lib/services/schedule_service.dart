import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/schedule.dart';

class ScheduleService {
  static const String _url =
      'https://app-saptaindra.msappproxy.net/PlantAdmo/api/schedule/data';
  static const int _maxRetries = 3;
  static const Duration _timeout = Duration(seconds: 30);

  static Future<List<Schedule>> fetchSchedules({String? customUrl}) async {
    final url = customUrl ?? _url;
    
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        debugPrint('[ScheduleService] Attempt $attempt/$_maxRetries - Fetching: $url');
        
        final uri = Uri.parse(url);
        final response = await http.get(uri).timeout(_timeout);

        if (response.statusCode == 200) {
          debugPrint('[ScheduleService] Success! Status: ${response.statusCode}');
          final List<dynamic> jsonList = json.decode(response.body);
          return jsonList.map((json) => Schedule.fromJson(json)).toList();
        } else {
          throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          );
        }
      } on TimeoutException {
        debugPrint('[ScheduleService] Timeout on attempt $attempt');
        if (attempt == _maxRetries) {
          throw Exception(
            'Timeout setelah $attempt percobaan. Server tidak merespons dalam 30 detik.',
          );
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      } on SocketException catch (e) {
        debugPrint('[ScheduleService] SocketException on attempt $attempt: $e');
        if (attempt == _maxRetries) {
          throw Exception(
            'Gagal terhubung ke server. '
            'Kemungkinan penyebab:\n'
            '• DNS resolution gagal\n'
            '• Device belum terhubung ke network yang tepat\n'
            '• Corporate proxy belum dikonfigurasi\n'
            'Error: ${e.message}',
          );
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      } on HttpException catch (e) {
        debugPrint('[ScheduleService] HttpException on attempt $attempt: $e');
        if (attempt == _maxRetries) {
          throw Exception(
            'HTTP Error: ${e.message}\n\n'
            'Tips:\n'
            '• Pastikan URL benar\n'
            '• Periksa koneksi internet device\n'
            '• Jika di corporate network, setup proxy di device settings',
          );
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      } catch (e) {
        debugPrint('[ScheduleService] Unknown error on attempt $attempt: $e');
        if (attempt == _maxRetries) {
          throw Exception('Error: $e');
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      }
    }

    throw Exception('Gagal memuat data setelah $_maxRetries percobaan');
  }
}
