// 更新弹窗（设置页与启动自动检查共用）：
// 展示「当前版本 → 最新版本」与 Release Notes；Android 支持应用内下载 APK
// 并拉起系统安装器，桌面端打开 Release 页。
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'update_checker.dart';

/// 展示更新对话框。返回后由调用方决定是否继续其它流程。
Future<void> showUpdateDialog(
  BuildContext context,
  UpdateCheckResult result,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => _UpdateDialog(result: result),
  );
}

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({required this.result});

  final UpdateCheckResult result;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _downloading = false;
  double? _progress;
  String? _error;

  bool get _isAndroid => UpdateChecker.isAndroidPlatform;

  Future<void> _openReleasePage() async {
    final url = UpdateChecker.downloadUrl(
      widget.result,
      isAndroid: _isAndroid,
    );
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) setState(() => _error = '无法打开链接：$url');
    }
  }

  /// Android：下载 APK 到应用缓存目录 → 拉起系统安装器。
  /// 桌面：打开发布页（便携 zip 需手动替换）。
  Future<void> _installOrDownload() async {
    final url = widget.result.apkUrl;
    if (!_isAndroid || url == null) {
      await _openReleasePage();
      return;
    }
    setState(() {
      _downloading = true;
      _progress = null;
      _error = null;
    });
    try {
      final dir = await getTemporaryDirectory();
      final fileName =
          'creative_kb-${widget.result.latestVersion ?? 'update'}.apk';
      final path = '${dir.path}/$fileName';
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(minutes: 10),
        ),
      );
      await dio.download(
        url,
        path,
        onReceiveProgress: (received, total) {
          if (!mounted) return;
          setState(() => _progress = total > 0 ? received / total : null);
        },
      );
      final opened = await OpenFilex.open(path);
      if (!mounted) return;
      if (opened.type == ResultType.done) {
        Navigator.of(context).pop();
      } else {
        setState(
          () => _error = '无法拉起安装器（${opened.message}）。APK 已保存：$path',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = '下载失败：$e');
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = widget.result;
    final notes = result.releaseNotes?.trim() ?? '';
    return AlertDialog(
      title: Text('发现新版本 ${result.tagName ?? ''}'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '当前版本 ${result.currentVersion} → '
              '最新版本 ${result.latestVersion ?? ''}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            if (notes.isEmpty)
              const Text('（无 Release Notes）')
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: SingleChildScrollView(
                  child: MarkdownBody(data: notes),
                ),
              ),
            if (_downloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 6),
              Text(
                _progress == null
                    ? '正在下载…'
                    : '正在下载 ${(_progress! * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _downloading ? null : () => Navigator.of(context).pop(),
          child: const Text('稍后再说'),
        ),
        FilledButton(
          onPressed: _downloading ? null : _installOrDownload,
          child: Text(
            _isAndroid && result.apkUrl != null ? '下载并安装' : '前往下载',
          ),
        ),
      ],
    );
  }
}
