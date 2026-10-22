import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_setting_keys.dart';
import '../../../core/db/database.dart';
import '../../../core/tasks/task_runner_provider.dart';
import '../../../shared/empty_state.dart';
import '../models/kb_ingest_models.dart';
import '../models/kb_schema.dart';
import '../services/kb_entry_service.dart';
import '../services/kb_ingest_task.dart';
import '../services/kb_providers.dart';
import '../services/kb_vector_task.dart';
import '../widgets/kb_widgets.dart';

/// 五步入库向导（docs/02 D2）：输入 → AI 清洗+分类 → 校验映射 → 预览确认 → 入库。
/// 极速入库模式（设置项 kb.quick_ingest）开启时跳过预览步。
/// 路由接线（集成收尾）：`RoutePaths.kbIngest` → KbIngestWizardPage，
/// 参数支持 `{RouteArgs.fragmentId: int}`（从碎片转入并预填原文）或
/// `{'initialText': String}`（直接预填文本）。
class KbIngestWizardPage extends ConsumerStatefulWidget {
  const KbIngestWizardPage({
    super.key,
    this.initialText,
    this.fragmentId,
    this.precomputed,
  });

  final String? initialText;
  final int? fragmentId;

  /// AI 搜集等前置管线已产出的结构化结果；非空时跳过输入/AI 步，
  /// 直接进入「校验映射」（用户仍可修改分类/字段后预览入库）。
  final KbIngestResult? precomputed;

  @override
  ConsumerState<KbIngestWizardPage> createState() => _KbIngestWizardPageState();
}

/// 待入库草稿（向导内流转的数据载体）。
class _Draft {
  _Draft({
    required this.entryName,
    required this.categoryPath,
    required this.schemaId,
    required this.contentMd,
    this.summary = '',
    this.tags = const <String>[],
    this.related = const <String>[],
    this.credibility,
    this.extra = const <String, Object?>{},
  });

  bool include = true;
  String entryName;
  String categoryPath;
  String schemaId;
  String summary;
  String contentMd;
  List<String> tags;
  List<String> related;
  Credibility? credibility;
  Map<String, Object?> extra;
}

enum _Step { input, ai, mapping, preview, ingest }

class _KbIngestWizardPageState extends ConsumerState<KbIngestWizardPage> {
  _Step _step = _Step.input;
  final _textController = TextEditingController();
  String? _intensityCode;
  bool _aiUsed = false;

  bool _aiRunning = false;
  String? _aiError;

  final List<_Draft> _drafts = <_Draft>[];

  bool _ingesting = false;
  bool _done = false;
  int _created = 0;
  bool _vectorQueued = false;
  String? _finishNote;
  String? _ingestError;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialText;
    if (initial != null && initial.isNotEmpty) {
      _textController.text = initial;
    }
    final fragmentId = widget.fragmentId;
    if (fragmentId != null) {
      _loadFragment(fragmentId);
    }
    final precomputed = widget.precomputed;
    if (precomputed != null) {
      _aiUsed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyPrecomputed(precomputed);
      });
    }
    _loadDefaultIntensity();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadFragment(int fragmentId) async {
    try {
      final db = ref.read(kbDbProvider);
      if (db == null) return;
      final fragment = await db.fragmentsDao.byId(fragmentId);
      if (fragment == null || !mounted) return;
      if (_textController.text.isEmpty) {
        setState(() => _textController.text = fragment.rawText);
      }
    } catch (_) {
      // 碎片不存在/库不可用时保持空输入。
    }
  }

  Future<void> _loadDefaultIntensity() async {
    try {
      final db = ref.read(kbDbProvider);
      if (db == null) return;
      final code = await db.appSettingsDao.get(AppSettingKeys.defaultIntensity);
      if (code != null && mounted && _intensityCode == null) {
        setState(() => _intensityCode = code);
      }
    } catch (_) {}
  }

  // ———— 步骤 2：AI 清洗+分类 ————

  Future<void> _runAi() async {
    if (_aiRunning) return;
    setState(() {
      _aiRunning = true;
      _aiError = null;
    });
    try {
      final task = ref.read(kbIngestTaskProvider);
      final presets =
          ref.read(intensityPresetsStreamProvider).value ??
          const <IntensityPreset>[];
      final preset = _currentPreset(presets);
      final outcome = await task.run(
        rawText: _textController.text,
        intensity: preset,
      );
      if (!mounted) return;
      if (outcome.result != null) {
        await _applyResult(outcome.result!);
        if (!mounted) return;
        setState(() {
          _aiRunning = false;
          _aiUsed = true;
          _step = _Step.mapping;
        });
        return;
      }
      setState(() {
        _aiRunning = false;
        _aiError = outcome.error ?? '整理失败，请重试';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiRunning = false;
        _aiError = '整理失败：$e';
      });
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

  Future<void> _applyResult(KbIngestResult result) async {
    final schemas = await ref.read(schemaRegistryProvider.future);
    final schemaId =
        schemaById(schemas, result.proposedSchemaId)?.id ??
        KbSchema.generalSchemaId;
    _drafts
      ..clear()
      ..addAll([
        for (final entry in result.entries)
          _Draft(
            entryName: entry.entryName,
            categoryPath:
                (entry.categoryPath != null &&
                    entry.categoryPath!.trim().isNotEmpty)
                ? entry.categoryPath!.trim()
                : result.proposedCategory,
            schemaId: schemaId,
            summary: entry.summary,
            contentMd: entry.contentMd,
            tags: entry.tags,
            related: entry.related,
            credibility: credibilityFromName(entry.credibility),
            extra: Map<String, Object?>.of(entry.extra),
          ),
      ]);
  }

  /// 外部管线（AI 搜集）预置结果：跳过输入/AI 步，直接进入校验映射。
  Future<void> _applyPrecomputed(KbIngestResult result) async {
    try {
      await _applyResult(result);
      if (!mounted) return;
      setState(() => _step = _Step.mapping);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiError = '载入结构化结果失败：$e';
        _step = _Step.ai;
      });
    }
  }

  /// 无 AI 时的手动整理：单条草稿，原文作正文，分类「未分类」，Schema 按关键词建议。
  Future<void> _manualDraft() async {
    final schemas = await ref.read(schemaRegistryProvider.future);
    final schema = suggestSchemaFor(schemas, _textController.text);
    setState(() {
      _drafts
        ..clear()
        ..add(
          _Draft(
            entryName: '未命名条目',
            categoryPath: '未分类',
            schemaId: schema.id,
            contentMd: _textController.text,
          ),
        );
      _aiUsed = false;
      _step = _Step.mapping;
    });
  }

  // ———— 文件导入 ————

  Future<void> _pickFile() async {
    try {
      // file_picker 13.x：静态 pickFile，单文件选择；本地文件读 path，否则读字节。
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['txt', 'md'],
      );
      if (file == null) return;
      final path = file.path;
      final text = path != null
          ? await File(path).readAsString()
          : utf8.decode(await file.readAsBytes(), allowMalformed: true);
      if (!mounted) return;
      setState(() => _textController.text = text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('读取文件失败：$e')));
    }
  }

  // ———— 校验 ————

  List<String> _validateDraft(_Draft draft, List<KbSchema> schemas) {
    final issues = <String>[];
    if (draft.entryName.trim().isEmpty) issues.add('条目名称不能为空');
    final schema = schemaById(schemas, draft.schemaId);
    if (schema == null) {
      issues.add('未知 Schema：${draft.schemaId}');
    } else {
      issues.addAll(schema.validateExtra(draft.extra));
    }
    return issues;
  }

  List<String> _allMappingIssues(List<KbSchema> schemas) {
    final issues = <String>[];
    final nameCount = <String, int>{};
    for (final draft in _drafts) {
      if (!draft.include) continue;
      final name = draft.entryName.trim();
      nameCount[name] = (nameCount[name] ?? 0) + 1;
      final prefix = name.isEmpty ? '未命名条目' : '「$name」';
      issues.addAll(_validateDraft(draft, schemas).map((s) => '$prefix：$s'));
    }
    final duplicates = [
      for (final e in nameCount.entries)
        if (e.value > 1) e.key,
    ];
    if (duplicates.isNotEmpty) issues.add('条目名重复：${duplicates.join('、')}');
    return issues;
  }

  // ———— 步骤 5：入库 ————

  Future<void> _confirmIngest() async {
    if (_ingesting) return;
    setState(() {
      _ingesting = true;
      _ingestError = null;
    });
    try {
      final schemas = await ref.read(schemaRegistryProvider.future);
      final included = _drafts.where((d) => d.include).toList();
      if (included.isEmpty) {
        setState(() {
          _ingesting = false;
          _ingestError = '没有勾选任何条目';
        });
        return;
      }
      final inputs = <KbEntryInput>[];
      for (final draft in included) {
        final issues = _validateDraft(draft, schemas);
        if (issues.isNotEmpty) {
          setState(() {
            _ingesting = false;
            _ingestError = '「${draft.entryName}」校验未通过：${issues.join('；')}';
          });
          return;
        }
        inputs.add(
          KbEntryInput(
            entryName: draft.entryName.trim(),
            categoryPath: draft.categoryPath.trim().isEmpty
                ? '未分类'
                : draft.categoryPath.trim(),
            tags: draft.tags,
            summary: draft.summary,
            contentMd: draft.contentMd,
            extra: _normalizeExtra(draft, schemas),
            related: draft.related,
            source: _aiUsed ? 'ai' : 'manual',
            credibility: draft.credibility,
          ),
        );
      }
      final report = await ref
          .read(kbEntryServiceProvider)
          .createEntries(inputs);

      // 可选向量化：配置了嵌入模型才入队（失败不阻塞入库，docs/02 D2）。
      // 统一经全局 TaskRunner 处理（bridge 注册的 kb_embed 处理器），
      // 避免与 runner 的遗留任务恢复重复处理同一行。
      var vectorQueued = false;
      var vectorNote = '未配置嵌入模型，跳过向量化（条目将标记「未向量化」）';
      final config = await ref.read(embeddingConfigProvider.future);
      var aiReady = false;
      try {
        aiReady = await ref.read(kbAiAvailableProvider.future);
      } catch (_) {
        aiReady = false;
      }
      if (config != null && aiReady) {
        ref.read(kbQueueBridgeProvider); // 注册 kb_embed 处理器（副作用桥）
        final runner = ref.read(taskRunnerProvider);
        var failed = 0;
        for (final id in report.entryIds) {
          final taskId = await runner.enqueue(
            module: KbVectorTaskService.module,
            taskType: KbVectorTaskService.taskType,
            payload: {'entryId': id, 'model': config.model},
          );
          final row = await runner.whenFinished(taskId);
          if (row.status == QueueTaskStatus.success) {
            vectorQueued = true;
          } else {
            failed++;
          }
        }
        vectorNote = failed == 0
            ? '已向量化 ${report.entryIds.length} 条，可参与语义检索'
            : '向量化 $failed 条失败（不影响入库），可稍后在条目页重试';
      }
      if (!mounted) return;
      setState(() {
        _ingesting = false;
        _done = true;
        _created = report.entryIds.length;
        _pendingRelated
          ..clear()
          ..addAll(report.pendingRelated);
        _vectorQueued = vectorQueued;
        _finishNote = vectorNote;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ingesting = false;
        _ingestError = '入库失败：$e';
      });
    }
  }

  /// 入库前归一化扩展字段：number 字段文本转数字、空串删除（编辑器里都是字符串）。
  Map<String, Object?> _normalizeExtra(_Draft draft, List<KbSchema> schemas) {
    final extra = Map<String, Object?>.of(draft.extra);
    final schema = schemaById(schemas, draft.schemaId);
    if (schema == null) return extra;
    for (final field in schema.fields) {
      final value = extra[field.key];
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) {
          extra.remove(field.key);
        } else if (field.type == KbSchemaFieldType.number) {
          final parsed = num.tryParse(trimmed);
          if (parsed != null) extra[field.key] = parsed;
        } else {
          extra[field.key] = trimmed;
        }
      }
    }
    return extra;
  }

  final List<String> _pendingRelated = <String>[];

  // ———— 构建 ————

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(kbDbProvider);
    if (db == null) {
      return const Scaffold(
        body: EmptyState(icon: Icons.storage_outlined, title: '数据库尚未初始化'),
      );
    }
    final quickIngest = ref.watch(quickIngestProvider).value ?? false;
    final schemasAsync = ref.watch(schemaRegistryProvider);
    final schemas = schemasAsync.value ?? const <KbSchema>[];
    final categories =
        ref.watch(kbCategoriesStreamProvider).value ?? const <KbCategory>[];
    final presets =
        ref.watch(intensityPresetsStreamProvider).value ??
        const <IntensityPreset>[];
    final aiAvailable = (ref.watch(kbAiAvailableProvider).value ?? false);

    return Scaffold(
      appBar: AppBar(title: const Text('资料入库向导')),
      body: Column(
        children: [
          _WizardStepper(current: _step),
          const Divider(height: 1),
          Expanded(child: _body(schemas, categories, presets, aiAvailable)),
          const Divider(height: 1),
          _bottomBar(quickIngest, schemas),
        ],
      ),
    );
  }

  Widget _body(
    List<KbSchema> schemas,
    List<KbCategory> categories,
    List<IntensityPreset> presets,
    bool aiAvailable,
  ) {
    switch (_step) {
      case _Step.input:
        return _inputBody();
      case _Step.ai:
        return _aiBody(aiAvailable, presets);
      case _Step.mapping:
        if (schemas.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return _mappingBody(schemas, categories);
      case _Step.preview:
        return _previewBody();
      case _Step.ingest:
        return _ingestBody();
    }
  }

  Widget _inputBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('第 1 步：输入资料', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            '粘贴文本，或导入一个 TXT/MD 文件。从灵感碎片转入时已自动预填。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            maxLines: 14,
            minLines: 8,
            decoration: const InputDecoration(
              hintText: '把原始资料粘贴到这里……',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('导入 TXT / MD 文件'),
              ),
              _IntensityDropdown(
                presets:
                    ref.watch(intensityPresetsStreamProvider).value ?? const [],
                value: _intensityCode,
                onChanged: (code) => setState(() => _intensityCode = code),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _aiBody(bool aiAvailable, List<IntensityPreset> presets) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '第 2 步：AI 清洗 + 分类',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'AI 将去除冗余、拆分多主题、按分类树与 Schema 建议结构与字段；输出仍需在第 3 步确认与修改。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          _IntensityDropdown(
            presets: presets,
            value: _intensityCode,
            onChanged: (code) => setState(() => _intensityCode = code),
          ),
          const SizedBox(height: 12),
          if (_aiRunning)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('正在清洗与分类，请稍候……'),
                  ],
                ),
              ),
            )
          else ...[
            if (_aiError != null)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_aiError!)),
                    ],
                  ),
                ),
              ),
            if (_drafts.isNotEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text('已有 ${_drafts.length} 条待确认草稿'),
                  subtitle: const Text('可直接进入第 3 步，或重新整理'),
                ),
              ),
            const SizedBox(height: 8),
            Tooltip(
              message: aiAvailable ? '使用已配置的模型清洗、拆分并建议分类' : '请先在设置中配置 API Key',
              child: FilledButton.icon(
                onPressed: aiAvailable ? _runAi : null,
                icon: const Icon(Icons.auto_fix_high_outlined),
                label: const Text('AI 清洗并分类'),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _manualDraft,
              icon: const Icon(Icons.edit_note_outlined),
              label: const Text('跳过 AI，手动整理'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _mappingBody(List<KbSchema> schemas, List<KbCategory> categories) {
    final categoryPaths = [for (final c in categories) c.path];
    final issues = _allMappingIssues(schemas);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '第 3 步：校验映射（可修改分类与字段）',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '分类路径不存在会自动逐级创建；带 * 为 Schema 必填字段。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < _drafts.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DraftCard(
                    key: ValueKey(_drafts[i]),
                    index: i,
                    draft: _drafts[i],
                    schemas: schemas,
                    categories: categoryPaths,
                    issues: _drafts[i].include
                        ? _validateDraft(_drafts[i], schemas)
                        : const <String>[],
                    onChanged: (_) => setState(() {}),
                    onRemove: () => setState(() => _drafts.removeAt(i)),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _drafts.add(
                    _Draft(
                      entryName: '',
                      categoryPath: '未分类',
                      schemaId: schemas.first.id,
                      contentMd: '',
                    ),
                  );
                }),
                icon: const Icon(Icons.add),
                label: const Text('手动加一条'),
              ),
            ],
          ),
        ),
        if (issues.isNotEmpty)
          Material(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                issues.join('\n'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _previewBody() {
    final included = _drafts.where((d) => d.include).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('第 4 步：预览确认', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          '以下条目将写入资料库，可在此修改正文与概述。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < included.length; i++)
          _PreviewCard(
            key: ValueKey('preview_${included[i].entryName}_$i'),
            draft: included[i],
            onEdit: () => _editPreviewDraft(included[i]),
          ),
      ],
    );
  }

  Future<void> _editPreviewDraft(_Draft draft) async {
    final summaryCtrl = TextEditingController(text: draft.summary);
    final contentCtrl = TextEditingController(text: draft.contentMd);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('编辑：${draft.entryName}'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: summaryCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: '概述',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: contentCtrl,
                maxLines: 12,
                decoration: const InputDecoration(
                  labelText: '正文（Markdown）',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    final newSummary = summaryCtrl.text;
    final newContent = contentCtrl.text;
    summaryCtrl.dispose();
    contentCtrl.dispose();
    if (saved == true && mounted) {
      setState(() {
        draft.summary = newSummary;
        draft.contentMd = newContent;
      });
    }
  }

  Widget _ingestBody() {
    if (_done) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 56,
                color: Colors.green,
              ),
              const SizedBox(height: 12),
              Text('入库完成', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                '成功入库 $_created 条。',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (_pendingRelated.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '待创建关联（库内暂无对应条目名）：',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  _pendingRelated.join('；'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _vectorQueued ? Icons.check_circle : Icons.info_outline,
                    size: 16,
                    color: _vectorQueued ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _finishNote ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('完成'),
              ),
            ],
          ),
        ),
      );
    }
    final includedCount = _drafts.where((d) => d.include).length;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('第 5 步：入库', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text('将写入 $includedCount 条条目：自动创建分类、建立双向关联、同步全文索引。'),
            const SizedBox(height: 6),
            Text(
              '若已配置嵌入模型，入库后自动向量化入队；未匹配到的关联名将标记为「待创建」。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            if (_ingestError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _ingestError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            FilledButton.icon(
              onPressed: _ingesting ? null : _confirmIngest,
              icon: _ingesting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('确认入库'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(bool quickIngest, List<KbSchema> schemas) {
    Widget? primary;
    var enabled = true;
    switch (_step) {
      case _Step.input:
        primary = FilledButton(
          onPressed: _textController.text.trim().isEmpty
              ? null
              : () => setState(() => _step = _Step.ai),
          child: const Text('下一步：AI 清洗'),
        );
        break;
      case _Step.ai:
        primary = null; // 按钮在步骤体内
        break;
      case _Step.mapping:
        enabled = _allMappingIssues(schemas).isEmpty;
        primary = FilledButton(
          onPressed: enabled
              ? () => setState(
                  () => _step = quickIngest ? _Step.ingest : _Step.preview,
                )
              : null,
          child: Text(quickIngest ? '下一步（极速入库）' : '下一步：预览'),
        );
        break;
      case _Step.preview:
        primary = FilledButton(
          onPressed: () => setState(() => _step = _Step.ingest),
          child: const Text('下一步：入库'),
        );
        break;
      case _Step.ingest:
        primary = null;
        break;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          if (_step != _Step.input && !_done)
            OutlinedButton(
              onPressed: () => setState(() {
                switch (_step) {
                  case _Step.ai:
                    _step = _Step.input;
                    break;
                  case _Step.mapping:
                    _step = _Step.ai;
                    break;
                  case _Step.preview:
                    _step = _Step.mapping;
                    break;
                  case _Step.ingest:
                    _step = quickIngest ? _Step.mapping : _Step.preview;
                    break;
                  case _Step.input:
                    break;
                }
              }),
              child: const Text('上一步'),
            ),
          const Spacer(),
          ?primary,
        ],
      ),
    );
  }
}

/// 步骤进度头（1-5）。
class _WizardStepper extends StatelessWidget {
  const _WizardStepper({required this.current});

  final _Step current;

  static const _labels = <String>['输入', 'AI 清洗', '校验映射', '预览确认', '入库'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentIndex = _Step.values.indexOf(current);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          for (var i = 0; i < _labels.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Divider(
                  color: i <= currentIndex
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                ),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 11,
                  backgroundColor: i <= currentIndex
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  child: Text(
                    '${i + 1}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: i <= currentIndex
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _labels[i],
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: i == currentIndex ? FontWeight.bold : null,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// 强度选择器（docs/02 A4：所有 AI 发起处均有强度选择器，默认取设置的全局默认）。
class _IntensityDropdown extends StatelessWidget {
  const _IntensityDropdown({
    required this.presets,
    required this.value,
    required this.onChanged,
  });

  final List<IntensityPreset> presets;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    IntensityPreset? current;
    for (final preset in presets) {
      if (preset.code == value) current = preset;
    }
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<String>(
        initialValue: current?.code,
        decoration: const InputDecoration(
          labelText: '思考强度',
          isDense: true,
          border: OutlineInputBorder(),
        ),
        items: [
          for (final preset in presets)
            DropdownMenuItem(value: preset.code, child: Text(preset.name)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

/// 校验映射卡片：控制器持有输入，变更回写 draft 并触发父级重校验。
class _DraftCard extends ConsumerStatefulWidget {
  const _DraftCard({
    super.key,
    required this.index,
    required this.draft,
    required this.schemas,
    required this.categories,
    required this.issues,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final _Draft draft;
  final List<KbSchema> schemas;
  final List<String> categories;
  final List<String> issues;
  final ValueChanged<_Draft> onChanged;
  final VoidCallback onRemove;

  @override
  ConsumerState<_DraftCard> createState() => _DraftCardState();
}

class _DraftCardState extends ConsumerState<_DraftCard> {
  late final TextEditingController _name = TextEditingController(
    text: widget.draft.entryName,
  );
  late final TextEditingController _category = TextEditingController(
    text: widget.draft.categoryPath,
  );
  late final TextEditingController _summary = TextEditingController(
    text: widget.draft.summary,
  );
  late final TextEditingController _content = TextEditingController(
    text: widget.draft.contentMd,
  );
  late final TextEditingController _tags = TextEditingController(
    text: widget.draft.tags.join('，'),
  );
  late final TextEditingController _related = TextEditingController(
    text: widget.draft.related.join('，'),
  );
  Map<String, TextEditingController> _extraCtrls = {};

  @override
  void initState() {
    super.initState();
    _syncExtraCtrls();
  }

  @override
  void didUpdateWidget(covariant _DraftCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draft.schemaId != widget.draft.schemaId) {
      _syncExtraCtrls();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _summary.dispose();
    _content.dispose();
    _tags.dispose();
    _related.dispose();
    for (final ctrl in _extraCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _syncExtraCtrls() {
    final schema = schemaById(widget.schemas, widget.draft.schemaId);
    final old = _extraCtrls;
    _extraCtrls = {
      for (final field in schema?.fields ?? const <KbSchemaField>[])
        field.key:
            old[field.key] ??
            (TextEditingController(
              text: '${widget.draft.extra[field.key] ?? ''}',
            )..addListener(() {
              widget.draft.extra[field.key] =
                  _extraCtrls[field.key]?.text ?? '';
              widget.onChanged(widget.draft);
            })),
    };
    for (final key in old.keys) {
      if (!_extraCtrls.containsKey(key)) old[key]!.dispose();
    }
  }

  void _update(void Function(_Draft) mutate) {
    mutate(widget.draft);
    widget.onChanged(widget.draft);
  }

  Future<void> _pickCategory() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final path in widget.categories)
              ListTile(
                title: Text(path),
                onTap: () => Navigator.of(sheetContext).pop(path),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      _category.text = picked;
      _update((d) => d.categoryPath = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final theme = Theme.of(context);
    final schema = schemaById(widget.schemas, draft.schemaId);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Checkbox(
                  value: draft.include,
                  onChanged: (v) => _update((d) => d.include = v ?? true),
                ),
                Text(
                  '条目 ${widget.index + 1}',
                  style: theme.textTheme.titleSmall,
                ),
                const Spacer(),
                IconButton(
                  tooltip: '移除该条目',
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: '条目名称 *',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => _update((d) => d.entryName = v),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _category,
                    decoration: const InputDecoration(
                      labelText: '分类路径（不存在将自动创建）',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => _update((d) => d.categoryPath = v),
                  ),
                ),
                IconButton(
                  tooltip: '选择已有分类',
                  onPressed: _pickCategory,
                  icon: const Icon(Icons.account_tree_outlined),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: schema?.id,
              decoration: const InputDecoration(
                labelText: '适用 Schema',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: [
                for (final s in widget.schemas)
                  DropdownMenuItem(
                    value: s.id,
                    child: Text('${s.name}（${s.id}）'),
                  ),
              ],
              onChanged: (v) {
                if (v != null) _update((d) => d.schemaId = v);
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _summary,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '概述',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => _update((d) => d.summary = v),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _content,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: '正文（Markdown）',
                alignLabelWithHint: true,
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => _update((d) => d.contentMd = v),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _tags,
              decoration: const InputDecoration(
                labelText: '标签（中文逗号分隔）',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => _update((d) => d.tags = splitNames(v)),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _related,
              decoration: const InputDecoration(
                labelText: '关联条目（名称，逗号分隔；未匹配的入库后显示为待创建）',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => _update((d) => d.related = splitNames(v)),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<Credibility?>(
              initialValue: draft.credibility,
              decoration: const InputDecoration(
                labelText: '可信度',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem<Credibility?>(value: null, child: Text('未标注')),
                DropdownMenuItem<Credibility?>(
                  value: Credibility.high,
                  child: Text('高'),
                ),
                DropdownMenuItem<Credibility?>(
                  value: Credibility.mid,
                  child: Text('中'),
                ),
                DropdownMenuItem<Credibility?>(
                  value: Credibility.low,
                  child: Text('低'),
                ),
              ],
              onChanged: (v) => _update((d) => d.credibility = v),
            ),
            if (schema != null && schema.fields.isNotEmpty) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '扩展字段（${schema.name}）',
                  style: theme.textTheme.labelLarge,
                ),
              ),
              for (final field in schema.fields)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: KbSchemaFieldEditor(
                    field: field,
                    controller: _extraCtrls[field.key],
                  ),
                ),
            ],
            if (widget.issues.isNotEmpty) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.issues.map((s) => '⚠ $s').join('\n'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 预览确认卡片（Markdown 渲染，docs/02 D2 第4步）。
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({super.key, required this.draft, required this.onEdit});

  final _Draft draft;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    draft.entryName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '编辑',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  InputChip(
                    label: Text(draft.categoryPath),
                    visualDensity: VisualDensity.compact,
                    onPressed: null,
                  ),
                  CredibilityBadge(credibility: draft.credibility),
                  for (final tag in draft.tags)
                    InputChip(
                      label: Text(tag),
                      visualDensity: VisualDensity.compact,
                      onPressed: null,
                    ),
                ],
              ),
            ),
            if (draft.summary.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(draft.summary, style: theme.textTheme.bodySmall),
                ),
              ),
            const Divider(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: MarkdownBody(data: draft.contentMd),
            ),
          ],
        ),
      ),
    );
  }
}
