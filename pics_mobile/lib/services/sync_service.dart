import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../database/db_helper.dart';
import '../models/pending_submission.dart';
import 'local_storage_service.dart';

class SyncService {
  static String get _formSaveUrl => '${AppConfig.host}/execution/form/save';
  static const Duration _timeout = Duration(seconds: 30);

  /// Sync a single pending submission to the server
  static Future<bool> syncSubmission(PendingSubmission submission) async {
    if (submission.id == null) {
      debugPrint('[SyncService] Cannot sync submission without ID');
      return false;
    }

    try {
      debugPrint(
        '[SyncService] Syncing submission ${submission.id}: '
        'schedule=${submission.idSchedule}, poc=${submission.partOfCheck}',
      );

      final uri = Uri.parse(_formSaveUrl);
      final body = json.encode({
        'id_schedule': submission.idSchedule,
        'part_of_check': submission.partOfCheck,
        'inspector': submission.inspector,
        'items': submission.items.map((e) => e.toSubmitJson()).toList(),
      });

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        debugPrint('[SyncService] Sync successful for ${submission.id}');

        // Delete from local database after successful sync
        await LocalStorageService.deleteSubmission(submission.id!);

        return true;
      } else {
        final errorMsg = 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
        debugPrint('[SyncService] Sync failed for ${submission.id}: $errorMsg');

        // Update status to error
        await LocalStorageService.updateSubmissionStatus(
          id: submission.id!,
          status: DBHelper.statusError,
          incrementAttempts: 1,
          error: errorMsg,
        );

        return false;
      }
    } on TimeoutException catch (e) {
      final errorMsg = 'Timeout: ${e.message}';
      debugPrint('[SyncService] Sync timeout for ${submission.id}: $errorMsg');

      await LocalStorageService.updateSubmissionStatus(
        id: submission.id!,
        status: DBHelper.statusError,
        incrementAttempts: 1,
        error: errorMsg,
      );

      return false;
    } on SocketException catch (e) {
      final errorMsg = 'Network error: ${e.message}';
      debugPrint('[SyncService] Network error for ${submission.id}: $errorMsg');

      await LocalStorageService.updateSubmissionStatus(
        id: submission.id!,
        status: DBHelper.statusError,
        incrementAttempts: 1,
        error: errorMsg,
      );

      return false;
    } catch (e) {
      final errorMsg = e.toString();
      debugPrint('[SyncService] Unexpected error for ${submission.id}: $errorMsg');

      await LocalStorageService.updateSubmissionStatus(
        id: submission.id!,
        status: DBHelper.statusError,
        incrementAttempts: 1,
        error: errorMsg,
      );

      return false;
    }
  }

  /// Sync all pending submissions
  static Future<SyncResult> syncAllPending() async {
    debugPrint('[SyncService] Starting sync for all pending submissions');

    final pending = await LocalStorageService.getPendingSubmissions();

    if (pending.isEmpty) {
      debugPrint('[SyncService] No pending submissions to sync');
      return SyncResult(total: 0, success: 0, failed: 0);
    }

    int successCount = 0;
    int failedCount = 0;

    for (final submission in pending) {
      // Reset status to pending before retry (if it was error)
      if (submission.hasError) {
        await LocalStorageService.updateSubmissionStatus(
          id: submission.id!,
          status: DBHelper.statusPending,
        );
      }

      final success = await syncSubmission(submission);
      if (success) {
        successCount++;
      } else {
        failedCount++;
      }

      // Small delay between syncs to avoid overwhelming the server
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    debugPrint(
      '[SyncService] Sync completed: $successCount success, $failedCount failed out of ${pending.length}',
    );

    return SyncResult(
      total: pending.length,
      success: successCount,
      failed: failedCount,
    );
  }

  /// Sync pending submissions for a specific schedule
  static Future<SyncResult> syncBySchedule(String idSchedule) async {
    debugPrint('[SyncService] Starting sync for schedule: $idSchedule');

    final pending =
        await LocalStorageService.getPendingSubmissionsBySchedule(idSchedule);

    if (pending.isEmpty) {
      debugPrint('[SyncService] No pending submissions for schedule $idSchedule');
      return SyncResult(total: 0, success: 0, failed: 0);
    }

    int successCount = 0;
    int failedCount = 0;

    for (final submission in pending) {
      // Reset status to pending before retry (if it was error)
      if (submission.hasError) {
        await LocalStorageService.updateSubmissionStatus(
          id: submission.id!,
          status: DBHelper.statusPending,
        );
      }

      final success = await syncSubmission(submission);
      if (success) {
        successCount++;
      } else {
        failedCount++;
      }

      // Small delay between syncs
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    debugPrint(
      '[SyncService] Sync for schedule $idSchedule completed: '
      '$successCount success, $failedCount failed out of ${pending.length}',
    );

    return SyncResult(
      total: pending.length,
      success: successCount,
      failed: failedCount,
    );
  }

  /// Attempt immediate sync after saving to local storage
  /// Returns true if sync was successful, false otherwise
  /// (Does not throw exceptions - failures are handled gracefully)
  static Future<bool> attemptImmediateSync(PendingSubmission submission) async {
    debugPrint('[SyncService] Attempting immediate sync for new submission');

    try {
      return await syncSubmission(submission);
    } catch (e) {
      debugPrint('[SyncService] Immediate sync failed: $e');
      return false;
    }
  }
}

class SyncResult {
  final int total;
  final int success;
  final int failed;

  SyncResult({
    required this.total,
    required this.success,
    required this.failed,
  });

  bool get hasFailures => failed > 0;
  bool get allSuccess => total > 0 && failed == 0;
  bool get isEmpty => total == 0;

  String get message {
    if (isEmpty) return 'Tidak ada data untuk disinkronkan';
    if (allSuccess) return 'Semua data berhasil disinkronkan ($success/$total)';
    if (success == 0) {
      return 'Gagal menyinkronkan semua data ($failed/$total)';
    }
    return 'Sebagian data berhasil disinkronkan ($success/$total berhasil, $failed gagal)';
  }
}
