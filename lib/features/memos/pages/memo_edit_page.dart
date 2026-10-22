// 备忘录编辑页（v0.3）：标题 + 多行正文 + 图片（本地复制存储，可删）。
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../providers/memos_providers.dart';
import 'memos_page.dart';

class MemoEditPage extends ConsumerStatefulWidget {
  const MemoEditPage({super.key, this.memoId});

  final int? memoId;

  @override
  ConsumerState<MemoEditPage> createState() => _MemoEditPageState();
}

class _MemoEditPageState extends ConsumerState<MemoEditPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final List<String> _images = <String>[];
  bool _loading = true;
  bool _saving = false;
  MemoRow? _row;

  bool get _isNew => widget.memoId == null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = widget.memoId;
    if (id == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final row = await ref.read(memosDaoProvider).byId(id);
      if (!mounted) return;
      setState(() {
        _row = row;
        if (row != null) {
          _titleController.text = row.title;
          _contentController.text = row.content;
          _images.addAll(decodeMemoImages(row.images));
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _toast('加载失败：$e');
    }
  }

  Future<void> _addImages() async {
    try {
      final files = await FilePicker.pickFiles(type: FileType.image);
      if (files.isEmpty) return;
      final store = ref.read(memoImageStoreProvider);
      final saved = <String>[];
      for (final file in files) {
        saved.add(await store.save(file));
      }
      if (!mounted) return;
      setState(() => _images.addAll(saved));
    } catch (e) {
      if (mounted) _toast('添加图片失败：$e');
    }
  }

  Future<void> _removeImage(String path) async {
    setState(() => _images.remove(path));
    await ref.read(memoImageStoreProvider).delete(path);
  }

  Future<void> _save() async {
    if (_saving) return;
    final title = _titleController.text.trim();
    final content = _contentController.text;
    if (title.isEmpty && content.trim().isEmpty && _images.isEmpty) {
      _toast('写点什么或加张图片再保存吧');
      return;
    }
    setState(() => _saving = true);
    try {
      final dao = ref.read(memosDaoProvider);
      final now = DateTime.now();
      final imagesJson = jsonEncode(_images);
      if (_isNew) {
        await dao.add(
          MemosCompanion.insert(
            title: Value(title),
            content: Value(content),
            images: Value(imagesJson),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      } else {
        final row = _row;
        if (row == null) throw StateError('备忘录不存在');
        await dao.updateRow(
          row.copyWith(
            title: title,
            content: content,
            images: imagesJson,
            updatedAt: now,
          ),
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

  Future<void> _delete() async {
    final row = _row;
    if (row == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除备忘录？'),
        content: const Text('正文与图片将一并删除，无法恢复。'),
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
    try {
      final store = ref.read(memoImageStoreProvider);
      for (final path in decodeMemoImages(row.images)) {
        await store.delete(path);
      }
      await ref.read(memosDaoProvider).deleteById(row.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) _toast('删除失败：$e');
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? '新建备忘录' : '备忘录'),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: '删除',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
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
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: '标题（可空）',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _contentController,
                      minLines: 8,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        labelText: '内容',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _addImages,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('添加图片'),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _images.isEmpty ? '' : '共 ${_images.length} 张',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    if (_images.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final path in _images)
                            _ImageThumb(
                              path: path,
                              onDelete: () => _removeImage(path),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

class _ImageThumb extends StatelessWidget {
  const _ImageThumb({required this.path, required this.onDelete});

  final String path;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(path),
            width: 140,
            height: 140,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 140,
              height: 140,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: onDelete,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(3),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
