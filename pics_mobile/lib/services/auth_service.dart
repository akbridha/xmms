import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../models/login_response.dart';

class AuthService {
  static String get _loginUrl => '${AppConfig.host}/login';
  static const int _maxRetries = 3;
  static const Duration _timeout = Duration(seconds: 30);

  static Future<LoginResponse> login({
    required String nrp,
    required String password,
  }) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final uri = Uri.parse(_loginUrl).replace(
          queryParameters: {
            'nrp': nrp,
            'password': password,
          },
        );

        debugPrint(
          '[AuthService] Attempt $attempt/$_maxRetries - GET: ${uri.toString().replaceAll(RegExp(r'password=[^&]*'), 'password=***')}',
        );

        final response = await http.get(uri).timeout(_timeout);

        debugPrint(
          '[AuthService] Response Status: ${response.statusCode}',
        );

        if (response.statusCode == 200) {
          final loginResponse = LoginResponse.fromJson(
            json.decode(response.body) as Map<String, dynamic>,
          );
          
          if (loginResponse.success) {
            debugPrint('[AuthService] Login successful for NRP: $nrp');
          } else {
            debugPrint('[AuthService] Login failed: ${loginResponse.message}');
          }
          
          return loginResponse;
        } else {
          throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          );
        }
      } on TimeoutException {
        debugPrint('[AuthService] Timeout on attempt $attempt');
        if (attempt == _maxRetries) {
          throw Exception(
            'Timeout setelah $attempt percobaan. Server tidak merespons dalam 30 detik.',
          );
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
      } on SocketException catch (e) {
        debugPrint('[AuthService] SocketException on attempt $attempt: $e');
        if (attempt == _maxRetries) {
          throw Exception(
            'Gagal terhubung ke server. Periksa koneksi internet Anda.',
          );
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
      } on HttpException catch (e) {
        debugPrint('[AuthService] HttpException on attempt $attempt: $e');
        if (attempt == _maxRetries) {
          throw Exception('Terjadi kesalahan HTTP: ${e.message}');
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
      } on FormatException catch (e) {
        debugPrint('[AuthService] FormatException: $e');
        throw Exception(
          'Response server tidak valid. Harap hubungi administrator.',
        );
      } catch (e) {
        debugPrint('[AuthService] Unexpected error on attempt $attempt: $e');
        if (attempt == _maxRetries) {
          throw Exception('Terjadi kesalahan: $e');
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }

    throw Exception('Login gagal setelah $_maxRetries percobaan');
  }
}
