import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'dart:developer' as developer;

class HistoryPrintService {
  // Base URL - you can move this to config/env file
  // static const String baseUrl = '/api/history/detail?id=67137';

  
  
  // Add headers if needed (e.g., authentication)
  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    // 'Authorization': 'Bearer $token', // if using auth
  };

  // Generic GET request


  // Generic POST request
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.host}/api/history/detail?id=67137'),
        headers: headers,
        body: json.encode(data),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to post data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // services/history_print_service.dart
  Future<List<Map<String, dynamic>>> getHistoryPrints({
    required String scheduleId,
    required String unitCode,
  }) async {
    try {
      final response = await http.get(
        // Uri.parse('${AppConfig.host}/history/mobile?id=$scheduleId'),
        Uri.parse('${AppConfig.host}/history/mobile?id=67113'),
        headers: headers,
      );

      developer.log('${AppConfig.host}/history/mobile?id=$scheduleId');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        // Pastikan jsonData adalah List dan konversi setiap elemen ke Map
        if (jsonData is List) {
          return jsonData
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        } else {
          // Jika response bukan List, mungkin ada wrapper; fallback
          return [Map<String, dynamic>.from(jsonData)];
        }
      } else {
        throw Exception('Failed to load history print results');
      }
    } catch (e) {
      throw Exception('Error fetching history print results: $e');
    }
  }
}