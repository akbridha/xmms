import '../config/app_config.dart';
import '../services/local_storage_service.dart';

class Execution {
  final String date;
  final String section;
  final String eqNumb;
  final Map<String, List<List<dynamic>>> scheduleResults;

  Execution({
    required this.date,
    required this.section,
    required this.eqNumb,
    required this.scheduleResults,
  });

  factory Execution.fromJson(Map<String, dynamic> json) {
    final knownKeys = {'date', 'section', 'eq_numb'};
    final results = <String, List<List<dynamic>>>{};

    for (final key in json.keys) {
      if (!knownKeys.contains(key)) {
        final rawList = json[key] as List<dynamic>? ?? [];
        results[key] = rawList.map((e) => (e as List<dynamic>)).toList();
      }
    }

    return Execution(
      date: json['date'] as String? ?? '',
      section: json['section'] as String? ?? '',
      eqNumb: json['eq_numb'] as String? ?? '',
      scheduleResults: results,
    );
  }

  String get scheduleId =>
      scheduleResults.keys.isNotEmpty ? scheduleResults.keys.first : '';

  List<String> get targetPartOfChecks =>
      AppConfig.partOfCheckBySection[section] ?? const <String>[];

  Set<String> get coveredPartOfChecks {
    final covered = <String>{};

    for (final resultRows in scheduleResults.values) {
      for (final row in resultRows) {
        if (row.length < 2) continue;

        final rawPart = row[1]?.toString() ?? '';
        if (rawPart.isEmpty) continue;

        covered.add(AppConfig.normalizePartOfCheck(rawPart));
      }
    }

    return covered;
  }

  Map<String, bool> get partOfCheckStatus {
    final status = <String, bool>{};
    final covered = coveredPartOfChecks;

    for (final part in targetPartOfChecks) {
      status[part] = covered.contains(part);
    }

    return status;
  }

  int get targetPocCount => targetPartOfChecks.length;

  int get fulfilledPocCount =>
      partOfCheckStatus.values.where((isDone) => isDone).length;

  int get resultRowCount =>
      scheduleResults.values.fold<int>(0, (sum, rows) => sum + rows.length);

  int get pocCount {
    return targetPocCount;
  }

  bool get hasResults {
    return resultRowCount > 0;
  }

  /// Get count of unsynced (pending) submissions for this schedule
  /// Returns a Future since it requires database query
  Future<int> getUnsyncedCount() async {
    if (scheduleId.isEmpty) return 0;
    return await LocalStorageService.getUnsyncedCountBySchedule(scheduleId);
  }
}
