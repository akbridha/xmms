import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database/db_helper.dart';
import '../models/pending_submission.dart';
import '../models/form_item.dart';

class LocalStorageService {
  /// Insert a new pending submission
  static Future<int> insertPendingSubmission({
    required String idSchedule,
    required String partOfCheck,
    required String inspector,
    required List<FormItem> items,
  }) async {
    try {
      final db = await DBHelper.database;
      final submission = PendingSubmission(
        idSchedule: idSchedule,
        partOfCheck: partOfCheck,
        inspector: inspector,
        items: items,
        createdAt: DateTime.now(),
        syncStatus: DBHelper.statusPending,
      );

      final id = await db.insert(
        DBHelper.tablePendingSubmissions,
        submission.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      debugPrint(
        '[LocalStorageService] Inserted pending submission: '
        'id=$id, schedule=$idSchedule, poc=$partOfCheck',
      );

      return id;
    } catch (e) {
      debugPrint('[LocalStorageService] Error inserting submission: $e');
      rethrow;
    }
  }

  /// Get all pending submissions (not synced yet)
  static Future<List<PendingSubmission>> getPendingSubmissions() async {
    try {
      final db = await DBHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DBHelper.tablePendingSubmissions,
        where: '${DBHelper.colSyncStatus} = ?',
        whereArgs: [DBHelper.statusPending],
        orderBy: '${DBHelper.colCreatedAt} ASC',
      );

      return maps.map((map) => PendingSubmission.fromMap(map)).toList();
    } catch (e) {
      debugPrint('[LocalStorageService] Error getting pending submissions: $e');
      return [];
    }
  }

  /// Get pending submissions for a specific schedule
  static Future<List<PendingSubmission>> getPendingSubmissionsBySchedule(
    String idSchedule,
  ) async {
    try {
      final db = await DBHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DBHelper.tablePendingSubmissions,
        where: '${DBHelper.colIdSchedule} = ? AND ${DBHelper.colSyncStatus} = ?',
        whereArgs: [idSchedule, DBHelper.statusPending],
        orderBy: '${DBHelper.colCreatedAt} ASC',
      );

      return maps.map((map) => PendingSubmission.fromMap(map)).toList();
    } catch (e) {
      debugPrint(
        '[LocalStorageService] Error getting pending submissions for schedule $idSchedule: $e',
      );
      return [];
    }
  }

  /// Get count of unsynced submissions for a specific schedule
  static Future<int> getUnsyncedCountBySchedule(String idSchedule) async {
    try {
      final db = await DBHelper.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${DBHelper.tablePendingSubmissions} '
        'WHERE ${DBHelper.colIdSchedule} = ? AND ${DBHelper.colSyncStatus} = ?',
        [idSchedule, DBHelper.statusPending],
      );

      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      debugPrint(
        '[LocalStorageService] Error counting unsynced for schedule $idSchedule: $e',
      );
      return 0;
    }
  }

  /// Update submission status after sync attempt
  static Future<void> updateSubmissionStatus({
    required int id,
    required String status,
    int? incrementAttempts,
    String? error,
  }) async {
    try {
      final db = await DBHelper.database;

      // Get current submission to increment attempts
      final current = await db.query(
        DBHelper.tablePendingSubmissions,
        where: '${DBHelper.colId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (current.isEmpty) {
        debugPrint('[LocalStorageService] Submission $id not found');
        return;
      }

      final currentAttempts = current.first[DBHelper.colSyncAttempts] as int;
      final newAttempts = incrementAttempts != null
          ? currentAttempts + incrementAttempts
          : currentAttempts;

      await db.update(
        DBHelper.tablePendingSubmissions,
        {
          DBHelper.colSyncStatus: status,
          DBHelper.colSyncAttempts: newAttempts,
          if (error != null) DBHelper.colLastError: error,
        },
        where: '${DBHelper.colId} = ?',
        whereArgs: [id],
      );

      debugPrint(
        '[LocalStorageService] Updated submission $id: '
        'status=$status, attempts=$newAttempts',
      );
    } catch (e) {
      debugPrint('[LocalStorageService] Error updating submission $id: $e');
      rethrow;
    }
  }

  /// Delete a submission (typically after successful sync)
  static Future<void> deleteSubmission(int id) async {
    try {
      final db = await DBHelper.database;
      await db.delete(
        DBHelper.tablePendingSubmissions,
        where: '${DBHelper.colId} = ?',
        whereArgs: [id],
      );

      debugPrint('[LocalStorageService] Deleted submission $id');
    } catch (e) {
      debugPrint('[LocalStorageService] Error deleting submission $id: $e');
      rethrow;
    }
  }

  /// Get a specific pending submission by ID
  static Future<PendingSubmission?> getSubmissionById(int id) async {
    try {
      final db = await DBHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DBHelper.tablePendingSubmissions,
        where: '${DBHelper.colId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return PendingSubmission.fromMap(maps.first);
    } catch (e) {
      debugPrint('[LocalStorageService] Error getting submission $id: $e');
      return null;
    }
  }

  /// Clear all synced submissions (cleanup)
  static Future<int> clearSyncedSubmissions() async {
    try {
      final db = await DBHelper.database;
      final count = await db.delete(
        DBHelper.tablePendingSubmissions,
        where: '${DBHelper.colSyncStatus} = ?',
        whereArgs: [DBHelper.statusSynced],
      );

      debugPrint('[LocalStorageService] Cleared $count synced submissions');
      return count;
    } catch (e) {
      debugPrint('[LocalStorageService] Error clearing synced submissions: $e');
      return 0;
    }
  }

  /// Get total count of all pending submissions
  static Future<int> getTotalPendingCount() async {
    try {
      final db = await DBHelper.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${DBHelper.tablePendingSubmissions} '
        'WHERE ${DBHelper.colSyncStatus} = ?',
        [DBHelper.statusPending],
      );

      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      debugPrint('[LocalStorageService] Error getting total pending count: $e');
      return 0;
    }
  }
}
