import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/router.dart';
import '../../../shared/empty_state.dart';
import '../models/prompt_models.dart';
import '../providers/prompts_providers.dart';
import '../services/prompt_templates.dart';
import 'prompt_detail_page.dart';
import 'prompt_generate_page.dart';

/// 模块2 提示词库列表页：类型/分类筛选 + 关键词检索 + 模板新建 / 从碎片生成。
class PromptsPage extends ConsumerStatefulWidget {
  const PromptsPage({super.key});

  @override
  ConsumerState<PromptsPage> createState() => _PromptsPageState();
}

class _PromptsPageState extends ConsumerState<PromptsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openDetail(int promptId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        // 路由名与路由常量表一致，便于 T7 统一接线。
        settings: const RouteSettings(name: RoutePaths.promptDetail),
        builder: (_) => PromptDetailPage(promptId: promptId),
      ),
    );
  }

  void _openGenerate() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: RoutePaths.promptGenerate),
        builder: (_) => const PromptGeneratePage(),
      ),
    );
  }

  void _showCreateMenu() {
    final aiReady = ref.read(promptAiReadyProvider).value ?? false;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('从模板新建'),
              subtitle: const Text('小说 / AI 绘画 / Agent 三类四段式骨架'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _showCreateDialog();
              },
            ),
            Tooltip(
              message: aiReady ? '' : '请先在设置中配置 API Key',
              child: ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: const Text('从灵感碎片生成（AI）'),
                subtitle: const Text('选碎片 → 一次生成 3 个风格版本'),
                enabled: aiReady,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openGenerate();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateDialog() async {
    await showDialog<void>(
      context: context,
      builder: (_) => const _PromptCreateDialog(),
    );
  }

  Future<void> _confirmDelete(Prompt prompt) async {
    final repository = ref.read(promptRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除提示词'),
        content: Text('删除「${prompt.title}」将连同全部版本历史一起删除，确定吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await repository.remove(prompt.id);
    messenger.showSnackBar(const SnackBar(content: Text('已删除')));
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(promptFilterProvider);
    final listAsync = ref.watch(promptListProvider);
    final categories =
        ref.watch(promptCategoriesProvider).value ?? const <String>[];

    return Scaffold(
      appBar: AppBar(title: const Text('提示词')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: ref.read(promptFilterProvider.notifier).setKeyword,
              decoration: const InputDecoration(
                hintText: '搜索标题或正文',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ChoiceChip(
                  label: const Text('全部类型'),
                  selected: filter.type == null,
                  onSelected: (_) =>
                      ref.read(promptFilterProvider.notifier).setType(null),
                ),
                for (final type in PromptType.values)
                  ChoiceChip(
                    label: Text(type.label),
                    selected: filter.type == type,
                    onSelected: (selected) => ref
                        .read(promptFilterProvider.notifier)
                        .setType(selected ? type : null),
                  ),
              ],
            ),
          ),
          if (categories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ChoiceChip(
                    label: const Text('全部分类'),
                    selected: filter.category == null,
                    onSelected: (_) => ref
                        .read(promptFilterProvider.notifier)
                        .setCategory(null),
                  ),
                  for (final category in categories)
                    ChoiceChip(
                      label: Text(category),
                      selected: filter.category == category,
                      onSelected: (selected) => ref
                          .read(promptFilterProvider.notifier)
                          .setCategory(selected ? category : null),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: listAsync.when(
              skipLoadingOnReload: true,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('加载失败：$error')),
              data: (prompts) {
                if (prompts.isEmpty) {
                  return const EmptyState(
                    icon: Icons.auto_awesome_outlined,
                    title: '还没有提示词',
                    hint: '点击右下角「新建」：从模板开始，或用灵感碎片让 AI 生成 3 个风格版本。',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: prompts.length,
                  itemBuilder: (context, index) {
                    final prompt = prompts[index];
                    return _PromptTile(
                      prompt: prompt,
                      onTap: () => _openDetail(prompt.id),
                      onDelete: () => _confirmDelete(prompt),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateMenu,
        icon: const Icon(Icons.add),
        label: const Text('新建'),
      ),
    );
  }
}

class _PromptTile extends StatelessWidget {
  const _PromptTile({
    required this.prompt,
    required this.onTap,
    required this.onDelete,
  });

  final Prompt prompt;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final variableCount = PromptVariable.decode(prompt.variables).length;
    final category = (prompt.category == null || prompt.category!.isEmpty)
        ? '未分类'
        : prompt.category!;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prompt.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${prompt.type.label} · $category · $variableCount 个变量',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        prompt.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  tooltip: '更多操作',
                  onSelected: (action) {
                    if (action == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'delete', child: Text('删除')),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

/// 从模板新建：选类型 → 预填四段式骨架 → 编辑后保存为首版本。
class _PromptCreateDialog extends ConsumerStatefulWidget {
  const _PromptCreateDialog();

  @override
  ConsumerState<_PromptCreateDialog> createState() =>
      _PromptCreateDialogState();
}

class _PromptCreateDialogState extends ConsumerState<_PromptCreateDialog> {
  PromptType _type = PromptType.novel;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  late final TextEditingController _bodyController = TextEditingController(
    text: PromptSkeletonTemplates.byType(_type).render(),
  );

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('标题与正文不能为空')));
      return;
    }
    final category = _categoryController.text.trim();
    await ref
        .read(promptRepositoryProvider)
        .create(
          title: title,
          type: _type,
          body: body,
          category: category.isEmpty ? null : category,
        );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('已保存')));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('从模板新建提示词'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<PromptType>(
                segments: [
                  for (final template in PromptSkeletonTemplates.all)
                    ButtonSegment(
                      value: template.type,
                      label: Text(template.name),
                    ),
                ],
                selected: {_type},
                onSelectionChanged: (selection) => setState(() {
                  _type = selection.first;
                  _bodyController.text = PromptSkeletonTemplates.byType(_type)
                      .render();
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '标题',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: '分类（可选，如：仙侠/人物描写）',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bodyController,
                minLines: 8,
                maxLines: 14,
                decoration: const InputDecoration(
                  labelText: '正文（已按模板预填，可直接修改）',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('保存'),
        ),
      ],
    );
  }
}
