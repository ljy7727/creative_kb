// 模块B 灵感碎片首页（docs/02 B1/B2/B3）：
// 顶部常驻录入区（多行输入、Enter 换行、Ctrl+Enter 提交、AI 优化复选框、
// 强度选择器、标签快速输入）+ 标签筛选/关键词搜索 + 时间倒序列表。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ProviderException（watch 错误态 provider 时的包装异常）在 misc 导出中。
import 'package:flutter_riverpod/misc.dart';
import 'package:intl/intl.dart';

import '../../../core/db/database.dart';
import '../../../core/router.dart';
import '../../../shared/empty_state.dart';
import '../../../shared/tag_chip_list.dart';
import '../models/fragment_models.dart';
import '../services/fragment_ai_invoker.dart';
import '../services/fragment_optimize_task.dart';
import '../services/fragments_controller.dart';
import 'fragment_ui.dart';

class FragmentsPage extends ConsumerStatefulWidget {
  const FragmentsPage({super.key});

  @override
  ConsumerState<FragmentsPage> createState() => _FragmentsPageState();
}

class _FragmentsPageState extends ConsumerState<FragmentsPage> {
  final _textController = TextEditingController();
  final _tagsController = TextEditingController();
  final _searchController = TextEditingController();
  bool _useAi = true;
  String? _intensityCode;

  @override
  void dispose() {
    _textController.dispose();
    _tagsController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// 解析标签快输：逗号/分号/空白分隔。
  List<String> _parseTags(String input) => input
      .split(RegExp(r'[,，;；\s]+'))
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toList();

  /// 当前生效强度：用户选择 > 全局默认 > 第一项 > standard。
  String _resolveIntensity(List<IntensityPreset> presets, String defaultCode) {
    final codes = presets.map((p) => p.code).toSet();
    final chosen = _intensityCode;
    if (chosen != null && codes.contains(chosen)) return chosen;
    if (codes.contains(defaultCode)) return defaultCode;
    if (presets.isNotEmpty) return presets.first.code;
    return 'standard';
  }

  Future<void> _submit() async {
    final view = ref.read(fragmentsControllerProvider);
    if (!view.dbReady) return;
    final notifier = ref.read(fragmentsControllerProvider.notifier);
    final presets = ref.read(intensityPresetsProvider).value ?? const [];
    final defaultCode = ref.read(defaultIntensityProvider).value ?? 'standard';
    // AI 不可用时即使复选框残留勾选也只做手动保存（复选框此时应已置灰）。
    final aiContext = ref.read(optimizeAiContextProvider);
    final useAi = _useAi && aiContext.hasValue && aiContext.value != null;

    final saved = await notifier.submit(
      text: _textController.text,
      useAi: useAi,
      intensityCode: _resolveIntensity(presets, defaultCode),
      tags: _parseTags(_tagsController.text),
    );
    if (saved && mounted) {
      _textController.clear();
      _tagsController.clear();
      if (!useAi) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('灵感已保存')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 确保灵感优化任务已注册进全局队列（内部含未注入降级）。
    ref.watch(fragmentsTaskBridgeProvider);
    final view = ref.watch(fragmentsControllerProvider);
    final presetsAsync = ref.watch(intensityPresetsProvider);
    final defaultIntensity =
        ref.watch(defaultIntensityProvider).value ?? 'standard';
    final aiContext = ref.watch(optimizeAiContextProvider);

    ref.listen<FragmentsViewState>(fragmentsControllerProvider, (
      previous,
      next,
    ) {
      final error = next.lastError;
      if (error != null && error != previous?.lastError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error)));
        ref.read(fragmentsControllerProvider.notifier).clearError();
      }
    });

    final presets = presetsAsync.value ?? const [];
    final aiDisabledReason = _aiDisabledReason(aiContext);
    final visible = filterFragments(view.fragments, view.filter);
    final allTags = collectTags(view.fragments);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _EntryCard(
                  textController: _textController,
                  tagsController: _tagsController,
                  useAi: _useAi,
                  onUseAiChanged: (value) => setState(() => _useAi = value),
                  aiEnabled: aiDisabledReason == null,
                  aiDisabledReason: aiDisabledReason,
                  presets: presets,
                  selectedIntensity: _resolveIntensity(
                    presets,
                    defaultIntensity,
                  ),
                  onIntensityChanged: (code) =>
                      setState(() => _intensityCode = code),
                  onSubmit: _submit,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _FilterBar(
                  searchController: _searchController,
                  onKeywordChanged: ref
                      .read(fragmentsControllerProvider.notifier)
                      .setKeyword,
                  selectedTag: view.filter.tag,
                  allTags: allTags,
                  onTagSelected: (tag) => ref
                      .read(fragmentsControllerProvider.notifier)
                      .setTagFilter(tag),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: !view.dbReady
                    ? const EmptyState(
                        icon: Icons.storage_outlined,
                        title: '数据库未初始化',
                        hint: '请从应用主入口启动后再使用灵感碎片。',
                      )
                    : view.fragments.isEmpty
                    ? const EmptyState(
                        icon: Icons.lightbulb_outline,
                        title: '还没有灵感记录',
                        hint: '在上方随手记下第一条灵感；勾选「AI 优化后保存」可自动纠错、提炼并打标签。',
                      )
                    : visible.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off,
                        title: '没有符合筛选条件的灵感',
                        hint: '试试清除标签筛选或更换关键词。',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: visible.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final fragment = visible[index];
                          return _FragmentCard(
                            fragment: fragment,
                            optimizing: view.isOptimizing(fragment.id),
                            dateFormat: dateFormat,
                            onOpen: () => _openDetail(fragment.id),
                            onTagTap: (tag) => ref
                                .read(fragmentsControllerProvider.notifier)
                                .setTagFilter(tag),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(int fragmentId) {
    Navigator.of(context).pushNamed(
      RoutePaths.fragmentDetail,
      arguments: {RouteArgs.fragmentId: fragmentId},
    );
  }

  String? _aiDisabledReason(AsyncValue<OptimizeAiContext?> aiContext) {
    return aiContext.when(
      data: (context) => context == null ? aiNotConfiguredMessage : null,
      loading: () => 'AI 配置加载中…',
      error: (error, _) {
        // 数据库未注入时 AsyncError 里是 ProviderException 包装，剥壳归类。
        var cause = error;
        if (cause is ProviderException) cause = cause.exception;
        if (cause is UnimplementedError) return '数据库未初始化，AI 不可用';
        return 'AI 暂不可用：$cause';
      },
    );
  }
}

/// 录入卡片（docs/02 B1）。
class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.textController,
    required this.tagsController,
    required this.useAi,
    required this.onUseAiChanged,
    required this.aiEnabled,
    required this.aiDisabledReason,
    required this.presets,
    required this.selectedIntensity,
    required this.onIntensityChanged,
    required this.onSubmit,
  });

  final TextEditingController textController;
  final TextEditingController tagsController;
  final bool useAi;
  final ValueChanged<bool> onUseAiChanged;
  final bool aiEnabled;
  final String? aiDisabledReason;
  final List<IntensityPreset> presets;
  final String selectedIntensity;
  final ValueChanged<String> onIntensityChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('记录灵感', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            CallbackShortcuts(
              bindings: {
                // Enter 换行保持默认行为，Ctrl+Enter 提交（docs/02 B1）。
                const SingleActivator(LogicalKeyboardKey.enter, control: true):
                    onSubmit,
                const SingleActivator(
                  LogicalKeyboardKey.numpadEnter,
                  control: true,
                ): onSubmit,
              },
              child: TextField(
                controller: textController,
                minLines: 3,
                maxLines: 6,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  hintText: '随手记下灵感，Enter 换行，Ctrl+Enter 提交',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Tooltip(
                  message: aiDisabledReason ?? '',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: useAi,
                        onChanged: aiEnabled
                            ? (value) => onUseAiChanged(value ?? false)
                            : null,
                      ),
                      const Text('AI 优化后保存'),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('强度', style: theme.textTheme.bodyMedium),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: presets.any((p) => p.code == selectedIntensity)
                          ? selectedIntensity
                          : null,
                      hint: const Text('选择强度'),
                      items: [
                        for (final preset in presets)
                          DropdownMenuItem(
                            value: preset.code,
                            child: Text(preset.name),
                          ),
                      ],
                      onChanged: (code) {
                        if (code != null) onIntensityChanged(code);
                      },
                    ),
                  ],
                ),
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: tagsController,
                    decoration: const InputDecoration(
                      hintText: '标签（逗号/空格分隔，可空）',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: onSubmit,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('保存灵感'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 标签筛选 + 关键词搜索（docs/02 B2）。
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.searchController,
    required this.onKeywordChanged,
    required this.selectedTag,
    required this.allTags,
    required this.onTagSelected,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onKeywordChanged;
  final String? selectedTag;
  final List<String> allTags;
  final ValueChanged<String?> onTagSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                onChanged: onKeywordChanged,
                decoration: const InputDecoration(
                  hintText: '搜索标题或原文',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            if (selectedTag != null) ...[
              const SizedBox(width: 8),
              Chip(
                label: Text(selectedTag!),
                onDeleted: () => onTagSelected(null),
              ),
            ],
          ],
        ),
        if (allTags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                ChoiceChip(
                  label: const Text('全部'),
                  selected: selectedTag == null,
                  onSelected: (_) => onTagSelected(null),
                ),
                for (final tag in allTags)
                  ChoiceChip(
                    label: Text(tag),
                    selected: selectedTag == tag,
                    onSelected: (selected) =>
                        onTagSelected(selected ? tag : null),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 列表卡片。
class _FragmentCard extends StatelessWidget {
  const _FragmentCard({
    required this.fragment,
    required this.optimizing,
    required this.dateFormat,
    required this.onOpen,
    required this.onTagTap,
  });

  final Fragment fragment;
  final bool optimizing;
  final DateFormat dateFormat;
  final VoidCallback onOpen;
  final ValueChanged<String> onTagTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      fragment.title.isEmpty ? '未命名灵感' : fragment.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  fragmentStatusBadge(
                    context,
                    fragment,
                    optimizing: optimizing,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                fragment.rawText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    dateFormat.format(fragment.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TagChipList(
                      tags: decodeTags(fragment.tags),
                      maxVisible: 4,
                      onTagTap: onTagTap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
