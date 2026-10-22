// 书籍列表（v0.4）：自建 / 导入 / 内置书籍；支持 TXT/MD 与网页链接导入。
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/empty_state.dart';
import '../providers/books_providers.dart';
import '../services/book_import_service.dart';
import 'book_detail_page.dart';
import 'book_edit_page.dart';

class BooksPage extends ConsumerStatefulWidget {
  const BooksPage({super.key});

  @override
  ConsumerState<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends ConsumerState<BooksPage> {
  final _searchController = TextEditingController();
  String _keyword = '';
  bool _busy = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openDetail(int bookId) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => BookDetailPage(bookId: bookId)),
    );
  }

  Future<void> _createBook() async {
    final id = await Navigator.of(context).push<int>(
      MaterialPageRoute<int>(builder: (_) => const BookEditPage()),
    );
    if (id != null && mounted) await _openDetail(id);
  }

  Future<void> _importFiles() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['txt', 'md'],
      );
      if (files.isEmpty) return;
      final books = await ref
          .read(bookImportServiceProvider)
          .importFiles(files);
      final service = ref.read(bookServiceProvider);
      int? firstId;
      for (final book in books) {
        final id = await service.createBook(
          title: book.title,
          author: book.author,
          kind: 'imported',
          sourceUrl: book.sourceUrl,
          chapters: book.chapters,
        );
        firstId ??= id;
      }
      if (!mounted) return;
      _toast('已导入 ${books.length} 本书');
      if (firstId != null) await _openDetail(firstId);
    } catch (e) {
      if (mounted) _toast('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importUrlDialog() async {
    final controller = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('从链接导入书籍'),
        content: SizedBox(
          width: 480,
          child: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '网页链接（http/https）',
              hintText: 'https://mp.weixin.qq.com/s/...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('导入'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (url == null || url.isEmpty || !mounted) return;
    setState(() => _busy = true);
    try {
      final book = await ref.read(bookImportServiceProvider).importUrl(url);
      final id = await ref
          .read(bookServiceProvider)
          .createBook(
            title: book.title,
            author: book.author,
            kind: 'imported',
            sourceUrl: book.sourceUrl,
            chapters: book.chapters,
          );
      if (!mounted) return;
      _toast('已导入《${book.title}》');
      await _openDetail(id);
    } on BookImportException catch (e) {
      if (mounted) _toast(e.message);
    } catch (e) {
      if (mounted) _toast('导入失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _kindLabel(String kind) => switch (kind) {
    'builtin' => '内置',
    'imported' => '导入',
    _ => '自建',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final booksAsync = ref.watch(booksStreamProvider);
    return Scaffold(
      body: booksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: '书籍加载失败',
          hint: '$error',
          actionLabel: '重试',
          onAction: () => ref.invalidate(booksStreamProvider),
        ),
        data: (books) {
          final keyword = _keyword.trim().toLowerCase();
          final visible = keyword.isEmpty
              ? books
              : books
                    .where(
                      (b) =>
                          b.title.toLowerCase().contains(keyword) ||
                          b.author.toLowerCase().contains(keyword),
                    )
                    .toList();
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '书籍',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 300,
                            minWidth: 160,
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) =>
                                setState(() => _keyword = value),
                            decoration: const InputDecoration(
                              isDense: true,
                              prefixIcon: Icon(Icons.search),
                              hintText: '搜索书名或作者',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _busy ? null : _createBook,
                          icon: const Icon(Icons.add),
                          label: const Text('新建书籍'),
                        ),
                        MenuAnchor(
                          builder: (context, controller, _) =>
                              FilledButton.tonalIcon(
                                onPressed: _busy
                                    ? null
                                    : () => controller.isOpen
                                          ? controller.close()
                                          : controller.open(),
                                icon: const Icon(Icons.file_download_outlined),
                                label: Text(_busy ? '导入中…' : '导入书籍'),
                              ),
                          menuChildren: [
                            MenuItemButton(
                              onPressed: _importFiles,
                              child: const Text('从 TXT / MD 文件导入'),
                            ),
                            MenuItemButton(
                              onPressed: _importUrlDialog,
                              child: const Text('从网页链接导入'),
                            ),
                          ],
                        ),
                        if (_busy)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: visible.isEmpty
                        ? EmptyState(
                            icon: Icons.auto_stories_outlined,
                            title: books.isEmpty ? '书架还是空的' : '没有匹配的书籍',
                            hint: books.isEmpty
                                ? '新建一本自己的书籍，或从 TXT/MD 文件、网页链接导入。'
                                : '换个关键词试试。',
                            actionLabel: books.isEmpty ? '新建书籍' : null,
                            onAction: books.isEmpty ? _createBook : null,
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: visible.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final book = visible[index];
                              return Card(
                                margin: EdgeInsets.zero,
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.auto_stories_outlined,
                                  ),
                                  title: Text(book.title),
                                  subtitle: Text(
                                    [
                                      if (book.author.isNotEmpty) book.author,
                                      _kindLabel(book.kind),
                                    ].join(' · '),
                                  ),
                                  trailing: Text(
                                    DateFormat(
                                      'MM-dd HH:mm',
                                    ).format(book.updatedAt),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  onTap: () => _openDetail(book.id),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
