import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../models/execution.dart';
import '../models/form_item.dart';
import '../models/pending_submission.dart';
import 'local_storage_service.dart';
import 'sync_service.dart';

class ExecutionService {
  static String get _url => '${AppConfig.host}/execution/data';
  static String get _formUrl => '${AppConfig.host}/execution/form';
  static String get _formSaveUrl => '${AppConfig.host}/execution/form/save';
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
            'end_date': date,
            'page': page.toString(),
            if (search.isNotEmpty) 'search_string': search,
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

  static Future<FormClaimResponse> fetchFormItems({
    required String section,
    required String partOfCheck,
    required String idSchedule,
  }) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final uri = Uri.parse(_formUrl).replace(
          queryParameters: {
            'section': section,
            'part_of_check': partOfCheck,
            'id_schedule': idSchedule,
          },
        );

        debugPrint(
          '[ExecutionService] Attempt $attempt/$_maxRetries - GET form: $uri',
        );

        final response = await http.get(uri).timeout(_timeout);

        if (response.statusCode == 200) {
          debugPrint('[ExecutionService] Form fetch success!');
          final Map<String, dynamic> jsonMap =
              json.decode(response.body) as Map<String, dynamic>;
          return FormClaimResponse.fromJson(jsonMap);
        } else {
          throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          );
        }
      } on TimeoutException {
        debugPrint('[ExecutionService] Form timeout on attempt $attempt');
        if (attempt == _maxRetries) {
          throw Exception(
            'Timeout setelah $attempt percobaan. Server tidak merespons.',
          );
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      } on SocketException catch (e) {
        debugPrint('[ExecutionService] Form SocketException: $e');
        if (attempt == _maxRetries) {
          throw Exception('Gagal terhubung ke server.\nError: ${e.message}');
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      } catch (e) {
        debugPrint('[ExecutionService] Form error on attempt $attempt: $e');
        if (attempt == _maxRetries) {
          throw Exception('Error: $e');
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      }
    }
    throw Exception('Gagal memuat form setelah $_maxRetries percobaan');
  }

  static Future<String> saveForm({
    required String idSchedule,
    required String partOfCheck,
    required List<FormItem> items,
    required String inspector,
  }) async {
    // OFFLINE-FIRST APPROACH:
    // 1. Save to local database first
    // 2. Attempt immediate sync
    // 3. If sync fails, data remains in local DB for later retry
    // 4. Return success to UI regardless (data is safe locally)

    try {
      // Step 1: Save to local database
      debugPrint('[ExecutionService] Saving form to local database first');
      final submissionId = await LocalStorageService.insertPendingSubmission(
        idSchedule: idSchedule,
        partOfCheck: partOfCheck,
        inspector: inspector,
        items: items,
      );

      debugPrint('[ExecutionService] Saved to local DB with ID: $submissionId');

      // Step 2: Get the submission we just created
      final submission =
          await LocalStorageService.getSubmissionById(submissionId);

      if (submission == null) {
        throw Exception('Gagal membaca data yang baru disimpan');
      }

      // Step 3: Attempt immediate sync to server
      debugPrint('[ExecutionService] Attempting immediate sync to server');
      final syncSuccess = await SyncService.attemptImmediateSync(submission);

      if (syncSuccess) {
        debugPrint('[ExecutionService] Immediate sync successful!');
        return 'Data berhasil disimpan dan disinkronkan ke server';
      } else {
        debugPrint(
          '[ExecutionService] Immediate sync failed, data saved locally for later sync',
        );
        return 'Data berhasil disimpan. Sinkronisasi ke server akan dilakukan nanti.';
      }
    } catch (e) {
      debugPrint('[ExecutionService] Error in saveForm: $e');
      // If even local save fails, throw the error
      throw Exception('Gagal menyimpan data: $e');
    }
  }
}
