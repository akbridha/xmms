class HistoryEntry {
  final DateTime date;
  final String result;

  HistoryEntry({
    required this.date,
    required this.result,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      date: DateTime.parse(json['date'] as String),
      result: json['result'] as String? ?? '',
    );
  }
}

class FormItem {
  final int id;
  final String section;
  final String partOfCheck;
  final String item;
  final String detailsItems;
  final String activity;
  final String value;
  final String? statusRisk;
  final int order;
  final int valid;
  final List<HistoryEntry> history;

  String? inputValue;
  DateTime? _startTime;
  int durationMs = 0;

  void startTimer() {
    _startTime ??= DateTime.now();
  }

  void stopTimer() {
    if (_startTime != null) {
      durationMs += DateTime.now().difference(_startTime!).inMilliseconds;
      _startTime = null;
    }
  }

  bool get isFilled => inputValue != null && inputValue!.isNotEmpty;

  FormItem({
    required this.id,
    required this.section,
    required this.partOfCheck,
    required this.item,
    required this.detailsItems,
    required this.activity,
    required this.value,
    this.statusRisk,
    required this.order,
    required this.valid,
    this.inputValue,
    this.history = const [],
  });

  factory FormItem.fromJson(Map<String, dynamic> json) {
    final historyList = (json['history'] as List<dynamic>? ?? [])
        .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    return FormItem(
      id: json['id'] as int,
      section: json['section'] as String? ?? '',
      partOfCheck: json['part_of_check'] as String? ?? '',
      item: json['item'] as String? ?? '',
      detailsItems: json['details_items'] as String? ?? '',
      activity: json['activity'] as String? ?? '',
      value: json['value'] as String? ?? '',
      statusRisk: json['status_risk'] as String?,
      order: json['order'] as int? ?? 0,
      valid: json['valid'] as int? ?? 1,
      history: historyList,
    );
  }

  bool get isMeasure => activity.trim().toLowerCase() == 'measure' || activity.trim().toLowerCase() == 'add';

  bool get isCheck => !isMeasure;

  bool get hasInput => true;

  Map<String, dynamic> toSubmitJson() {
    return {
      'id': id,
      'input_value': inputValue ?? '',
      'duration_ms': durationMs,
    };
  }
}

class FormClaimResponse {
  final String message;
  final String partOfCheck;
  final String idSchedule;
  final List<FormItem> items;

  FormClaimResponse({
    required this.message,
    required this.partOfCheck,
    required this.idSchedule,
    required this.items,
  });

  factory FormClaimResponse.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items_claimed'] as List<dynamic>? ?? [])
        .map((e) => FormItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return FormClaimResponse(
      message: json['message'] as String? ?? '',
      partOfCheck: json['part_of_check'] as String? ?? '',
      idSchedule: json['id_schedule']?.toString() ?? '',
      items: itemsList,
    );
  }
}
