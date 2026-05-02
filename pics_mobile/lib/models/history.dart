class History {
  final String eqNumb;
  final String date;
  final String? status;
  final String? section;
  final String? schedule_id;

  History({
    required this.eqNumb,
    required this.date,
    this.status,
    this.section,
    this.schedule_id,
  });

  factory History.fromJson(Map<String, dynamic> json) {
    return History(
      eqNumb: (json['eq_numb'] ?? json['eqNumb'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      status: json['status']?.toString(),
      section: json['section']?.toString(),
      schedule_id: json['schedule_id']?.toString(),
    );
  }
}
