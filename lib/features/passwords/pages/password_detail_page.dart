// 密码本详情（v0.3）：字段点击复制（双击），支持自定义字段与备注。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/passwords_providers.dart';
import '../services/password_service.dart';
import 'password_edit_page.dart';

class PasswordDetailPage extends ConsumerStatefulWidget {
  const PasswordDetailPage({super.key, required this.entryId});

  final int entryId;

  @override
  ConsumerState<PasswordDetailPage> createState() => _PasswordDetailPageState();
}

class _PasswordDetailPageState extends ConsumerState<PasswordDetailPage> {
  PasswordEntryView? _entry;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final entry = await ref
          .read(passwordServiceProvider)
          .load(widget.entryId);
      if (!mounted) return;
      setState(() {
        _entry = entry;
        _loading = false;
        _error = entry == null ? '条目不存在或已被删除' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '读取失败：$e';
      });
    }
  }

  Future<void> _copy(String label, String value) async {
    if (value.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(label.isEmpty ? '已复制' : '已复制「$label」'),
          duration: const Duration(seconds: 1),
        ),
      );
  }

  Future<void> _delete() async {
    final entry = _entry;
    if (entry == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除条目？'),
        content: const Text('删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(passwordServiceProvider).delete(entry.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _edit() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PasswordEditPage(entryId: widget.entryId),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = _entry;
    return Scaffold(
      appBar: AppBar(
        title: Text(entry?.name ?? '密码本'),
        actions: [
          if (entry != null) ...[
            IconButton(
              tooltip: '编辑',
              onPressed: _edit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: '删除',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (entry!.fields.isEmpty)
                      const Card(
                        child: ListTile(
                          title: Text('暂无字段'),
                          subtitle: Text('点右上角编辑，添加账号、密码等自定义项。'),
                        ),
                      )
                    else
                      for (final field in entry.fields)
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              field.label.isEmpty ? '（未命名）' : field.label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            subtitle: GestureDetector(
                              // 双击复制该字段的值（需求：双击 123 即复制）。
                              onDoubleTap: () =>
                                  _copy(field.label, field.value),
                              child: Tooltip(
                                message: '双击复制',
                                waitDuration: const Duration(
                                  milliseconds: 400,
                                ),
                                child: SelectableText(
                                  field.value,
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                            ),
                            trailing: IconButton(
                              tooltip: '复制',
                              onPressed: () => _copy(field.label, field.value),
                              icon: const Icon(Icons.copy_outlined),
                            ),
                          ),
                        ),
                    if (entry.note.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '备注',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              SelectableText(entry.note),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
