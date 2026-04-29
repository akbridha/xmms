class History {
  final String eqNumb;
  final String date;
  final String? status;
  final String? section;
  final int? id;

  History({
    required this.eqNumb,
    required this.date,
    this.status,
    this.section,
    this.id,
  });

  factory History.fromJson(Map<String, dynamic> json) {
    return History(
      eqNumb: (json['eq_numb'] ?? json['eqNumb'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      status: json['status']?.toString(),
      section: json['section']?.toString(),
      id: json['id'] is int ? json['id'] as int : null,
    );
  }
}
