import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../models/execution.dart';
import '../models/form_item.dart';
import '../models/form_data_response.dart';
import '../models/pending_submission.dart';
import 'local_storage_service.dart';
import 'sync_service.dart';

class ExecutionService {
  static String get _url => '${AppConfig.host}/execution/data'; /*dipakai ketika bukan execution index*/
  static String get _formUrl => '${AppConfig.host}/execution/form'; /*dipakai ketika ingin mengambil form untuk diisi sekaligus claim.*/
  static String get _formDataUrl => '${AppConfig.host}/execution/form/data'; /*endpoint baru untuk mengambil form dengan history*/
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

  static Future<Execution> fetchExecutionByScheduleId(String scheduleId) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final uri = Uri.parse(_url).replace(
          queryParameters: {
            'schedule_id': scheduleId,
          },
        );

        debugPrint(
          '[ExecutionService] Attempt $attempt/$_maxRetries - GET detail: $uri',
        );

        final response = await http.get(uri).timeout(_timeout);

        if (response.statusCode == 200) {
          final List<dynamic> jsonList = json.decode(response.body);
          final executions = jsonList
              .map((j) => Execution.fromJson(j as Map<String, dynamic>))
              .toList();

          if (executions.isEmpty) {
            throw Exception('Data eksekusi tidak ditemukan untuk schedule $scheduleId');
          }

          return executions.first;
        } else {
          throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          );
        }
      } on TimeoutException {
        debugPrint('[ExecutionService] Detail timeout on attempt $attempt');
        if (attempt == _maxRetries) {
          throw Exception(
            'Timeout setelah $attempt percobaan. Server tidak merespons dalam 30 detik.',
          );
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      } on SocketException catch (e) {
        debugPrint('[ExecutionService] Detail SocketException on attempt $attempt: $e');
        if (attempt == _maxRetries) {
          throw Exception('Gagal terhubung ke server. Error: ${e.message}');
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      } catch (e) {
        debugPrint('[ExecutionService] Detail error on attempt $attempt: $e');
        if (attempt == _maxRetries) {
          throw Exception('Error: $e');
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      }
    }

    throw Exception('Gagal memuat detail eksekusi setelah $_maxRetries percobaan');
  }


  static Future<FormDataResponse> fetchFormData({
    required String scheduleId,
    required String poc,
  }) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final uri = Uri.parse(_formDataUrl).replace(
          queryParameters: {
            'schedule_id': scheduleId,
            'poc': poc,
          },
        );

        debugPrint(
          '[ExecutionService] Attempt $attempt/$_maxRetries - GET form data: $uri',
        );

        final response = await http.get(uri).timeout(_timeout);

        if (response.statusCode == 200) {
          debugPrint('[ExecutionService] Form data fetch success!');
          final Map<String, dynamic> jsonMap =
              json.decode(response.body) as Map<String, dynamic>;
          return FormDataResponse.fromJson(jsonMap);
        } else {
          throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          );
        }
      } on TimeoutException {
        debugPrint('[ExecutionService] Form data timeout on attempt $attempt');
        if (attempt == _maxRetries) {
          throw Exception(
            'Timeout setelah $attempt percobaan. Server tidak merespons.',
          );
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      } on SocketException catch (e) {
        debugPrint('[ExecutionService] Form data SocketException: $e');
        if (attempt == _maxRetries) {
          throw Exception('Gagal terhubung ke server.\nError: ${e.message}');
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      } catch (e) {
        debugPrint('[ExecutionService] Form data error on attempt $attempt: $e');
        if (attempt == _maxRetries) {
          throw Exception('Error: $e');
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      }
    }
    throw Exception('Gagal memuat form data setelah $_maxRetries percobaan');
  }

  static Future<FormClaimResponse> fetchFormItems({
    required String section,
    required String partOfCheck,
    required String idSchedule,
  }) async {
    // STEP 1: Fetch form data with history from new endpoint
    debugPrint('[ExecutionService] Fetching form data with history...');
    final formDataResponse = await fetchFormData(
      scheduleId: idSchedule,
      poc: partOfCheck,
    );

    debugPrint(
      '[ExecutionService] Form data fetched successfully. Total items: ${formDataResponse.data.items.length}',
    );
    
    // Check for claim status by looking at history entries
    final hasMatchingHistory = formDataResponse.data.isAlreadyClaimed;
    debugPrint(
      '[ExecutionService] Claim status: ${hasMatchingHistory ? "Already claimed (found history with date ${formDataResponse.data.scheduleDate})" : "Not claimed yet"}',
    );

    // STEP 2: Check if this schedule has already been claimed
    // by looking for history entries matching schedule_date (including null results)
    if (formDataResponse.data.isAlreadyClaimed) {
      debugPrint(
        '[ExecutionService] Schedule already claimed. Skipping claim step.',
      );
      
      // STEP 2a: Populate form items with previously claimed data (Edit Mode)
      debugPrint('[ExecutionService] Populating form with claimed data for editing...');
      formDataResponse.data.populateWithClaimedData();
      
      final populatedCount = formDataResponse.data.items
          .where((item) => item.inputValue != null && item.inputValue!.isNotEmpty)
          .length;
      debugPrint(
        '[ExecutionService] Populated $populatedCount/${formDataResponse.data.items.length} items with existing data',
      );
    } else {
      // STEP 3: Attempt to claim the form using old endpoint
      // This step can fail silently - we still return the data with history
      try {
        debugPrint('[ExecutionService] Attempting to claim form...');
        final uri = Uri.parse(_formUrl).replace(
          queryParameters: {
            'section': section,
            'part_of_check': partOfCheck,
            'id_schedule': idSchedule,
          },
        );

        final response = await http.get(uri).timeout(_timeout);

        if (response.statusCode == 200) {
          debugPrint('[ExecutionService] Form claimed successfully!');
        } else {
          debugPrint(
            '[ExecutionService] Claim failed with status ${response.statusCode}, but continuing with fetched data',
          );
        }
      } catch (e) {
        debugPrint(
          '[ExecutionService] Claim attempt failed: $e. Continuing with fetched data.',
        );
        // Continue anyway - we have the form data with history
      }
    }

    // STEP 4: Return FormClaimResponse using data from first call
    return FormClaimResponse(
      message: formDataResponse.message,
      partOfCheck: formDataResponse.data.poc,
      idSchedule: formDataResponse.data.scheduleId.toString(),
      items: formDataResponse.data.items,
    );
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
