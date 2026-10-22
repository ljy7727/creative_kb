// 备忘录列表（v0.3）：标题/正文搜索、按更新时间倒序、悬浮新建。
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/db/database.dart';
import '../../../shared/empty_state.dart';
import '../providers/memos_providers.dart';
import 'memo_edit_page.dart';

class MemosPage extends ConsumerStatefulWidget {
  const MemosPage({super.key});

  @override
  ConsumerState<MemosPage> createState() => _MemosPageState();
}

class _MemosPageState extends ConsumerState<MemosPage> {
  final _searchController = TextEditingController();
  String _keyword = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openEditor({int? memoId}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MemoEditPage(memoId: memoId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final memosAsync = ref.watch(memosStreamProvider);
    return Scaffold(
      body: memosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: '备忘录加载失败',
          hint: '$error',
          actionLabel: '重试',
          onAction: () => ref.invalidate(memosStreamProvider),
        ),
        data: (memos) {
          final keyword = _keyword.trim().toLowerCase();
          final visible = keyword.isEmpty
              ? memos
              : memos
                    .where(
                      (m) =>
                          m.title.toLowerCase().contains(keyword) ||
                          m.content.toLowerCase().contains(keyword),
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
                          '备忘录',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 320,
                            minWidth: 180,
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) =>
                                setState(() => _keyword = value),
                            decoration: const InputDecoration(
                              isDense: true,
                              prefixIcon: Icon(Icons.search),
                              hintText: '搜索标题或内容',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => _openEditor(),
                          icon: const Icon(Icons.add),
                          label: const Text('新建备忘录'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: visible.isEmpty
                        ? EmptyState(
                            icon: Icons.sticky_note_2_outlined,
                            title: memos.isEmpty ? '还没有备忘录' : '没有匹配的备忘录',
                            hint: memos.isEmpty
                                ? '新建一条备忘录，支持文本和图片混排保存。'
                                : '换个关键词试试。',
                            actionLabel: memos.isEmpty ? '新建备忘录' : null,
                            onAction: memos.isEmpty
                                ? () => _openEditor()
                                : null,
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: visible.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final memo = visible[index];
                              return _MemoTile(
                                memo: memo,
                                onTap: () => _openEditor(memoId: memo.id),
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

class _MemoTile extends StatelessWidget {
  const _MemoTile({required this.memo, required this.onTap});

  final MemoRow memo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageCount = decodeMemoImages(memo.images).length;
    final title = memo.title.trim().isEmpty ? '无标题' : memo.title.trim();
    final snippet = memo.content.replaceAll('\n', ' ').trim();
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          imageCount > 0 ? Icons.photo_library_outlined : Icons.notes,
        ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          snippet.isEmpty ? (imageCount > 0 ? '（图片备忘录）' : '（空）') : snippet,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              DateFormat('MM-dd HH:mm').format(memo.updatedAt),
              style: theme.textTheme.bodySmall,
            ),
            if (imageCount > 0)
              Text(
                '$imageCount 张图片',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 解析 images JSON 数组（损坏按空处理）。
List<String> decodeMemoImages(String json) {
  try {
    final decoded = jsonDecode(json);
    if (decoded is List) return [for (final item in decoded) '$item'];
  } catch (_) {
    // 损坏按空处理。
  }
  return const [];
}
