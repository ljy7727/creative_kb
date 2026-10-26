// 资料库「AI 搜集」页：输入主题 → DeepSeek 联网搜索/抓取 → 结构化 → 转入库预览。
// 需要已配置 DeepSeek 厂商（/v1/tools/search、/v1/tools/fetch 仅 DeepSeek 提供）。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_setting_keys.dart';
import '../../../core/db/database.dart';
import '../services/kb_ingest_task.dart';
import '../services/kb_providers.dart';
import '../services/kb_research_service.dart';
import 'kb_ingest_wizard_page.dart';

class KbResearchPage extends ConsumerStatefulWidget {
  const KbResearchPage({super.key});

  @override
  ConsumerState<KbResearchPage> createState() => _KbResearchPageState();
}

class _KbResearchPageState extends ConsumerState<KbResearchPage> {
  final _topicController = TextEditingController();
  String? _intensityCode;
  bool _fetchPages = false;
  bool _running = false;
  bool _cancelRequested = false;
  String _stage = '';
  String? _error;
  KbResearchOutcome? _outcome;

  @override
  void initState() {
    super.initState();
    _loadDefaultIntensity();
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultIntensity() async {
    try {
      final db = ref.read(kbDbProvider);
      if (db == null) return;
      final code = await db.appSettingsDao.get(AppSettingKeys.defaultIntensity);
      final resolved = (code == null || code.isEmpty) ? 'standard' : code;
      if (mounted) setState(() => _intensityCode ??= resolved);
    } catch (_) {
      if (mounted) setState(() => _intensityCode ??= 'standard');
    }
  }

  IntensityParams _currentPreset(List<IntensityPreset> presets) {
    for (final preset in presets) {
      if (preset.code == _intensityCode) {
        return IntensityParams.fromPreset(preset);
      }
    }
    for (final preset in presets) {
      if (preset.code == 'standard') return IntensityParams.fromPreset(preset);
    }
    return const IntensityParams(code: 'standard');
  }

  Future<void> _run() async {
    if (_running) return;
    setState(() {
      _running = true;
      _cancelRequested = false;
      _error = null;
      _outcome = null;
      _stage = '准备中…';
    });
    try {
      final presets =
          ref.read(intensityPresetsStreamProvider).value ??
          const <IntensityPreset>[];
      final service = ref.read(kbResearchServiceProvider);
      final outcome = await service.run(
        topic: _topicController.text,
        intensity: _currentPreset(presets),
        fetchPages: _fetchPages,
        isCancelled: () => _cancelRequested,
        onStage: (stage) {
          if (mounted) setState(() => _stage = stage);
        },
      );
      if (!mounted) return;
      setState(() {
        _running = false;
        _stage = '';
        _outcome = outcome;
        // 用户主动取消不算错误：只提示已取消，已收集部分照常展示。
        _error = outcome.cancelled ? null : outcome.error;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _running = false;
        _stage = '';
        _error = '搜集失败：$e';
      });
    }
  }

  void _openIngestPreview() {
    final result = _outcome?.ingest?.result;
    if (result == null) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => KbIngestWizardPage(
          initialText: _topicController.text.trim(),
          precomputed: result,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final presets =
        ref.watch(intensityPresetsStreamProvider).value ??
        const <IntensityPreset>[];
    final aiAvailable = ref.watch(kbAiAvailableProvider).value ?? false;
    final hasStructured = _outcome?.ingest?.result != null;
    return Scaffold(
      appBar: AppBar(title: const Text('AI 搜集资料')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '输入主题，AI 会联网检索并自动整理成标准条目',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '使用 DeepSeek 的 Search / Fetch 能力收集资料，再按资料库 Schema '
                    '结构化，进入入库预览后由你确认保存。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _topicController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: '搜集主题',
              hintText: '例如：唐朝五品官员的服饰、俸禄与上朝礼仪',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _intensityCode,
                  decoration: const InputDecoration(
                    labelText: '思考强度',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    for (final preset in presets)
                      DropdownMenuItem(
                        value: preset.code,
                        child: Text(preset.name),
                      ),
                  ],
                  onChanged: _running
                      ? null
                      : (code) => setState(() => _intensityCode = code),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('抓取网页正文'),
                  subtitle: const Text('搜索摘要通常够用；需要全文再开'),
                  value: _fetchPages,
                  onChanged: _running
                      ? null
                      : (value) => setState(() => _fetchPages = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _running
                    ? OutlinedButton.icon(
                        onPressed: () => setState(() => _cancelRequested = true),
                        icon: const Icon(Icons.stop_circle_outlined),
                        label: const Text('取消'),
                      )
                    : FilledButton.icon(
                        onPressed: aiAvailable ? _run : null,
                        icon: const Icon(Icons.travel_explore),
                        label: const Text('开始搜集'),
                      ),
              ),
            ],
          ),
          if (!aiAvailable)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '请先在设置中配置 DeepSeek 的 API Key 并启用模型；'
                'AI 搜集的搜索/抓取仅 DeepSeek 厂商支持。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          if (_running) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text(_stage, style: theme.textTheme.bodySmall),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Card(
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
          if (_outcome != null && !hasStructured) ...[
            const SizedBox(height: 16),
            _SearchSummary(outcome: _outcome!),
          ],
          if (hasStructured) ...[
            const SizedBox(height: 16),
            _ResultCard(
              outcome: _outcome!,
              onPreview: _openIngestPreview,
            ),
          ],
        ],
      ),
    );
  }
}

/// 搜索完成但结构化失败时的资料摘要（完整列出，便于换主题重试或手动粘贴）。
class _SearchSummary extends StatelessWidget {
  const _SearchSummary({required this.outcome});

  final KbResearchOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '已收集 ${outcome.items.length} 条资料'
              '（检索词 ${outcome.queries.length} 个，抓取正文 ${outcome.fetchedPages} 页）',
              style: theme.textTheme.titleSmall,
            ),
            if (outcome.queries.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '检索词：${outcome.queries.join('、')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const Divider(height: 16),
            // 全部条目逐行展示；页面本身是 ListView，可滚动查看全部。
            for (final item in outcome.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.isEmpty ? '（无标题）' : item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      [
                        if (item.siteName.isNotEmpty) item.siteName,
                        item.url,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 结构化成功卡片：条目统计 + 进入预览入库。
class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.outcome, required this.onPreview});

  final KbResearchOutcome outcome;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = outcome.ingest!.result!;
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('整理完成：${result.entries.length} 个条目', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '资料 ${outcome.items.length} 条 · 抓取正文 ${outcome.fetchedPages} 页 · '
              '建议分类「${result.proposedCategory}」',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onPreview,
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('去预览入库'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
