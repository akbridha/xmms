import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/history.dart';
import '../models/history_detail.dart';

class HistoryService {
  static String get _dataUrl =>
      '${AppConfig.host}${AppConfig.historyDataPath}';
  static String _detailUrl(String id) =>
      '${AppConfig.host}${AppConfig.historyDetailPath}?id=$id';

  static const int _maxRetries = 3;
  static const Duration _timeout = Duration(seconds: 30);

  static Future<List<History>> fetchHistories() async {
    final url = _dataUrl;

    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        debugPrint(
          '[HistoryService] Attempt $attempt/$_maxRetries - Fetching: $url',
        );

        final response = await http.get(Uri.parse(url)).timeout(_timeout);

        if (response.statusCode == 200) {
          debugPrint('[HistoryService] Success! Status: ${response.statusCode}');
          final decoded = json.decode(response.body);
          final List<dynamic> jsonList;
          if (decoded is List) {
            jsonList = decoded;
          } else if (decoded is Map<String, dynamic>) {
            // Unwrap common envelope keys: data, records, result, items
            final listValue = decoded['data'] ??
                decoded['records'] ??
                decoded['result'] ??
                decoded['items'];
            if (listValue is List) {
              jsonList = listValue;
            } else {
              // Single object — wrap it
              jsonList = [decoded];
            }
          } else {
            jsonList = [];
          }
          return jsonList
              .map((item) => History.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          );
        }
      } on TimeoutException {
        debugPrint('[HistoryService] Timeout on attempt $attempt');
        if (attempt == _maxRetries) {
          throw Exception(
            'Timeout setelah $attempt percobaan. Server tidak merespons dalam 30 detik.',
          );
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      } on SocketException catch (e) {
        debugPrint('[HistoryService] SocketException on attempt $attempt: $e');
        if (attempt == _maxRetries) {
          throw Exception(
            'Gagal terhubung ke server.\n'
            'Kemungkinan penyebab:\n'
            '• DNS resolution gagal\n'
            '• Device belum terhubung ke network yang tepat\n'
            '• Corporate proxy belum dikonfigurasi\n'
            'Error: ${e.message}',
          );
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      } on HttpException catch (e) {
        debugPrint('[HistoryService] HttpException on attempt $attempt: $e');
        if (attempt == _maxRetries) {
          throw Exception('HTTP Error: ${e.message}');
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      } catch (e) {
        debugPrint('[HistoryService] Unknown error on attempt $attempt: $e');
        if (attempt == _maxRetries) {
          throw Exception('Error: $e');
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      }
    }

    throw Exception('Gagal memuat data setelah $_maxRetries percobaan');
  }

  static Future<HistoryApiResponse> fetchHistoryDetail(String id) async {
    final url = _detailUrl(id);

    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        debugPrint(
          '[HistoryService] Attempt $attempt/$_maxRetries - Fetching detail: $url',
        );

        final response = await http.get(Uri.parse(url)).timeout(_timeout);

        if (response.statusCode == 200) {
          debugPrint(
            '[HistoryService] Detail success! Status: ${response.statusCode}',
          );
          final decoded = json.decode(response.body) as Map<String, dynamic>;
          if (decoded['success'] == true && decoded['data'] != null) {
            return HistoryApiResponse.fromJson(
              decoded['data'] as Map<String, dynamic>,
            );
          }
          throw Exception(
            decoded['message']?.toString() ?? 'API returned success=false',
          );
        } else {
          throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          );
        }
      } on TimeoutException {
        debugPrint('[HistoryService] Detail timeout on attempt $attempt');
        if (attempt == _maxRetries) {
          throw Exception(
            'Timeout setelah $attempt percobaan. Server tidak merespons dalam 30 detik.',
          );
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      } on SocketException catch (e) {
        debugPrint('[HistoryService] SocketException on attempt $attempt: $e');
        if (attempt == _maxRetries) {
          throw Exception(
            'Gagal terhubung ke server.\nError: ${e.message}',
          );
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      } on HttpException catch (e) {
        debugPrint('[HistoryService] HttpException on attempt $attempt: $e');
        if (attempt == _maxRetries) {
          throw Exception('HTTP Error: ${e.message}');
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      } catch (e) {
        debugPrint('[HistoryService] Unknown error on attempt $attempt: $e');
        if (attempt == _maxRetries) {
          throw Exception('Error: $e');
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      }
    }

    throw Exception('Gagal memuat detail setelah $_maxRetries percobaan');
  }
}
