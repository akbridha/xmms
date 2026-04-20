// lib/services/version_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';

class VersionCheckResult {
  final String latestVersion;
  final String minVersion;
  final bool forceUpdate;
  final String updateUrl;
  final String? message;
  final String currentVersion;

  VersionCheckResult({
    required this.latestVersion,
    required this.minVersion,
    required this.forceUpdate,
    required this.updateUrl,
    this.message,
    required this.currentVersion,
  });

  bool get needsUpdate => _compareVersion(currentVersion, latestVersion) < 0;

  factory VersionCheckResult.fromJson(Map<String, dynamic> json, String currentVersion) {
    return VersionCheckResult(
      latestVersion: (json['latest_version'] ?? json['latest'] ?? '0.0.0') as String,
      minVersion: (json['min_version'] ?? json['minVersion'] ?? '0.0.0') as String,
      forceUpdate: (json['force_update'] == true || json['force'] == true),
      updateUrl: (json['update_url'] ?? json['download_url'] ?? '') as String,
      message: json['message'] as String?,
      currentVersion: currentVersion,
    );
  }
}

class VersionService {
  // sesuaikan endpoint di server Anda
  static String get _checkUrl => '${AppConfig.host}/app/version';

  static const Duration _timeout = Duration(seconds: 10);
  static const int _maxRetries = 3;

  static Future<VersionCheckResult> checkVersion() async {
    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;
    final currentBuild = info.buildNumber;

    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final uri = Uri.parse(_checkUrl).replace(queryParameters: {
          'platform': _detectPlatform(),
          'version': currentVersion,
          'build': currentBuild,
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
      if (result.needsUpdate) {
        await _showUpdateDialog(context, result);
      }
    } catch (e) {
      debugPrint('Version check failed: $e');
    }
  }

  static Future<void> _showUpdateDialog(BuildContext context, VersionCheckResult r) async {
    final force = r.forceUpdate;
    await showDialog<void>(
      context: context,
      barrierDismissible: !force,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => !force,
        child: AlertDialog(
          title: Text(force ? 'Update Wajib' : 'Update Tersedia'),
          content: Text(r.message ?? 'Versi saat ini: ${r.currentVersion}\nVersi terbaru: ${r.latestVersion}'),
          actions: [
            if (!force)
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Nanti')),
            TextButton(
              onPressed: () async {
                final url = r.updateUrl;
                if (url.isNotEmpty) {
                  final uri = Uri.parse(url);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
                if (!force) Navigator.of(ctx).pop();
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  static String _detectPlatform() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return defaultTargetPlatform.toString();
    }
  }
}

int _compareVersion(String a, String b) {
  List<int> norm(String v) {
    final s = v.split('+').first.split('-').first;
    return s.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  }

  final A = norm(a);
  final B = norm(b);
  final n = A.length > B.length ? A.length : B.length;
  for (var i = 0; i < n; i++) {
    final ai = i < A.length ? A[i] : 0;
    final bi = i < B.length ? B[i] : 0;
    if (ai < bi) return -1;
    if (ai > bi) return 1;
  }
  return 0;
}