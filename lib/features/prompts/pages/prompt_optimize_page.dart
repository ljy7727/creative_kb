import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_setting_keys.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/router.dart';
import '../../../shared/empty_state.dart';
import '../models/prompt_models.dart';
import '../providers/prompts_providers.dart';
import '../services/prompt_ai_contracts.dart';
import '../widgets/intensity_selector.dart';

/// 定向优化：四方向（精简压缩/扩写丰富/适配特定模型/风格转换）→
/// 新版本入 prompt_versions 并前移 currentVersionId（docs/02 模块C）。
class PromptOptimizePage extends ConsumerStatefulWidget {
  const PromptOptimizePage({super.key, required this.promptId});

  final int promptId;

  /// 供路由表接线（RoutePaths.promptOptimize）：参数取 RouteArgs.promptId。
  static PromptOptimizePage fromRouteSettings(RouteSettings settings) {
    final args = settings.arguments;
    final id = args is Map ? args[RouteArgs.promptId] : null;
    return PromptOptimizePage(promptId: id is int ? id : 0);
  }

  @override
  ConsumerState<PromptOptimizePage> createState() => _PromptOptimizePageState();
}

class _PromptOptimizePageState extends ConsumerState<PromptOptimizePage> {
  OptimizeDirection _direction = OptimizeDirection.condense;
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _styleController = TextEditingController();

  String? _intensityCode;
  bool _busy = false;
  OptimizeResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDefaultIntensity();
  }

  @override
  void dispose() {
    _modelController.dispose();
    _styleController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultIntensity() async {
    final db = ref.read(appDatabaseProvider);
    final code = await db.appSettingsDao.get(AppSettingKeys.defaultIntensity);
    if (mounted && _intensityCode == null && code != null) {
      setState(() => _intensityCode = code);
    }
  }

  Future<void> _run(String body) async {
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await ref
          .read(promptAiServiceProvider)
          .optimize(
            body: body,
            direction: _direction,
            targetModel: _direction.needsTargetModel
                ? _modelController.text
                : null,
            targetStyle: _direction.needsTargetStyle
                ? _styleController.text
                : null,
            intensityCode: _intensityCode ?? 'standard',
          );
      if (!mounted) return;
      setState(() {
        _result = result;
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

  Future<void> _save(OptimizeResult result) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final repository = ref.read(promptRepositoryProvider);
    final note = '${_direction.label}：${result.note ?? '已按方向优化'}';
    await repository.saveNewVersion(
      promptId: widget.promptId,
      body: result.body,
      note: note,
    );
    navigator.pop();
    messenger.showSnackBar(const SnackBar(content: Text('已保存为新版本，可在详情页回滚')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final promptAsync = ref.watch(promptDetailProvider(widget.promptId));
    final presets = ref.watch(intensityPresetsProvider).value ?? const [];
    final aiReady = ref.watch(promptAiReadyProvider).value ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('定向优化提示词')),
      body: promptAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('加载失败：$error')),
        data: (prompt) {
          if (prompt == null) {
            return const EmptyState(
              icon: Icons.search_off,
              title: '提示词不存在或已删除',
            );
          }
          final result = _result;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('当前正文预览', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    prompt.body,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('优化方向', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final direction in OptimizeDirection.values)
                    ChoiceChip(
                      label: Text(direction.label),
                      selected: _direction == direction,
                      onSelected: (_) => setState(() => _direction = direction),
                    ),
                ],
              ),
              if (_direction.needsTargetModel) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _modelController,
                  decoration: const InputDecoration(
                    labelText: '目标模型名（如 deepseek-chat）',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              if (_direction.needsTargetStyle) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _styleController,
                  decoration: const InputDecoration(
                    labelText: '目标风格（如：古风典雅 / 简洁口语）',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
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
                  onPressed: (_busy || !aiReady)
                      ? null
                      : () => _run(prompt.body),
                  icon: const Icon(Icons.auto_fix_high),
                  label: Text(_busy ? '优化中…' : 'AI 定向优化'),
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
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
              ],
              if (result != null) ...[
                const SizedBox(height: 16),
                Text('优化结果', style: theme.textTheme.titleSmall),
                if (result.note != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    result.note!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(
                      result.body,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _save(result),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('保存为新版本'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
