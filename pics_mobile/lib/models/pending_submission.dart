import 'dart:convert';
import 'form_item.dart';
import '../database/db_helper.dart';

class PendingSubmission {
  final int? id;
  final String idSchedule;
  final String partOfCheck;
  final String inspector;
  final List<FormItem> items;
  final DateTime createdAt;
  final String syncStatus;
  final int syncAttempts;
  final String? lastError;

  PendingSubmission({
    this.id,
    required this.idSchedule,
    required this.partOfCheck,
    required this.inspector,
    required this.items,
    required this.createdAt,
    this.syncStatus = DBHelper.statusPending,
    this.syncAttempts = 0,
    this.lastError,
  });

  /// Convert to Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      if (id != null) DBHelper.colId: id,
      DBHelper.colIdSchedule: idSchedule,
      DBHelper.colPartOfCheck: partOfCheck,
      DBHelper.colInspector: inspector,
      DBHelper.colItemsJson: _itemsToJson(),
      DBHelper.colCreatedAt: createdAt.toIso8601String(),
      DBHelper.colSyncStatus: syncStatus,
      DBHelper.colSyncAttempts: syncAttempts,
      DBHelper.colLastError: lastError,
    };
  }

  /// Convert from database Map
  factory PendingSubmission.fromMap(Map<String, dynamic> map) {
    return PendingSubmission(
      id: map[DBHelper.colId] as int?,
      idSchedule: map[DBHelper.colIdSchedule] as String,
      partOfCheck: map[DBHelper.colPartOfCheck] as String,
      inspector: map[DBHelper.colInspector] as String,
      items: _itemsFromJson(map[DBHelper.colItemsJson] as String),
      createdAt: DateTime.parse(map[DBHelper.colCreatedAt] as String),
      syncStatus: map[DBHelper.colSyncStatus] as String,
      syncAttempts: map[DBHelper.colSyncAttempts] as int,
      lastError: map[DBHelper.colLastError] as String?,
    );
  }

  /// Convert items list to JSON string for storage
  String _itemsToJson() {
    return json.encode(items.map((item) => item.toSubmitJson()).toList());
  }

  /// Convert JSON string back to items list
  static List<FormItem> _itemsFromJson(String jsonStr) {
    final List<dynamic> jsonList = json.decode(jsonStr) as List<dynamic>;
    // Note: We're only storing id and input_value for submission
    // So we create minimal FormItem objects just for submission purposes
    return jsonList.map((item) {
      final map = item as Map<String, dynamic>;
      return FormItem(
        id: map['id'] as int,
        section: '',
        partOfCheck: '',
        item: '',
        detailsItems: '',
        activity: '',
        value: '',
        order: 0,
        valid: 1,
        inputValue: map['input_value'] as String?,
      );
    }).toList();
  }

  /// Create a copy with updated fields
  PendingSubmission copyWith({
    int? id,
    String? idSchedule,
    String? partOfCheck,
    String? inspector,
    List<FormItem>? items,
    DateTime? createdAt,
    String? syncStatus,
    int? syncAttempts,
    String? lastError,
  }) {
    return PendingSubmission(
      id: id ?? this.id,
      idSchedule: idSchedule ?? this.idSchedule,
      partOfCheck: partOfCheck ?? this.partOfCheck,
      inspector: inspector ?? this.inspector,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
      syncAttempts: syncAttempts ?? this.syncAttempts,
      lastError: lastError ?? this.lastError,
    );
  }

  bool get isPending => syncStatus == DBHelper.statusPending;
  bool get isSynced => syncStatus == DBHelper.statusSynced;
  bool get hasError => syncStatus == DBHelper.statusError;
}
