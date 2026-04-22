// lib/screens/update_download_screen.dart
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/version_service.dart';

class UpdateDownloadScreen extends StatefulWidget {
  const UpdateDownloadScreen({
    super.key,
    required this.versionResult,
    required this.isMandatory,
  });

  final VersionCheckResult versionResult;
  final bool isMandatory;

  @override
  State<UpdateDownloadScreen> createState() => _UpdateDownloadScreenState();
}

class _UpdateDownloadScreenState extends State<UpdateDownloadScreen> {
  _DownloadState _state = _DownloadState.downloading;
  double _progress = 0.0;
  int _receivedBytes = 0;
  int _totalBytes = 0;
  String? _errorMessage;
  String? _savedPath;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var value = bytes.toDouble();
    var i = 0;
    while (value >= 1024 && i < suffixes.length - 1) {
      value /= 1024;
      i++;
    }
    return '${value.toStringAsFixed(2)} ${suffixes[i]}';
  }

  Future<void> _startDownload() async {
    setState(() {
      _state = _DownloadState.downloading;
      _progress = 0.0;
      _receivedBytes = 0;
      _totalBytes = 0;
      _errorMessage = null;
    });

    try {
      final url = widget.versionResult.downloadUrl;
      if (url == null || url.isEmpty) {
        throw Exception('URL unduhan tidak tersedia');
      }

      final request = http.Request('GET', Uri.parse(url));
      final client = http.Client();
      final response = await client.send(request);

      if (response.statusCode != 200) {
        client.close();
        throw Exception('Server error: HTTP ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      setState(() => _totalBytes = contentLength);

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/update.apk';
      final file = File(filePath);
      final sink = file.openWrite();

      try {
        await for (final chunk in response.stream) {
          sink.add(chunk);
          if (mounted) {
            setState(() {
              _receivedBytes += chunk.length;
              if (contentLength > 0) {
                _progress = _receivedBytes / contentLength;
              }
            });
          }
        }
        await sink.flush();
        await sink.close();
      } catch (e) {
        await sink.close();
        rethrow;
      } finally {
        client.close();
      }

      if (!mounted) return;
      _savedPath = filePath;
      await _triggerInstall(filePath);
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _DownloadState.error;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _triggerInstall(String path) async {
    if (!Platform.isAndroid) {
      setState(() {
        _state = _DownloadState.error;
        _errorMessage = 'Instalasi otomatis hanya didukung di Android.';
      });
      return;
    }

    setState(() => _state = _DownloadState.installing);

    final status = await Permission.requestInstallPackages.status;

    if (status.isGranted) {
      final result = await OpenFile.open(path, type: 'application/vnd.android.package-archive');
      if (result.type != ResultType.done) {
        if (mounted) {
          setState(() {
            _state = _DownloadState.error;
            _errorMessage = 'Gagal membuka installer: ${result.message}';
          });
        }
      }
    } else {
      // Permission denied — guide user to settings
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Izin Diperlukan'),
          content: const Text(
            'Untuk menginstal pembaruan, aktifkan "Install unknown apps" '
            'untuk aplikasi ini di Pengaturan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await openAppSettings();
              },
              child: const Text('Buka Pengaturan'),
            ),
          ],
        ),
      );
      if (mounted) {
        setState(() => _state = _DownloadState.awaitingPermission);
      }
    }
  }

  Future<void> _retryInstallAfterPermission() async {
    if (_savedPath != null) {
      await _triggerInstall(_savedPath!);
    } else {
      await _startDownload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !widget.isMandatory,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Memperbarui Aplikasi'),
          automaticallyImplyLeading: !widget.isMandatory,
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: _buildBody(theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    switch (_state) {
      case _DownloadState.downloading:
        return _DownloadingView(
          progress: _progress,
          receivedBytes: _receivedBytes,
          totalBytes: _totalBytes,
          versionResult: widget.versionResult,
          formatBytes: _formatBytes,
        );

      case _DownloadState.installing:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Memulai instalasi...',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        );

      case _DownloadState.awaitingPermission:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'Izin instalasi diperlukan.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Aktifkan "Install unknown apps" di Pengaturan lalu kembali ke sini.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: openAppSettings,
                  child: const Text('Buka Pengaturan'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _retryInstallAfterPermission,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ],
        );

      case _DownloadState.error:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 24),
            Text(
              'Unduhan gagal',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startDownload,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        );
    }
  }
}

enum _DownloadState { downloading, installing, awaitingPermission, error }

class _DownloadingView extends StatelessWidget {
  const _DownloadingView({
    required this.progress,
    required this.receivedBytes,
    required this.totalBytes,
    required this.versionResult,
    required this.formatBytes,
  });

  final double progress;
  final int receivedBytes;
  final int totalBytes;
  final VersionCheckResult versionResult;
  final String Function(int) formatBytes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = versionResult;
    final hasTotal = totalBytes > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.system_update_alt, size: 64, color: theme.colorScheme.primary),
        const SizedBox(height: 24),
        Text(
          'Mengunduh Pembaruan',
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '${r.currentVersion} → ${r.latestVersion ?? ''}',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        LinearProgressIndicator(
          value: hasTotal ? progress : null,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 12),
        Text(
          hasTotal
              ? '${formatBytes(receivedBytes)} / ${formatBytes(totalBytes)}'
              : '${formatBytes(receivedBytes)} diunduh...',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        if (hasTotal) ...[
          const SizedBox(height: 4),
          Text(
            '${(progress * 100).toStringAsFixed(1)}%',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
