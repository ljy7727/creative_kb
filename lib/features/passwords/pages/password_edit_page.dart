// 密码本编辑（v0.3）：名称 + 自定义字段行（左名称右值）+ 备注。
// 字段名与数量完全自定义（账号/密码/验证号/邮箱…）。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/password_models.dart';
import '../providers/passwords_providers.dart';

class _FieldRow {
  _FieldRow({String label = '', String value = ''})
    : labelController = TextEditingController(text: label),
      valueController = TextEditingController(text: value);

  final TextEditingController labelController;
  final TextEditingController valueController;

  void dispose() {
    labelController.dispose();
    valueController.dispose();
  }
}

class PasswordEditPage extends ConsumerStatefulWidget {
  const PasswordEditPage({super.key, this.entryId});

  final int? entryId;

  @override
  ConsumerState<PasswordEditPage> createState() => _PasswordEditPageState();
}

class _PasswordEditPageState extends ConsumerState<PasswordEditPage> {
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();
  final List<_FieldRow> _rows = <_FieldRow>[];
  bool _loading = true;
  bool _saving = false;

  bool get _isNew => widget.entryId == null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final id = widget.entryId;
    if (id == null) {
      _rows.add(_FieldRow(label: '账号'));
      _rows.add(_FieldRow(label: '密码'));
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final entry = await ref.read(passwordServiceProvider).load(id);
      if (!mounted) return;
      setState(() {
        if (entry != null) {
          _nameController.text = entry.name;
          _noteController.text = entry.note;
          for (final field in entry.fields) {
            _rows.add(
              _FieldRow(label: field.label, value: field.value),
            );
          }
        }
        if (_rows.isEmpty) _rows.add(_FieldRow(label: '密码'));
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _toast('读取失败：$e');
    }
  }

  void _addRow() {
    setState(() => _rows.add(_FieldRow()));
  }

  void _removeRow(_FieldRow row) {
    setState(() => _rows.remove(row));
    row.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _toast('请填写名称');
      return;
    }
    final fields = <PasswordField>[
      for (final row in _rows)
        if (row.labelController.text.trim().isNotEmpty ||
            row.valueController.text.isNotEmpty)
          PasswordField(
            label: row.labelController.text.trim(),
            value: row.valueController.text,
          ),
    ];
    final note = _noteController.text.trim();
    if (fields.isEmpty && note.isEmpty) {
      _toast('至少填写一个字段或备注');
      return;
    }
    setState(() => _saving = true);
    try {
      final service = ref.read(passwordServiceProvider);
      if (_isNew) {
        await service.create(name: name, fields: fields, note: note);
      } else {
        await service.update(
          widget.entryId!,
          name: name,
          fields: fields,
          note: note,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast('保存失败：$e');
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? '新建条目' : '编辑条目'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: FilledButton(
              onPressed: _saving || _loading ? null : _save,
              child: Text(_saving ? '保存中…' : '保存'),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '名称（例如：撸啊撸）',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('字段', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    for (var i = 0; i < _rows.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _rows[i].labelController,
                                decoration: const InputDecoration(
                                  labelText: '名称',
                                  hintText: '账号/密码/验证号…',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _rows[i].valueController,
                                autocorrect: false,
                                enableSuggestions: false,
                                decoration: const InputDecoration(
                                  labelText: '值',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: '删除该字段',
                              onPressed: () => _removeRow(_rows[i]),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                          ],
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: _addRow,
                        icon: const Icon(Icons.add),
                        label: const Text('添加自定义项'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _noteController,
                      minLines: 2,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: '备注（可空，同样加密保存）',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '字段值与备注使用 AES-GCM 加密保存，主密钥存放于系统安全存储。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
