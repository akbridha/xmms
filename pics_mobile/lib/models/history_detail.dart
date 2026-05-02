import 'dart:convert';

class HistoryApiResponse {
  final String equipmentCode;
  final String section;
  final String firstStartTime;
  final String lastEndTime;
  final List<HistoryDetailItem> historyDetail;

  const HistoryApiResponse({
    required this.equipmentCode,
    required this.section,
    required this.firstStartTime,
    required this.lastEndTime,
    required this.historyDetail,
  });

  factory HistoryApiResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['history_detail'] as List<dynamic>? ?? [];
    return HistoryApiResponse(
      equipmentCode: (json['equipment_code'] ?? '').toString(),
      section: (json['section'] ?? '').toString(),
      firstStartTime: (json['first_start_time'] ?? '').toString(),
      lastEndTime: (json['last_end_time'] ?? '').toString(),
      historyDetail: rawList
          .map((e) => HistoryDetailItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Groups history_detail items by date extracted from start_time, sorted ascending.
  Map<String, List<HistoryDetailItem>> get byDate {
    final map = <String, List<HistoryDetailItem>>{};
    for (final item in historyDetail) {
      map.putIfAbsent(item.dateKey, () => []).add(item);
    }
    final sorted = Map.fromEntries(
      map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    return sorted;
  }
}

class HistoryDetailItem {
  final int idResult;
  final String scheduleId;
  final String poc;
  final String startTime;
  final String endTime;
  final String status;
  final String? validatorName;
  final String? validationTime;
  final String? _rawNrpName;
  final Map<String, List<HistoryCategory>> data;

  const HistoryDetailItem({
    required this.idResult,
    required this.scheduleId,
    required this.poc,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.validatorName,
    this.validationTime,
    String? rawNrpName,
    required this.data,
  }) : _rawNrpName = rawNrpName;

  String get dateKey =>
      startTime.length >= 10 ? startTime.substring(0, 10) : startTime;

  String? get inspectorName {
    if (_rawNrpName == null) return null;
    try {
      final decoded = jsonDecode(_rawNrpName!) as Map<String, dynamic>;
      return decoded['nama']?.toString();
    } catch (_) {
      return null;
    }
  }

  String? get inspectorNrp {
    if (_rawNrpName == null) return null;
    try {
      final decoded = jsonDecode(_rawNrpName!) as Map<String, dynamic>;
      return decoded['nrp']?.toString();
    } catch (_) {
      return null;
    }
  }

  factory HistoryDetailItem.fromJson(Map<String, dynamic> json) {
    final dataRaw = json['data'] as Map<String, dynamic>? ?? {};
    final parsedData = <String, List<HistoryCategory>>{};
    for (final pocEntry in dataRaw.entries) {
      final categoryList = pocEntry.value as List<dynamic>;
      parsedData[pocEntry.key] = categoryList
          .map((cat) => HistoryCategory.fromJson(cat as List<dynamic>))
          .toList();
    }
    return HistoryDetailItem(
      idResult: (json['id_result'] as num?)?.toInt() ?? 0,
      scheduleId:(json['schedule_id'] ?? '').toString(),
      poc: (json['poc'] ?? '').toString(),
      startTime: (json['start_time'] ?? '').toString(),
      endTime: (json['end_time'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      validatorName: json['validator_name']?.toString(),
      validationTime: json['validation_time']?.toString(),
      rawNrpName: json['nrp_name']?.toString(),
      data: parsedData,
    );
  }
}

class HistoryCategory {
  final String name;
  final List<HistoryInspectionItem> items;

  const HistoryCategory({required this.name, required this.items});

  // json = ["CATEGORY_NAME", [[id, {details_items, activity, value}, actual, duration], ...]]
  factory HistoryCategory.fromJson(List<dynamic> json) {
    final name = (json[0] ?? '').toString();
    final itemList = (json.length > 1 ? json[1] : []) as List<dynamic>;
    return HistoryCategory(
      name: name,
      items: itemList
          .map((item) => HistoryInspectionItem.fromJson(item as List<dynamic>))
          .toList(),
    );
  }
}

class HistoryInspectionItem {
  final String id;
  final String detailsItems;
  final String activity;
  final String expectedValue;
  final String? actualValue;

  const HistoryInspectionItem({
    required this.id,
    required this.detailsItems,
    required this.activity,
    required this.expectedValue,
    this.actualValue,
  });

  // json = [id_string, {details_items, activity, value}, actual_value, duration_ms]
  factory HistoryInspectionItem.fromJson(List<dynamic> json) {
    final idStr = (json[0] ?? '').toString();
    final meta = (json.length > 1 ? json[1] : {}) as Map<String, dynamic>;
    final actualRaw = json.length > 2 ? json[2] : null;
    return HistoryInspectionItem(
      id: idStr,
      detailsItems: (meta['details_items'] ?? '').toString(),
      activity: (meta['activity'] ?? '').toString(),
      expectedValue: (meta['value'] ?? '').toString(),
      actualValue: actualRaw?.toString(),
    );
  }
}

