class HistoryDetail {
  final Map<String, dynamic> fields;

  const HistoryDetail({required this.fields});

  factory HistoryDetail.fromJson(Map<String, dynamic> json) {
    return HistoryDetail(fields: json);
  }

  List<MapEntry<String, String>> get entries {
    return fields.entries
        .where((e) => e.value != null)
        .map((e) => MapEntry(e.key, e.value.toString()))
        .toList();
  }
}
