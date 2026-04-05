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

  int get pocCount {
    if (scheduleResults.isEmpty) return 0;
    return scheduleResults.values.first.length;
  }

  bool get hasResults {
    if (scheduleResults.isEmpty) return false;
    return scheduleResults.values.first.isNotEmpty;
  }
}
