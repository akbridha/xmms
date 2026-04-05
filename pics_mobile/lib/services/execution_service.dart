import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../models/execution.dart';

class ExecutionService {
  static String get _url => '${AppConfig.host}/execution/data';
  static const int _maxRetries = 3;
  static const Duration _timeout = Duration(seconds: 30);

  static Future<List<Execution>> fetchExecutions({
    required String section,
    required String date,
    int page = 1,
    String search = '',
  }) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final uri = Uri.parse(_url).replace(
          queryParameters: {
            'section': section,
            'date': date,
            'page': page.toString(),
            if (search.isNotEmpty) 'search': search,
          },
        );

        debugPrint(
          '[ExecutionService] Attempt $attempt/$_maxRetries - GET: $uri',
        );

        final response = await http.get(uri).timeout(_timeout);

        if (response.statusCode == 200) {
          debugPrint(
            '[ExecutionService] Success! Status: ${response.statusCode}',
          );
          final List<dynamic> jsonList = json.decode(response.body);
          return jsonList
              .map((j) => Execution.fromJson(j as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          );
        }
      } on TimeoutException {
        debugPrint('[ExecutionService] Timeout on attempt $attempt');
        if (attempt == _maxRetries) {
          throw Exception(
            'Timeout setelah $attempt percobaan. Server tidak merespons dalam 30 detik.',
          );
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      } on SocketException catch (e) {
        debugPrint(
          '[ExecutionService] SocketException on attempt $attempt: $e',
        );
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
        debugPrint(
          '[ExecutionService] HttpException on attempt $attempt: $e',
        );
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
        debugPrint(
          '[ExecutionService] Unknown error on attempt $attempt: $e',
        );
        if (attempt == _maxRetries) {
          throw Exception('Error: $e');
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      }
    }

    throw Exception('Gagal memuat data setelah $_maxRetries percobaan');
  }
}
