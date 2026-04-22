// lib/services/version_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';

class VersionCheckResult {
  final bool updateAvailable;
  final bool isMandatory;
  final String currentVersion;
  final String? latestVersion;
  final String? downloadUrl;
  final String? fileSizeFormatted;
  final String? releaseNotes;
  final String? releaseDate;

  const VersionCheckResult({
    required this.updateAvailable,
    required this.isMandatory,
    required this.currentVersion,
    this.latestVersion,
    this.downloadUrl,
    this.fileSizeFormatted,
    this.releaseNotes,
    this.releaseDate,
  });

  factory VersionCheckResult.fromJson(Map<String, dynamic> body, String currentVersion) {
    final data = body['data'] as Map<String, dynamic>? ?? {};
    return VersionCheckResult(
      updateAvailable: data['update_available'] as bool? ?? false,
      isMandatory: data['is_mandatory'] as bool? ?? false,
      currentVersion: (data['current_version'] as String?) ?? currentVersion,
      latestVersion: data['latest_version'] as String?,
      downloadUrl: data['download_url'] as String?,
      fileSizeFormatted: data['file_size_formatted'] as String?,
      releaseNotes: data['release_notes'] as String?,
      releaseDate: data['release_date'] as String?,
    );
  }
}

class VersionService {
  static String get _checkUrl => '${AppConfig.host}/version/check';

  static const Duration _timeout = Duration(seconds: 10);
  static const int _maxRetries = 3;

  static Future<VersionCheckResult> checkVersion() async {
    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;

    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final uri = Uri.parse(_checkUrl).replace(queryParameters: {
          'current_version': currentVersion,
        });

        final resp = await http.get(uri).timeout(_timeout);

        if (resp.statusCode == 200) {
          final Map<String, dynamic> body = json.decode(resp.body) as Map<String, dynamic>;
          return VersionCheckResult.fromJson(body, currentVersion);
        } else {
          throw Exception('HTTP ${resp.statusCode}');
        }
      } on TimeoutException {
        if (attempt == _maxRetries) rethrow;
        await Future.delayed(Duration(seconds: 2 * attempt));
      } catch (e) {
        if (attempt == _maxRetries) rethrow;
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }
    throw Exception('Gagal cek versi');
  }

  static Future<void> checkAndPrompt(BuildContext context) async {
    try {
      final result = await checkVersion();
      if (!context.mounted) return;
      if (result.updateAvailable) {
        await _showUpdateDialog(context, result);
      } else {
        await _showUpToDateDialog(context, result);
      }
    } catch (e) {
      debugPrint('Version check failed: $e');
    }
  }

  static Future<void> _showUpdateDialog(BuildContext context, VersionCheckResult r) async {
    final mandatory = r.isMandatory;
    final contentParts = <String>[
      'Versi saat ini: ${r.currentVersion}',
      if (r.latestVersion != null) 'Versi terbaru: ${r.latestVersion}',
      if (r.fileSizeFormatted != null) 'Ukuran: ${r.fileSizeFormatted}',
      if (r.releaseDate != null) 'Tanggal rilis: ${r.releaseDate}',
      if (r.releaseNotes != null && r.releaseNotes!.isNotEmpty) '\n${r.releaseNotes}',
    ];

    await showDialog<void>(
      context: context,
      barrierDismissible: !mandatory,
      builder: (ctx) => PopScope(
        canPop: !mandatory,
        child: AlertDialog(
          title: Text(mandatory ? 'Update Wajib' : 'Update Tersedia'),
          content: Text(contentParts.join('\n')),
          actions: [
            if (!mandatory)
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Nanti'),
              ),
            TextButton(
              onPressed: () async {
                final url = r.downloadUrl;
                if (url != null && url.isNotEmpty) {
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                }
                if (!mandatory && ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _showUpToDateDialog(BuildContext context, VersionCheckResult r) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Versi Terbaru'),
        content: Text('Aplikasi sudah versi terbaru (${r.currentVersion}).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}