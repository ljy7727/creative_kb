import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/db/app_setting_keys.dart';
import '../../../core/db/database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/router.dart';
import '../../../shared/empty_state.dart';
import '../models/prompt_models.dart';
import '../providers/prompts_providers.dart';
import '../services/prompt_ai_contracts.dart';
import '../services/prompt_variables.dart';
import '../widgets/intensity_selector.dart';
import '../widgets/variable_fill_dialog.dart';
import 'prompt_optimize_page.dart';

/// 提示词详情：正文、变量面板（填值复制/提取）、版本历史与一键回滚、编辑、定向优化入口。
class PromptDetailPage extends ConsumerWidget {
  const PromptDetailPage({super.key, required this.promptId});

  final int promptId;

  /// 供路由表接线（RoutePaths.promptDetail）：参数取 RouteArgs.promptId。
  static PromptDetailPage fromRouteSettings(RouteSettings settings) {
    final args = settings.arguments;
    final id = args is Map ? args[RouteArgs.promptId] : null;
    return PromptDetailPage(promptId: id is int ? id : 0);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promptAsync = ref.watch(promptDetailProvider(promptId));
    return promptAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('加载失败：$error')),
      ),
      data: (prompt) {
        if (prompt == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(icon: Icons.search_off, title: '提示词不存在或已删除'),
          );
        }
        return _PromptDetailView(prompt: prompt);
      },
    );
  }
}

class _PromptDetailView extends ConsumerWidget {
  const _PromptDetailView({required this.prompt});

  final Prompt prompt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final versionsAsync = ref.watch(promptVersionsProvider(prompt.id));
    final aiReady = ref.watch(promptAiReadyProvider).value ?? false;
    final variables = resolveVariables(
      variablesJson: prompt.variables,
      body: prompt.body,
    );
    final category = (prompt.category == null || prompt.category!.isEmpty)
        ? null
        : prompt.category;

    return Scaffold(
      appBar: AppBar(
        title: Text(prompt.title),
        actions: [
          IconButton(
            tooltip: '删除',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              Chip(
                label: Text(prompt.type.label),
                visualDensity: VisualDensity.compact,
              ),
              if (category != null)
                Chip(
                  label: Text(category),
                  visualDensity: VisualDensity.compact,
                ),
              if (prompt.currentVersionId != null)
                Chip(
                  label: Text('当前版本 #${prompt.currentVersionId}'),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _openEditor(context, ref),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('编辑'),
              ),
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      settings: const RouteSettings(
                        name: RoutePaths.promptOptimize,
                      ),
                      builder: (_) => PromptOptimizePage(promptId: prompt.id),
                    ),
                  );
                },
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('定向优化'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => VariableFillDialog(
                      body: prompt.body,
                      variables: variables,
                    ),
                  );
                },
                icon: const Icon(Icons.content_copy_outlined),
                label: const Text('填充变量并复制'),
              ),
              Tooltip(
                message: aiReady ? '' : '请先在设置中配置 API Key',
                child: OutlinedButton.icon(
                  onPressed: aiReady
                      ? () => _extractVariables(context, ref)
                      : null,
                  icon: const Icon(Icons.psychology_outlined),
                  label: const Text('提取变量'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: '变量（${variables.length}）',
            child: variables.isEmpty
                ? Text(
                    '暂无变量。正文中的可变信息可手动写成 {{变量名}}，或点「提取变量」让 AI 分析。',
                    style: theme.textTheme.bodySmall,
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final variable in variables)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '{{${variable.name}}}',
                                style: theme.textTheme.labelLarge,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  variable.desc.isEmpty
                                      ? '（未填写说明）'
                                      : variable.desc,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: '正文',
            child: SelectableText(
              prompt.body,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: '版本历史',
            child: versionsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Text('版本加载失败：$error'),
              data: (versions) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final version in versions)
                    _VersionTile(
                      version: version,
                      isCurrent: version.id == prompt.currentVersionId,
                      onView: () => _showVersion(context, version),
                      onRollback: () =>
                          _rollback(context, ref, prompt, version),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final repository = ref.read(promptRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
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
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await repository.remove(prompt.id);
    messenger.showSnackBar(const SnackBar(content: Text('已删除')));
    navigator.pop();
  }

  void _openEditor(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => _PromptEditDialog(prompt: prompt),
    );
  }

  Future<void> _extractVariables(BuildContext context, WidgetRef ref) async {
    final repository = ref.read(promptRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<VariablesExtractResult>(
      context: context,
      builder: (_) => _ExtractVariablesDialog(body: prompt.body),
    );
    if (result == null) return;
    await repository.saveNewVersion(
      promptId: prompt.id,
      body: result.annotatedBody,
      note: '变量提取（${result.variables.length} 个）',
      variables: result.variables,
    );
    messenger.showSnackBar(
      SnackBar(content: Text('已标注 ${result.variables.length} 个变量并保存为新版本')),
    );
  }

  void _showVersion(BuildContext context, PromptVersion version) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('版本 #${version.id}'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(child: SelectableText(version.body)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 回滚 = 目标版本内容落为新版本（历史全保留），指针前移（docs/02 模块C）。
  Future<void> _rollback(
    BuildContext context,
    WidgetRef ref,
    Prompt prompt,
    PromptVersion version,
  ) async {
    final repository = ref.read(promptRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('回滚版本'),
        content: Text('将回滚到版本 #${version.id}；当前内容会作为新版本保留在历史中。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('回滚'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await repository.rollbackToVersion(
      promptId: prompt.id,
      versionId: version.id,
    );
    messenger.showSnackBar(SnackBar(content: Text('已回滚到版本 #${version.id}')));
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _VersionTile extends StatelessWidget {
  const _VersionTile({
    required this.version,
    required this.isCurrent,
    required this.onView,
    required this.onRollback,
  });

  final PromptVersion version;
  final bool isCurrent;
  final VoidCallback onView;
  final VoidCallback onRollback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = DateFormat('yyyy-MM-dd HH:mm').format(version.createdAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isCurrent ? Icons.check_circle : Icons.history,
            size: 20,
            color: isCurrent
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${version.id} · $time${isCurrent ? ' · 当前' : ''}',
                  style: theme.textTheme.labelMedium,
                ),
                Text(
                  version.note ?? version.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onView, child: const Text('查看')),
          if (!isCurrent)
            TextButton(onPressed: onRollback, child: const Text('回滚')),
        ],
      ),
    );
  }
}

/// 编辑：标题/分类（元信息）+ 正文（变化则落新版本，note=手动编辑）。
class _PromptEditDialog extends ConsumerStatefulWidget {
  const _PromptEditDialog({required this.prompt});

  final Prompt prompt;

  @override
  ConsumerState<_PromptEditDialog> createState() => _PromptEditDialogState();
}

class _PromptEditDialogState extends ConsumerState<_PromptEditDialog> {
  late final TextEditingController _titleController = TextEditingController(
    text: widget.prompt.title,
  );
  late final TextEditingController _categoryController = TextEditingController(
    text: widget.prompt.category ?? '',
  );
  late final TextEditingController _bodyController = TextEditingController(
    text: widget.prompt.body,
  );

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final repository = ref.read(promptRepositoryProvider);
    final prompt = widget.prompt;
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('标题与正文不能为空')));
      return;
    }
    final category = _categoryController.text.trim();
    if (body != prompt.body) {
      await repository.saveNewVersion(
        promptId: prompt.id,
        body: body,
        note: '手动编辑',
        variables: PromptVariable.decode(prompt.variables),
      );
    }
    final titleChanged = title != prompt.title;
    final categoryChanged = category != (prompt.category ?? '');
    if (titleChanged || categoryChanged) {
      await repository.updateMeta(
        promptId: prompt.id,
        title: titleChanged ? title : null,
        category: categoryChanged ? category : null, // 空串表示清空分类
      );
    }
    navigator.pop();
    messenger.showSnackBar(const SnackBar(content: Text('已保存')));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑提示词'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                  labelText: '分类（清空表示「未分类」）',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bodyController,
                minLines: 8,
                maxLines: 14,
                decoration: const InputDecoration(
                  labelText: '正文（修改后保存为新版本）',
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

/// 变量提取：选强度 → AI 分析 → 返回结果（标注落库由详情页完成）。
class _ExtractVariablesDialog extends ConsumerStatefulWidget {
  const _ExtractVariablesDialog({required this.body});

  final String body;

  @override
  ConsumerState<_ExtractVariablesDialog> createState() =>
      _ExtractVariablesDialogState();
}

class _ExtractVariablesDialogState
    extends ConsumerState<_ExtractVariablesDialog> {
  String? _intensityCode;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDefaultIntensity();
  }

  Future<void> _loadDefaultIntensity() async {
    final db = ref.read(appDatabaseProvider);
    final code = await db.appSettingsDao.get(AppSettingKeys.defaultIntensity);
    if (mounted && _intensityCode == null && code != null) {
      setState(() => _intensityCode = code);
    }
  }

  Future<void> _run() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // invoker 未接线时在此抛 UnimplementedError，同样落入下方用户可见错误。
      final result = await ref
          .read(promptAiServiceProvider)
          .extractVariables(
            body: widget.body,
            intensityCode: _intensityCode ?? 'standard',
          );
      navigator.pop(result);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _error = error is PromptAiException ? error.message : 'AI 调用失败：$error';
      });
      messenger.showSnackBar(SnackBar(content: Text(_error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final presets = ref.watch(intensityPresetsProvider).value ?? const [];
    return AlertDialog(
      title: const Text('提取变量'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI 将分析正文中的可变信息，并标注为 {{变量名}}，保存为新版本。'),
            const SizedBox(height: 12),
            const Text('思考强度'),
            const SizedBox(height: 4),
            IntensitySelector(
              presets: presets,
              selectedCode: _intensityCode,
              onChanged: (code) => setState(() => _intensityCode = code),
            ),
            if (_busy) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton.icon(
          onPressed: _busy ? null : _run,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('开始提取'),
        ),
      ],
    );
  }
}
