// 书籍详情（v0.4）：书籍信息 + 章节列表；自建书籍可增删改章节。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../providers/books_providers.dart';
import 'book_edit_page.dart';
import 'book_reader_page.dart';
import 'chapter_edit_page.dart';

class BookDetailPage extends ConsumerStatefulWidget {
  const BookDetailPage({super.key, required this.bookId});

  final int bookId;

  @override
  ConsumerState<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends ConsumerState<BookDetailPage> {
  BookRow? _book;
  bool _loading = true;

  bool get _editable => _book?.kind == 'self';

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    final book = await ref.read(booksDaoProvider).byId(widget.bookId);
    if (!mounted) return;
    setState(() {
      _book = book;
      _loading = false;
    });
  }

  Future<void> _editMeta() async {
    final book = _book;
    if (book == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => BookEditPage(book: book)),
    );
    await _loadBook();
  }

  Future<void> _addChapter() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChapterEditPage(bookId: widget.bookId),
      ),
    );
  }

  Future<void> _editChapter(BookChapterRow chapter) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChapterEditPage(
          bookId: widget.bookId,
          chapter: chapter,
        ),
      ),
    );
  }

  Future<void> _deleteChapter(BookChapterRow chapter) async {
    final confirmed = await _confirm('删除本章？', '「${chapter.title}」将被删除，无法恢复。');
    if (confirmed != true) return;
    await ref.read(bookServiceProvider).deleteChapter(chapter.id);
  }

  Future<void> _deleteBook() async {
    final book = _book;
    if (book == null) return;
    final confirmed = await _confirm(
      '删除书籍？',
      '「${book.title}」及其全部章节将被删除，无法恢复。',
    );
    if (confirmed != true) return;
    await ref.read(bookServiceProvider).deleteBook(book.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<bool?> _confirm(String title, String content) => showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(content),
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

  String get _kindLabel => switch (_book?.kind) {
    'builtin' => '内置',
    'imported' => '导入',
    _ => '自建',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chaptersAsync = ref.watch(
      bookChaptersStreamProvider(widget.bookId),
    );
    final book = _book;
    return Scaffold(
      appBar: AppBar(
        title: Text(book?.title ?? '书籍'),
        actions: [
          if (_editable)
            IconButton(
              tooltip: '编辑书籍信息',
              onPressed: _editMeta,
              icon: const Icon(Icons.edit_outlined),
            ),
          IconButton(
            tooltip: '删除书籍',
            onPressed: _loading ? null : _deleteBook,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      floatingActionButton: _editable
          ? FloatingActionButton.extended(
              onPressed: _addChapter,
              icon: const Icon(Icons.playlist_add),
              label: const Text('添加章节'),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : book == null
          ? const Center(child: Text('书籍不存在或已被删除'))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: chaptersAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('章节加载失败：$error')),
                  data: (chapters) => ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      book.title,
                                      style: theme.textTheme.titleLarge,
                                    ),
                                  ),
                                  Chip(
                                    label: Text(_kindLabel),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                [
                                  if (book.author.isNotEmpty) book.author,
                                  '${chapters.length} 章',
                                ].join(' · '),
                                style: theme.textTheme.bodySmall,
                              ),
                              if (book.sourceUrl.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                SelectableText(
                                  book.sourceUrl,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (chapters.isEmpty)
                        const Card(
                          child: ListTile(
                            title: Text('还没有章节'),
                            subtitle: Text('点右下角「添加章节」开始写作。'),
                          ),
                        )
                      else
                        for (var i = 0; i < chapters.length; i++)
                          Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 16,
                                child: Text('${i + 1}'),
                              ),
                              title: Text(chapters[i].title),
                              subtitle: Text(
                                _preview(chapters[i].content),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => BookReaderPage(
                                    title: chapters[i].title,
                                    content: chapters[i].content,
                                  ),
                                ),
                              ),
                              trailing: _editable
                                  ? PopupMenuButton<String>(
                                      tooltip: '章节操作',
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _editChapter(chapters[i]);
                                        } else if (value == 'delete') {
                                          _deleteChapter(chapters[i]);
                                        }
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text('编辑'),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text('删除'),
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  String _preview(String content) {
    final text = content
        .replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), '[图片]')
        .replaceAll(RegExp(r'[#*>`\-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return text.isEmpty ? '（空章节）' : text;
  }
}
