// 灵感详情页（docs/02 B2）：原始/AI 双版本对比（宽屏左右、窄屏上下）、
// 转为提示词草稿 / 转为资料条目（路由参数带 fragmentId）、重新优化（换强度重跑）、
// 编辑原文与删除（无 Key 亦可手动维护，docs/02 B3）。
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/db/database.dart';
import '../../../core/router.dart';
import '../../../shared/empty_state.dart';
import '../../../shared/tag_chip_list.dart';
import '../models/fragment_models.dart';
import '../services/fragment_optimize_task.dart';
import '../services/fragments_controller.dart';
import 'fragment_ui.dart';

class FragmentDetailPage extends ConsumerWidget {
  const FragmentDetailPage({super.key, required this.fragmentId});

  final int fragmentId;

  /// 供路由表接线：从 RouteSettings.arguments 提取 fragmentId。
  /// 用法：case RoutePaths.fragmentDetail:
  ///         return FragmentDetailPage.fromSettings(settings);
  static FragmentDetailPage fromSettings(RouteSettings settings) {
    final args = settings.arguments;
    final id = args is Map ? args[RouteArgs.fragmentId] : null;
    if (id is int) return FragmentDetailPage(fragmentId: id);
    throw ArgumentError('路由 ${settings.name} 缺少整型参数 ${RouteArgs.fragmentId}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 确保灵感优化任务已注册进全局队列（内部含未注入降级）。
    ref.watch(fragmentsTaskBridgeProvider);
    final asyncFragment = ref.watch(fragmentByIdProvider(fragmentId));
    final optimizing = ref
        .watch(fragmentsControllerProvider)
        .isOptimizing(fragmentId);

    return Scaffold(
      appBar: AppBar(title: const Text('灵感详情')),
      body: asyncFragment.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const EmptyState(
          icon: Icons.storage_outlined,
          title: '数据库未初始化',
          hint: '请从应用主入口启动后再使用灵感碎片。',
        ),
        data: (fragment) {
          if (fragment == null) {
            return const EmptyState(
              icon: Icons.delete_outline,
              title: '灵感不存在或已删除',
            );
          }
          return _DetailBody(fragment: fragment, optimizing: optimizing);
        },
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.fragment, required this.optimizing});

  final Fragment fragment;
  final bool optimizing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(fragmentsControllerProvider.notifier);

    ref.listen<FragmentsViewState>(fragmentsControllerProvider, (
      previous,
      next,
    ) {
      final error = next.lastError;
      if (error != null && error != previous?.lastError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error)));
        notifier.clearError();
      }
    });

    final presets = ref.watch(intensityPresetsProvider).value ?? const [];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeaderCard(
              fragment: fragment,
              optimizing: optimizing,
              onReoptimize: () => _showReoptimizeDialog(context, ref, presets),
              onEdit: () => _showEditDialog(context, ref),
              onDelete: () => _confirmDelete(context, ref),
              onToPrompt: () => _pushNamed(context, RoutePaths.promptGenerate),
              onToKbEntry: () => _pushNamed(context, RoutePaths.kbIngest),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final original = _OriginalCard(fragment: fragment);
                final optimized = _OptimizedCard(
                  fragment: fragment,
                  optimizing: optimizing,
                );
                // 宽屏左右对比，窄屏上下堆叠（docs/01 第四节）。
                if (constraints.maxWidth >= 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: original),
                      const SizedBox(width: 12),
                      Expanded(child: optimized),
                    ],
                  );
                }
                return Column(
                  children: [original, const SizedBox(height: 12), optimized],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _pushNamed(BuildContext context, String routeName) {
    Navigator.of(context)
        .pushNamed(routeName, arguments: {RouteArgs.fragmentId: fragment.id});
  }

  Future<void> _showReoptimizeDialog(
    BuildContext context,
    WidgetRef ref,
    List<IntensityPreset> presets,
  ) async {
    if (optimizing) return;
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('选择强度重新优化'),
        children: [
          for (final preset in presets)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(preset.code),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(preset.name),
                subtitle: Text(preset.code),
              ),
            ),
        ],
      ),
    );
    if (code == null) return;
    await ref
        .read(fragmentsControllerProvider.notifier)
        .optimize(fragment.id, intensityCode: code);
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: fragment.rawText);
    final newText = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('编辑原始记录'),
        content: TextField(
          controller: controller,
          minLines: 4,
          maxLines: 10,
          keyboardType: TextInputType.multiline,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newText == null) return;
    final trimmed = newText.trim();
    if (trimmed.isEmpty || trimmed == fragment.rawText) return;
    await ref
        .read(fragmentsControllerProvider.notifier)
        .updateRawText(fragment.id, trimmed);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除这条灵感？'),
        content: const Text('将同时删除由它拆分生成的灵感条目，操作不可撤销。'),
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
    await ref.read(fragmentsControllerProvider.notifier).delete(fragment.id);
    if (context.mounted) Navigator.of(context).pop();
  }
}

/// 头部卡片：状态、元信息、标签与操作按钮。
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.fragment,
    required this.optimizing,
    required this.onReoptimize,
    required this.onEdit,
    required this.onDelete,
    required this.onToPrompt,
    required this.onToKbEntry,
  });

  final Fragment fragment;
  final bool optimizing;
  final VoidCallback onReoptimize;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToPrompt;
  final VoidCallback onToKbEntry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = FragmentAiMeta.tryDecode(fragment.aiMeta);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    fragment.title.isEmpty ? '未命名灵感' : fragment.title,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                fragmentStatusBadge(context, fragment, optimizing: optimizing),
              ],
            ),
            if (optimizing) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
              const SizedBox(height: 4),
              Text('AI 优化中…', style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 8),
            Text(
              '记录于 ${dateFormat.format(fragment.createdAt)}'
              ' · 来源：${fragment.source == FragmentSource.manual ? '手动录入' : 'AI 拆分'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            if (meta != null && fragment.status != FragmentStatus.raw) ...[
              const SizedBox(height: 4),
              Text(
                '模型 ${meta.model.isEmpty ? '-' : meta.model}'
                ' · 强度 ${meta.presetCode}'
                ' · 输入 ${meta.inputTokens} / 输出 ${meta.outputTokens} token'
                ' · ${dateFormat.format(meta.ts)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
            if (decodeTags(fragment.tags).isNotEmpty) ...[
              const SizedBox(height: 8),
              TagChipList(tags: decodeTags(fragment.tags)),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onToPrompt,
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('转为提示词草稿'),
                ),
                OutlinedButton.icon(
                  onPressed: onToKbEntry,
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('转为资料条目'),
                ),
                FilledButton.tonalIcon(
                  onPressed: optimizing ? null : onReoptimize,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重新优化'),
                ),
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('编辑原文'),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('删除'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 原始版本卡片。
class _OriginalCard extends StatelessWidget {
  const _OriginalCard({required this.fragment});

  final Fragment fragment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notes, size: 18),
                const SizedBox(width: 6),
                Text('原始记录', style: theme.textTheme.titleSmall),
              ],
            ),
            const Divider(height: 16),
            SelectableText(
              fragment.rawText,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// AI 整理版本卡片（Markdown 渲染）。
class _OptimizedCard extends StatelessWidget {
  const _OptimizedCard({required this.fragment, required this.optimizing});

  final Fragment fragment;
  final bool optimizing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = FragmentOptimizeItem.tryDecode(fragment.optimizedJson);
    final meta = FragmentAiMeta.tryDecode(fragment.aiMeta);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, size: 18),
                const SizedBox(width: 6),
                Text('AI 整理', style: theme.textTheme.titleSmall),
              ],
            ),
            const Divider(height: 16),
            if (item != null) ...[
              if ((item.context ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '背景：${item.context}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              MarkdownBody(data: item.content),
              if (item.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                TagChipList(tags: item.tags),
              ],
            ] else if (fragment.status == FragmentStatus.failed) ...[
              Text(
                '优化失败：${meta?.error ?? '原因未知'}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '原始记录已保留，可点击「重新优化」换强度再试。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else
              Text(
                optimizing ? 'AI 优化进行中…' : '尚未 AI 优化，可点击「重新优化」发起整理。',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
