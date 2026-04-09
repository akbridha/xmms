class ValidationItem {
  final String date;
  final String eqNumb;
  final String section;
  final int scheduleId;
  final String mostEarliestUpdated;
  final String mostLatestUpdated;
  final String totalDuration;
  final int totalDurationMinutes;
  final Map<String, PocDuration> pocDurationsDetail;

  ValidationItem({
    required this.date,
    required this.eqNumb,
    required this.section,
    required this.scheduleId,
    required this.mostEarliestUpdated,
    required this.mostLatestUpdated,
    required this.totalDuration,
    required this.totalDurationMinutes,
    required this.pocDurationsDetail,
  });

  factory ValidationItem.fromJson(Map<String, dynamic> json) {
    final pocDurationsRaw = json['poc_durations_detail'] as Map<String, dynamic>? ?? {};
    final pocDurations = <String, PocDuration>{};

    pocDurationsRaw.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        pocDurations[key] = PocDuration.fromJson(value);
      }
    });

    return ValidationItem(
      date: json['date'] as String? ?? '',
      eqNumb: json['eq_numb'] as String? ?? '',
      section: json['section'] as String? ?? '',
      scheduleId: json['schedule_id'] as int? ?? 0,
      mostEarliestUpdated: json['mostEarliestUpdated'] as String? ?? '',
      mostLatestUpdated: json['mostLatestUpdated'] as String? ?? '',
      totalDuration: json['total_duration'] as String? ?? '',
      totalDurationMinutes: json['total_duration_minutes'] as int? ?? 0,
      pocDurationsDetail: pocDurations,
    );
  }

  Map<String, dynamic> toJson() {
    final pocDurationsJson = <String, dynamic>{};
    pocDurationsDetail.forEach((key, value) {
      pocDurationsJson[key] = value.toJson();
    });

    return {
      'date': date,
      'eq_numb': eqNumb,
      'section': section,
      'schedule_id': scheduleId,
      'mostEarliestUpdated': mostEarliestUpdated,
      'mostLatestUpdated': mostLatestUpdated,
      'total_duration': totalDuration,
      'total_duration_minutes': totalDurationMinutes,
      'poc_durations_detail': pocDurationsJson,
    };
  }
}

class PocDuration {
  final String duration;
  final int minutes;

  PocDuration({
    required this.duration,
    required this.minutes,
  });

  factory PocDuration.fromJson(Map<String, dynamic> json) {
    return PocDuration(
      duration: json['duration'] as String? ?? '',
      minutes: json['minutes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'duration': duration,
      'minutes': minutes,
    };
  }
}
