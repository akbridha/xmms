import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../models/validation_item.dart' as models;
import '../models/validation_detail.dart';

class ValidationService {
  static String get _validationDataUrl => '${AppConfig.host}/validation/data';
  static String get _validationDetailUrl =>
      '${AppConfig.host}/validation/detail';
  static const int _maxRetries = 3;
  static const Duration _timeout = Duration(seconds: 30);

  /// Fetch validation list from /api/validation/data
  static Future<List<models.ValidationItem>> fetchValidationList({
    String? section,
    String? date,
  }) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final queryParameters = <String, String>{
          if (section != null && section.isNotEmpty && section != 'All')
            'section': section,
          if (date != null && date.isNotEmpty) 'date': date,
        };

        final uri = Uri.parse(_validationDataUrl).replace(
          queryParameters: queryParameters.isEmpty ? null : queryParameters,
        );

        debugPrint(
          '[ValidationService] Attempt $attempt/$_maxRetries - GET: $uri',
        );

        final response = await http.get(uri).timeout(_timeout);

        if (response.statusCode == 200) {
          debugPrint(
            '[ValidationService] Success! Status: ${response.statusCode}',
          );
          final List<dynamic> jsonList = json.decode(response.body);
          return jsonList
              .map(
                (j) =>
                    models.ValidationItem.fromJson(j as Map<String, dynamic>),
              )
              .toList();
        } else {
          throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          );
        }
      } on TimeoutException {
        debugPrint('[ValidationService] Timeout on attempt $attempt');
        if (attempt == _maxRetries) {
          throw Exception(
            'Timeout setelah $attempt percobaan. Server tidak merespons dalam 30 detik.',
          );
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      } on SocketException catch (e) {
        debugPrint(
          '[ValidationService] SocketException on attempt $attempt: $e',
        );
        if (attempt == _maxRetries) {
          throw Exception(
            'Gagal terhubung ke server. Periksa koneksi internet Anda.\nError: ${e.message}',
          );
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      } on HttpException catch (e) {
        debugPrint('[ValidationService] HttpException on attempt $attempt: $e');
        if (attempt == _maxRetries) {
          throw Exception('HTTP Error: ${e.message}');
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      } catch (e) {
        debugPrint('[ValidationService] Unknown error on attempt $attempt: $e');
        if (attempt == _maxRetries) {
          throw Exception('Error: $e');
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      }
    }

    throw Exception('Gagal memuat data setelah $_maxRetries percobaan');
  }

  /// Fetch validation detail from /api/validation/detail?schedule_id=X
  static Future<ValidationDetail> fetchValidationDetail(
    String scheduleId,
  ) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final uri = Uri.parse(
          _validationDetailUrl,
        ).replace(queryParameters: {'schedule_id': scheduleId});

        debugPrint(
          '[ValidationService] Attempt $attempt/$_maxRetries - GET: $uri',
        );

        final response = await http.get(uri).timeout(_timeout);

        if (response.statusCode == 200) {
          debugPrint(
            '[ValidationService] Success! Status: ${response.statusCode}',
          );
          final Map<String, dynamic> jsonData = json.decode(response.body);
          return ValidationDetail.fromJson(jsonData);
        } else {
          throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          );
        }
      } on TimeoutException {
        debugPrint('[ValidationService] Timeout on attempt $attempt');
        if (attempt == _maxRetries) {
          throw Exception(
            'Timeout setelah $attempt percobaan. Server tidak merespons dalam 30 detik.',
          );
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      } on SocketException catch (e) {
        debugPrint(
          '[ValidationService] SocketException on attempt $attempt: $e',
        );
        if (attempt == _maxRetries) {
          throw Exception(
            'Gagal terhubung ke server. Periksa koneksi internet Anda.\nError: ${e.message}',
          );
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      } on HttpException catch (e) {
        debugPrint('[ValidationService] HttpException on attempt $attempt: $e');
        if (attempt == _maxRetries) {
          throw Exception('HTTP Error: ${e.message}');
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      } catch (e) {
        debugPrint('[ValidationService] Unknown error on attempt $attempt: $e');
        if (attempt == _maxRetries) {
          throw Exception('Error: $e');
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      }
    }

    throw Exception('Gagal memuat detail setelah $_maxRetries percobaan');
  }

  /// Submit approval action
  /// Note: Using GET method as per backend requirement (unusual but as specified)
  static Future<bool> submitApprovalAction({
    required String scheduleId,
    required String nrp,
  }) async {
    try {
      final uri = Uri.parse(
        '${AppConfig.host}/validation/validate',
      ).replace(queryParameters: {'schedule_id': scheduleId, 'nrp': nrp});

      debugPrint('[ValidationService] Submitting approval - GET: $uri');

      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        debugPrint(
          '[ValidationService] Approval submitted successfully! Status: ${response.statusCode}',
        );
        return true;
      } else {
        debugPrint(
          '[ValidationService] Approval failed with status: ${response.statusCode}',
        );
        throw Exception(
          'Gagal menyimpan approval. HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } on TimeoutException {
      debugPrint('[ValidationService] Timeout during approval submission');
      throw Exception('Timeout. Server tidak merespons dalam 30 detik.');
    } on SocketException catch (e) {
      debugPrint('[ValidationService] SocketException during approval: $e');
      throw Exception(
        'Gagal terhubung ke server. Periksa koneksi internet Anda.',
      );
    } catch (e) {
      debugPrint('[ValidationService] Error during approval: $e');
      throw Exception('Error: $e');
    }
  }
}
