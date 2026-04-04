import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/schedule.dart';

class ScheduleService {
  static const String _url =
      'https://app-saptaindra.msappproxy.net/PlantAdmo/api/schedule/data';

  static Future<List<Schedule>> fetchSchedules() async {
    final response = await http.get(Uri.parse(_url));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Schedule.fromJson(json)).toList();
    } else {
      throw Exception('Gagal memuat data jadwal (${response.statusCode})');
    }
  }
}
