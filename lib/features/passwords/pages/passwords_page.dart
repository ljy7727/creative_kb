// 密码本列表（v0.3）：名称搜索、按更新时间倒序；条目内容加密存储。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/empty_state.dart';
import '../providers/passwords_providers.dart';
import 'password_detail_page.dart';
import 'password_edit_page.dart';

class PasswordsPage extends ConsumerStatefulWidget {
  const PasswordsPage({super.key});

  @override
  ConsumerState<PasswordsPage> createState() => _PasswordsPageState();
}

class _PasswordsPageState extends ConsumerState<PasswordsPage> {
  final _searchController = TextEditingController();
  String _keyword = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openEditor({int? entryId}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PasswordEditPage(entryId: entryId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entriesAsync = ref.watch(passwordEntriesStreamProvider);
    return Scaffold(
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: '密码本加载失败',
          hint: '$error',
          actionLabel: '重试',
          onAction: () => ref.invalidate(passwordEntriesStreamProvider),
        ),
        data: (entries) {
          final keyword = _keyword.trim().toLowerCase();
          final visible = keyword.isEmpty
              ? entries
              : entries
                    .where((e) => e.name.toLowerCase().contains(keyword))
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
                          '密码本',
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
                              hintText: '搜索名称',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => _openEditor(),
                          icon: const Icon(Icons.add),
                          label: const Text('新建条目'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: visible.isEmpty
                        ? EmptyState(
                            icon: Icons.key_outlined,
                            title: entries.isEmpty ? '密码本还是空的' : '没有匹配的条目',
                            hint: entries.isEmpty
                                ? '新建一条记录，可自定义字段（账号、密码、验证号等）；内容加密保存在本地。'
                                : '换个名称试试。',
                            actionLabel: entries.isEmpty ? '新建条目' : null,
                            onAction: entries.isEmpty
                                ? () => _openEditor()
                                : null,
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: visible.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final entry = visible[index];
                              return Card(
                                margin: EdgeInsets.zero,
                                child: ListTile(
                                  leading: const Icon(Icons.key_outlined),
                                  title: Text(entry.name),
                                  subtitle: const Text('内容已加密'),
                                  trailing: Text(
                                    DateFormat(
                                      'MM-dd HH:mm',
                                    ).format(entry.updatedAt),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => PasswordDetailPage(
                                          entryId: entry.id,
                                        ),
                                      ),
                                    );
                                  },
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
