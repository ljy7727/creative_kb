import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_setting_keys.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/db/tables.dart';
import '../../../core/router.dart';
import '../../../shared/empty_state.dart';
import '../models/prompt_models.dart';
import '../providers/prompts_providers.dart';
import '../services/prompt_ai_contracts.dart';
import '../widgets/intensity_selector.dart';

/// 从灵感碎片生成提示词：多选碎片 → 选类型与强度 → AI 一次生成
/// 精简/详细/创意 3 个版本 → 三卡对比选择保存（docs/02 模块C）。
class PromptGeneratePage extends ConsumerStatefulWidget {
  const PromptGeneratePage({super.key, this.preselectedFragmentIds});

  /// 从碎片详情「转为提示词草稿」跳入时预选的碎片（RouteArgs.fragmentIds）。
  final List<int>? preselectedFragmentIds;

  /// 供路由表接线（RoutePaths.promptGenerate）。兼容两种预选参数：
  /// RouteArgs.fragmentIds（多选列表）与 RouteArgs.fragmentId（单条，碎片详情跳入）。
  static PromptGeneratePage fromRouteSettings(RouteSettings settings) {
    final args = settings.arguments;
    if (args is! Map) return const PromptGeneratePage();
    final ids = args[RouteArgs.fragmentIds];
    if (ids is List) {
      return PromptGeneratePage(
        preselectedFragmentIds: [
          for (final id in ids)
            if (id is int) id,
        ],
      );
    }
    final single = args[RouteArgs.fragmentId];
    return PromptGeneratePage(
      preselectedFragmentIds: single is int ? [single] : null,
    );
  }

  @override
  ConsumerState<PromptGeneratePage> createState() => _PromptGeneratePageState();
}

class _PromptGeneratePageState extends ConsumerState<PromptGeneratePage> {
  final Set<int> _selectedIds = {};
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  PromptType _type = PromptType.novel;
  String? _intensityCode;
  bool _busy = false;
  List<StyleDraft>? _drafts;
  int _selectedDraft = -1;
  String? _error;

  @override
  void initState() {
    super.initState();
    final preselected = widget.preselectedFragmentIds;
    if (preselected != null) _selectedIds.addAll(preselected);
    _loadDefaultIntensity();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultIntensity() async {
    final db = ref.read(appDatabaseProvider);
    final code = await db.appSettingsDao.get(AppSettingKeys.defaultIntensity);
    if (mounted && _intensityCode == null && code != null) {
      setState(() => _intensityCode = code);
    }
  }

  Future<void> _generate() async {
    final messenger = ScaffoldMessenger.of(context);
    final allFragments =
        ref.read(promptSourceFragmentsProvider).value ?? const [];
    final fragments = allFragments
        .where((fragment) => _selectedIds.contains(fragment.id))
        .toList();
    if (fragments.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('请先选择至少一条灵感碎片')));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _drafts = null;
      _selectedDraft = -1;
    });
    try {
      final drafts = await ref
          .read(promptAiServiceProvider)
          .generateStyleVersions(
            type: _type,
            fragments: fragments,
            intensityCode: _intensityCode ?? 'standard',
          );
      if (!mounted) return;
      setState(() {
        _drafts = drafts;
        _selectedDraft = 0;
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error is PromptAiException ? error.message : 'AI 调用失败：$error';
      });
    }
  }

  Future<void> _save() async {
    final drafts = _drafts;
    if (drafts == null ||
        _selectedDraft < 0 ||
        _selectedDraft >= drafts.length) {
      return;
    }
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请先填写标题')));
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final category = _categoryController.text.trim();
    await ref
        .read(promptRepositoryProvider)
        .create(
          title: title,
          type: _type,
          body: drafts[_selectedDraft].body,
          category: category.isEmpty ? null : category,
        );
    navigator.pop();
    messenger.showSnackBar(const SnackBar(content: Text('已保存到提示词库')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fragmentsAsync = ref.watch(promptSourceFragmentsProvider);
    final presets = ref.watch(intensityPresetsProvider).value ?? const [];
    final aiReady = ref.watch(promptAiReadyProvider).value ?? false;
    final drafts = _drafts;

    return Scaffold(
      appBar: AppBar(title: const Text('从碎片生成提示词')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '选择灵感碎片（已选 ${_selectedIds.length} 条）',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          fragmentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('碎片加载失败：$error'),
            data: (fragments) {
              if (fragments.isEmpty) {
                return const EmptyState(
                  icon: Icons.lightbulb_outline,
                  title: '暂无灵感碎片',
                  hint: '先到「灵感」页录入碎片，再回来生成提示词。',
                );
              }
              return Column(
                children: [
                  for (final fragment in fragments)
                    CheckboxListTile(
                      dense: true,
                      value: _selectedIds.contains(fragment.id),
                      title: Text(
                        fragment.title.isEmpty ? '未命名碎片' : fragment.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        fragment.rawText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onChanged: (checked) => setState(() {
                        if (checked == true) {
                          _selectedIds.add(fragment.id);
                        } else {
                          _selectedIds.remove(fragment.id);
                        }
                      }),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Text('提示词类型', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<PromptType>(
            segments: [
              for (final type in PromptType.values)
                ButtonSegment(value: type, label: Text(type.label)),
            ],
            selected: {_type},
            onSelectionChanged: (selection) =>
                setState(() => _type = selection.first),
          ),
          const SizedBox(height: 16),
          Text('思考强度', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          IntensitySelector(
            presets: presets,
            selectedCode: _intensityCode,
            onChanged: (code) => setState(() => _intensityCode = code),
          ),
          const SizedBox(height: 16),
          Tooltip(
            message: aiReady ? '' : '请先在设置中配置 API Key',
            child: FilledButton.icon(
              onPressed: (_busy || _selectedIds.isEmpty || !aiReady)
                  ? null
                  : _generate,
              icon: const Icon(Icons.auto_awesome),
              label: Text(_busy ? '生成中…' : 'AI 生成 3 个风格版本'),
            ),
          ),
          if (!aiReady) ...[
            const SizedBox(height: 4),
            Text(
              '请先在设置中配置 API Key',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ),
          ],
          if (drafts != null && _selectedDraft >= 0) ...[
            const SizedBox(height: 16),
            Text('选择一个版本保存', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            for (var i = 0; i < drafts.length; i++)
              _DraftCard(
                draft: drafts[i],
                selected: i == _selectedDraft,
                onTap: () => setState(() => _selectedDraft = i),
              ),
            const SizedBox(height: 16),
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
                labelText: '分类（可选）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('保存所选版本'),
            ),
          ],
        ],
      ),
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({
    required this.draft,
    required this.selected,
    required this.onTap,
  });

  final StyleDraft draft;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: selected ? theme.colorScheme.secondaryContainer : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 20,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '风格：${draft.style.label}',
                    style: theme.textTheme.titleSmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SelectableText(
                draft.body,
                maxLines: 8,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
