import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router.dart';
import '../../../shared/empty_state.dart';
import '../services/kb_providers.dart';
import '../widgets/category_tree.dart';
import '../widgets/kb_widgets.dart';

/// 模块3 创作资料库首页（docs/02 D4）：
/// 宽屏 = 左分类树 + 右条目列表双栏；窄屏 = 列表 + 底部弹层选分类。
class KbPage extends ConsumerStatefulWidget {
  const KbPage({super.key});

  @override
  ConsumerState<KbPage> createState() => _KbPageState();
}

class _KbPageState extends ConsumerState<KbPage> {
  String? _selectedCategory;

  void _openWizard() {
    Navigator.of(context).pushNamed(RoutePaths.kbIngest);
  }

  void _openSearch() {
    Navigator.of(context).pushNamed(RoutePaths.kbSearch);
  }

  void _openEntry(int entryId) => navigateToKbEntry(context, entryId);

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(kbDbProvider);
    if (db == null) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.storage_outlined,
          title: '数据库尚未初始化',
          hint: '请从应用入口正常启动（main 中完成数据库注入）。',
        ),
      );
    }
    final entriesAsync = ref.watch(kbEntriesStreamProvider);
    return Scaffold(
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: '资料库加载失败',
          hint: '$error',
          actionLabel: '重试',
          onAction: () => ref.invalidate(kbEntriesStreamProvider),
        ),
        data: (entries) {
          final tree = ref.watch(kbCategoriesStreamProvider).value ?? const [];
          final categoryPaths = [
            for (final c in tree) c.path,
            // 条目引用但分类行缺失的路径也纳入树，保证可筛选。
            for (final e in entries)
              if (!tree.any((c) => c.path == e.categoryPath)) e.categoryPath,
          ];
          final nodes = buildCategoryTree(categoryPaths);
          final counts = ref.watch(kbCategoryCountsProvider);
          final visible = _selectedCategory == null
              ? entries
              : entries
                    .where(
                      (e) =>
                          inCategorySubtree(e.categoryPath, _selectedCategory!),
                    )
                    .toList();
          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final header = _Header(
                onSearch: _openSearch,
                onWizard: _openWizard,
                showCategoryButton: !wide,
                onSelectCategory: wide
                    ? null
                    : () => _showCategorySheet(context, nodes, counts),
              );
              final listPane = visible.isEmpty
                  ? EmptyState(
                      icon: Icons.menu_book_outlined,
                      title: entries.isEmpty ? '资料库还是空的' : '该分类下暂无条目',
                      hint: entries.isEmpty
                          ? '通过入库向导粘贴文本或导入 TXT/MD 文件，AI 帮你清洗、分类、结构化入库。'
                          : '换个分类看看，或直接入库新条目。',
                      actionLabel: '打开入库向导',
                      onAction: _openWizard,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final entry = visible[index];
                        return KbEntryTile(
                          entry: entry,
                          onTap: () => _openEntry(entry.id),
                        );
                      },
                    );
              if (!wide) {
                return SafeArea(
                  child: Column(
                    children: [
                      header,
                      const Divider(height: 1),
                      Expanded(child: listPane),
                    ],
                  ),
                );
              }
              return SafeArea(
                child: Column(
                  children: [
                    header,
                    const Divider(height: 1),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 280,
                            child: ListView(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              children: [
                                ListTile(
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  selected: _selectedCategory == null,
                                  title: Text(
                                    '全部条目（${counts.values.fold<int>(0, (a, b) => a + b)}）',
                                    style: TextStyle(
                                      fontWeight: _selectedCategory == null
                                          ? FontWeight.bold
                                          : null,
                                    ),
                                  ),
                                  onTap: () =>
                                      setState(() => _selectedCategory = null),
                                ),
                                CategoryTreeView(
                                  nodes: nodes,
                                  directCounts: counts,
                                  selectedPath: _selectedCategory,
                                  onSelect: (path) =>
                                      setState(() => _selectedCategory = path),
                                ),
                              ],
                            ),
                          ),
                          const VerticalDivider(width: 1),
                          Expanded(child: listPane),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCategorySheet(
    BuildContext context,
    List<CategoryNode> nodes,
    Map<String, int> counts,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              ListTile(
                title: const Text('全部条目'),
                trailing: counts.isEmpty
                    ? null
                    : Text('${counts.values.fold<int>(0, (a, b) => a + b)}'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  setState(() => _selectedCategory = null);
                },
              ),
              CategoryTreeView(
                nodes: nodes,
                directCounts: counts,
                selectedPath: _selectedCategory,
                onSelect: (path) {
                  Navigator.of(sheetContext).pop();
                  setState(() => _selectedCategory = path);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onSearch,
    required this.onWizard,
    required this.showCategoryButton,
    this.onSelectCategory,
  });

  final VoidCallback onSearch;
  final VoidCallback onWizard;
  final bool showCategoryButton;
  final VoidCallback? onSelectCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '资料库',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (showCategoryButton)
            IconButton.outlined(
              tooltip: '按分类筛选',
              onPressed: onSelectCategory,
              icon: const Icon(Icons.account_tree_outlined),
            ),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300, minWidth: 160),
            child: TextField(
              readOnly: true,
              onTap: onSearch,
              decoration: const InputDecoration(
                isDense: true,
                prefixIcon: Icon(Icons.search),
                hintText: '搜索资料（关键词 + 语义）',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: onWizard,
            icon: const Icon(Icons.add),
            label: const Text('入库向导'),
          ),
        ],
      ),
    );
  }
}
