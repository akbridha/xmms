class Schedule {
  final int id;
  final String date;
  final int valid;
  final String equipmentCode;

  Schedule({
    required this.id,
    required this.date,
    required this.valid,
    required this.equipmentCode,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] as int,
      date: json['date'] as String,
      valid: json['valid'] as int,
      equipmentCode: json['equipment_code'] as String,
    );
  }
}
