// 章节编辑（v0.4）：新建或修改章节（标题 + Markdown 正文）。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../providers/books_providers.dart';

class ChapterEditPage extends ConsumerStatefulWidget {
  const ChapterEditPage({super.key, required this.bookId, this.chapter});

  final int bookId;

  /// null = 新增章节；非空 = 编辑该章节。
  final BookChapterRow? chapter;

  @override
  ConsumerState<ChapterEditPage> createState() => _ChapterEditPageState();
}

class _ChapterEditPageState extends ConsumerState<ChapterEditPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.chapter?.title ?? '');
    _contentController = TextEditingController(
      text: widget.chapter?.content ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final service = ref.read(bookServiceProvider);
      final chapter = widget.chapter;
      if (chapter == null) {
        await service.addChapter(
          widget.bookId,
          title: _titleController.text,
          content: _contentController.text,
        );
      } else {
        await service.updateChapter(
          chapter.id,
          title: _titleController.text,
          content: _contentController.text,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('保存失败：$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chapter == null ? '添加章节' : '编辑章节'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? '保存中…' : '保存'),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '章节标题（可空，默认第 N 章）',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                minLines: 14,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  labelText: '正文（Markdown；图片可用 assets/... 或 http(s) 链接）',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
