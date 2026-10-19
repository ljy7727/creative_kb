import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/search/hybrid_search.dart';
import '../../../shared/empty_state.dart';
import '../services/kb_providers.dart';
import '../widgets/category_tree.dart';
import '../widgets/kb_widgets.dart';

/// 资料检索页（docs/02 D4）：单一搜索框，关键词（FTS 加权）+ 语义（余弦）
/// 混合排序；未配置嵌入模型时纯 FTS 并提示。左侧分类树可折叠带计数，
/// 结果列表（标题/摘要/标签/可信度色点），点击进详情。
class KbSearchPage extends ConsumerStatefulWidget {
  const KbSearchPage({super.key});

  @override
  ConsumerState<KbSearchPage> createState() => _KbSearchPageState();
}

class _KbSearchPageState extends ConsumerState<KbSearchPage> {
  final _queryController = TextEditingController();
  HybridSearchResult? _result;
  bool _searching = false;
  String? _error;
  String? _selectedCategory;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final query = _queryController.text.trim();
    if (query.isEmpty || _searching) return;
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      HybridEmbedding? semantic;
      final config = await ref.read(embeddingConfigProvider.future);
      var aiReady = false;
      try {
        aiReady = await ref.read(kbAiAvailableProvider.future);
      } catch (_) {
        aiReady = false;
      }
      if (config != null && aiReady) {
        final gateway = ref.read(kbAiGatewayProvider);
        final model = config.model;
        semantic = HybridEmbedding(
          model: model,
          embed: (text) => gateway.embed(model: model, text: text),
        );
      }
      final service = ref.read(hybridSearchServiceProvider);
      final result = await service.search(query, semantic: semantic);
      if (!mounted) return;
      setState(() => _result = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '检索失败：$e');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tree =
        ref.watch(kbCategoriesStreamProvider).value ?? const <KbCategory>[];
    final counts = ref.watch(kbCategoryCountsProvider);
    final nodes = buildCategoryTree([for (final c in tree) c.path]);
    final showTree = (tree.isNotEmpty || counts.isNotEmpty);

    return Scaffold(
      appBar: AppBar(title: const Text('资料检索')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final resultsPane = _buildResults(context);
          if (!wide) {
            return Column(
              children: [
                _SearchBar(
                  controller: _queryController,
                  searching: _searching,
                  onSubmit: _runSearch,
                  onPickCategory: showTree
                      ? () => _showCategorySheet(context, nodes, counts)
                      : null,
                ),
                _buildNotice(),
                Expanded(child: resultsPane),
              ],
            );
          }
          return Column(
            children: [
              _SearchBar(
                controller: _queryController,
                searching: _searching,
                onSubmit: _runSearch,
              ),
              _buildNotice(),
              const Divider(height: 1),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showTree) ...[
                      SizedBox(
                        width: 280,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          children: [
                            ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              selected: _selectedCategory == null,
                              title: const Text('全部分类'),
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
                    ],
                    Expanded(child: resultsPane),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotice() {
    final notice = _result?.notice;
    if (notice == null) return const SizedBox.shrink();
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.info_outline, size: 18),
        title: Text(notice, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    if (_error != null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: '检索失败',
        hint: _error,
        actionLabel: '重试',
        onAction: _runSearch,
      );
    }
    if (_result == null) {
      // 未搜索时展示最近条目（浏览模式）。
      final entries =
          ref.watch(kbEntriesStreamProvider).value ?? const <KbEntry>[];
      if (entries.isEmpty) {
        return const EmptyState(
          icon: Icons.search,
          title: '输入关键词开始检索',
          hint: '支持关键词命中名称/摘要/正文；配置嵌入模型后可按语义召回。',
        );
      }
      return _HitList(hits: null, fallbackEntries: entries.take(30).toList());
    }
    var hits = _result!.hits;
    if (_selectedCategory != null) {
      hits = hits
          .where(
            (h) => inCategorySubtree(h.entry.categoryPath, _selectedCategory!),
          )
          .toList();
    }
    if (hits.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: '没有匹配的资料',
        hint: _result!.semanticUsed
            ? '试试更换关键词；语义召回也依赖条目已完成向量化。'
            : '试试更换关键词，或配置嵌入模型开启语义检索。',
      );
    }
    return _HitList(hits: hits);
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              ListTile(
                title: const Text('全部分类'),
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

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.searching,
    required this.onSubmit,
    this.onPickCategory,
  });

  final TextEditingController controller;
  final bool searching;
  final VoidCallback onSubmit;
  final VoidCallback? onPickCategory;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search),
                hintText: '搜索资料（如：宗门 护山大阵）',
                border: const OutlineInputBorder(),
                suffixIcon: searching
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: searching ? null : onSubmit,
            child: const Text('检索'),
          ),
          if (onPickCategory != null) ...[
            const SizedBox(width: 8),
            IconButton.outlined(
              tooltip: '按分类筛选',
              onPressed: onPickCategory,
              icon: const Icon(Icons.account_tree_outlined),
            ),
          ],
        ],
      ),
    );
  }
}

class _HitList extends ConsumerWidget {
  const _HitList({required this.hits, this.fallbackEntries});

  final List<HybridSearchHit>? hits;
  final List<KbEntry>? fallbackEntries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (hits != null) {
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: hits!.length,
        itemBuilder: (context, index) {
          final hit = hits![index];
          return Column(
            children: [
              KbEntryTile(
                entry: hit.entry,
                onTap: () => navigateToKbEntry(context, hit.entry.id),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Row(
                  children: [
                    Text(
                      '综合 ${hit.score.toStringAsFixed(3)}'
                      '（关键词 ${hit.ftsScore.toStringAsFixed(2)}'
                      ' · 语义 ${hit.vectorScore.toStringAsFixed(2)}）',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
    }
    final fallback = fallbackEntries ?? const <KbEntry>[];
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: fallback.length,
      itemBuilder: (context, index) {
        final entry = fallback[index];
        return KbEntryTile(
          entry: entry,
          onTap: () => navigateToKbEntry(context, entry.id),
        );
      },
    );
  }
}
