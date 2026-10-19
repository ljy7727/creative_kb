import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/tasks/task_runner_provider.dart';
import '../../../shared/empty_state.dart';
import '../models/kb_schema.dart';
import '../services/kb_entry_service.dart';
import '../services/kb_providers.dart';
import '../services/kb_vector_task.dart';
import '../widgets/kb_widgets.dart';

/// 条目详情页（docs/02 D4）：Markdown 渲染、扩展字段表格、双向关联跳转、
/// 编辑（按 Schema 校验）、删除（连带清理 relations/embeddings/FTS）、
/// 「未向量化」标记与手动补向量。
/// 路由接线（集成收尾）：`RoutePaths.kbEntryDetail` →
/// `KbEntryDetailPage(entryId: (args as Map)[RouteArgs.entryId] as int)`。
class KbEntryDetailPage extends ConsumerStatefulWidget {
  const KbEntryDetailPage({super.key, required this.entryId});

  final int entryId;

  @override
  ConsumerState<KbEntryDetailPage> createState() => _KbEntryDetailPageState();
}

class _KbEntryDetailPageState extends ConsumerState<KbEntryDetailPage> {
  bool _editing = false;

  // —— 编辑态（进入编辑时才创建控制器）。
  TextEditingController? _nameCtrl;
  TextEditingController? _categoryCtrl;
  TextEditingController? _summaryCtrl;
  TextEditingController? _contentCtrl;
  TextEditingController? _tagsCtrl;
  TextEditingController? _relatedCtrl;
  Map<String, TextEditingController> _extraCtrls = {};
  Credibility? _credibility;
  String? _schemaId;

  @override
  void dispose() {
    _disposeEditControllers();
    super.dispose();
  }

  void _disposeEditControllers() {
    _nameCtrl?.dispose();
    _categoryCtrl?.dispose();
    _summaryCtrl?.dispose();
    _contentCtrl?.dispose();
    _tagsCtrl?.dispose();
    _relatedCtrl?.dispose();
    for (final ctrl in _extraCtrls.values) {
      ctrl.dispose();
    }
    _extraCtrls = {};
  }

  void _beginEdit(KbEntry entry, List<KbSchema> schemas) {
    _disposeEditControllers();
    final extra = decodeJsonObject(entry.extra);
    final suggested = suggestSchemaFor(
      schemas,
      '${entry.entryName}\n${entry.summary}\n${entry.contentMd}',
    );
    final known = schemaById(schemas, suggested.id);
    _schemaId = known?.id;
    _extraCtrls = {
      for (final field in known?.fields ?? const <KbSchemaField>[])
        field.key: TextEditingController(text: '${extra[field.key] ?? ''}'),
    };
    _nameCtrl = TextEditingController(text: entry.entryName);
    _categoryCtrl = TextEditingController(text: entry.categoryPath);
    _summaryCtrl = TextEditingController(text: entry.summary);
    _contentCtrl = TextEditingController(text: entry.contentMd);
    _tagsCtrl = TextEditingController(
      text: decodeStringList(entry.tags).join('，'),
    );
    _relatedCtrl = TextEditingController(
      text: decodeStringList(entry.related).join('，'),
    );
    _credibility = entry.credibility;
    setState(() => _editing = true);
  }

  void _endEdit() {
    _disposeEditControllers();
    if (mounted) setState(() => _editing = false);
  }

  Future<void> _save(KbEntry entry) async {
    final name = _nameCtrl?.text.trim() ?? '';
    if (name.isEmpty) {
      _toast('条目名称不能为空');
      return;
    }
    final schemas = await ref.read(schemaRegistryProvider.future);
    final schema = _schemaId == null ? null : schemaById(schemas, _schemaId!);
    // Schema 字段外的原有扩展键原样保留（编辑不丢数据）。
    final extra = <String, Object?>{...decodeJsonObject(entry.extra)};
    if (schema != null) {
      for (final field in schema.fields) {
        final text = _extraCtrls[field.key]?.text.trim() ?? '';
        if (text.isEmpty) {
          extra.remove(field.key);
        } else {
          extra[field.key] = field.type == KbSchemaFieldType.number
              ? (num.tryParse(text) ?? text)
              : text;
        }
      }
      final issues = schema.validateExtra(extra);
      if (issues.isNotEmpty) {
        _toast('校验未通过：${issues.join('；')}');
        return;
      }
    }
    final tags = splitNames(_tagsCtrl?.text);
    final related = splitNames(_relatedCtrl?.text);
    final updated = entry.copyWith(
      entryName: name,
      categoryPath: _categoryCtrl?.text.trim() ?? entry.categoryPath,
      summary: _summaryCtrl?.text ?? entry.summary,
      contentMd: _contentCtrl?.text ?? entry.contentMd,
      tags: jsonEncode(tags),
      extra: jsonEncode(extra),
      credibility: Value(_credibility),
      updatedAt: DateTime.now(),
    );
    try {
      final pending = await ref
          .read(kbEntryServiceProvider)
          .updateEntry(updated, related: related);
      _endEdit();
      _toast(pending.isEmpty ? '已保存' : '已保存；待创建关联：${pending.join('、')}');
    } catch (e) {
      _toast('保存失败：$e');
    }
  }

  Future<void> _confirmDelete(KbEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除条目'),
        content: Text('确定删除「${entry.entryName}」？将连带清理其双向关联、向量数据与全文索引，不可恢复。'),
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
    try {
      await ref.read(kbEntryServiceProvider).deleteEntry(widget.entryId);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      _toast('删除失败：$e');
    }
  }

  Future<void> _vectorizeNow(KbEntry entry) async {
    final config = await ref.read(embeddingConfigProvider.future);
    var aiReady = false;
    try {
      aiReady = await ref.read(kbAiAvailableProvider.future);
    } catch (_) {
      aiReady = false;
    }
    if (config == null || !aiReady) {
      _toast('请先在设置中配置 API Key 与嵌入模型');
      return;
    }
    try {
      // 统一经全局 TaskRunner 处理（与入库向导一致，避免重复消费任务行）。
      ref.read(kbQueueBridgeProvider); // 注册 kb_embed 处理器（副作用桥）
      final runner = ref.read(taskRunnerProvider);
      final taskId = await runner.enqueue(
        module: KbVectorTaskService.module,
        taskType: KbVectorTaskService.taskType,
        payload: {'entryId': entry.id, 'model': config.model},
      );
      final row = await runner.whenFinished(taskId);
      _toast(row.status == QueueTaskStatus.success ? '向量化完成' : '向量化失败，可稍后重试');
    } catch (e) {
      _toast('向量化失败：$e');
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(kbDbProvider);
    if (db == null) {
      return const Scaffold(body: Center(child: Text('数据库尚未初始化')));
    }
    final entries = ref.watch(kbEntriesStreamProvider).value;
    if (entries == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    KbEntry? entry;
    for (final item in entries) {
      if (item.id == widget.entryId) {
        entry = item;
        break;
      }
    }
    if (entry == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('条目详情')),
        body: EmptyState(
          icon: Icons.person_off_outlined,
          title: '条目不存在',
          hint: '可能已被删除。',
          actionLabel: '返回',
          onAction: () => Navigator.of(context).pop(),
        ),
      );
    }
    final current = entry;

    final schemasAsync = ref.watch(schemaRegistryProvider);
    final schemas = schemasAsync.value ?? const <KbSchema>[];
    final editSchema = _editing && _schemaId != null
        ? schemaById(schemas, _schemaId!)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? '编辑条目' : current.entryName),
        actions: [
          if (!_editing) ...[
            IconButton(
              tooltip: '编辑',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _beginEdit(current, schemas),
            ),
            IconButton(
              tooltip: '删除',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(current),
            ),
          ] else ...[
            TextButton(onPressed: _endEdit, child: const Text('取消')),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: () => _save(current),
                child: const Text('保存'),
              ),
            ),
          ],
        ],
      ),
      body: _editing
          ? _EditForm(
              entry: current,
              schemas: schemas,
              schema: editSchema,
              nameCtrl: _nameCtrl!,
              categoryCtrl: _categoryCtrl!,
              summaryCtrl: _summaryCtrl!,
              contentCtrl: _contentCtrl!,
              tagsCtrl: _tagsCtrl!,
              relatedCtrl: _relatedCtrl!,
              extraCtrls: _extraCtrls,
              credibility: _credibility,
              schemaId: editSchema?.id,
              onPickCategory: _pickCategory,
              onSchemaChanged: (id) => _changeEditSchema(current, schemas, id),
              onCredibilityChanged: (value) =>
                  setState(() => _credibility = value),
            )
          : _ViewBody(
              entry: current,
              onVectorize: () => _vectorizeNow(current),
            ),
    );
  }

  Future<void> _pickCategory() async {
    final categories =
        ref.read(kbCategoriesStreamProvider).value ?? const <KbCategory>[];
    if (!mounted) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final category in categories)
              ListTile(
                title: Text(category.path),
                onTap: () => Navigator.of(sheetContext).pop(category.path),
              ),
          ],
        ),
      ),
    );
    if (picked != null) _categoryCtrl?.text = picked;
  }

  void _changeEditSchema(KbEntry entry, List<KbSchema> schemas, String? id) {
    setState(() {
      _schemaId = id;
      final extra = decodeJsonObject(entry.extra);
      final next = id == null ? null : schemaById(schemas, id);
      final oldCtrls = _extraCtrls;
      _extraCtrls = {
        for (final field in next?.fields ?? const <KbSchemaField>[])
          field.key:
              oldCtrls[field.key] ??
              TextEditingController(text: '${extra[field.key] ?? ''}'),
      };
      for (final key in oldCtrls.keys) {
        if (!_extraCtrls.containsKey(key)) oldCtrls[key]!.dispose();
      }
    });
  }
}

/// 只读视图：概览 / Markdown 正文 / 扩展字段表 / 双向关联 / 向量化状态。
class _ViewBody extends ConsumerStatefulWidget {
  const _ViewBody({required this.entry, required this.onVectorize});

  final KbEntry entry;
  final Future<void> Function() onVectorize;

  @override
  ConsumerState<_ViewBody> createState() => _ViewBodyState();
}

class _ViewBodyState extends ConsumerState<_ViewBody> {
  late Future<List<KbEntry>> _relatedFuture;
  Future<EntryEmbedding?>? _vectorFuture;
  int _vectorFutureKey = -1;
  int _reloadTick = 0;

  @override
  void initState() {
    super.initState();
    _reloadRelated();
  }

  @override
  void didUpdateWidget(covariant _ViewBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.id != widget.entry.id ||
        oldWidget.entry.updatedAt != widget.entry.updatedAt) {
      _reloadRelated();
    }
  }

  void _reloadRelated() {
    _relatedFuture = ref
        .read(kbEntryServiceProvider)
        .relatedEntriesOf(widget.entry.id);
  }

  /// 向量化状态按 (entryId, reloadTick) 记忆，避免每次 build 重建 Future 闪加载。
  Future<EntryEmbedding?> _vectorFutureFor(int entryId, int tick) {
    final db = ref.read(kbDbProvider)!;
    final key = entryId * 1000003 + tick;
    if (key != _vectorFutureKey) {
      _vectorFuture = db.embeddingsDao.byEntry(entryId);
      _vectorFutureKey = key;
    }
    return _vectorFuture!;
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final schemas =
        ref.watch(schemaRegistryProvider).value ?? const <KbSchema>[];
    final schema = _guessSchema(schemas, entry);
    final extra = decodeJsonObject(entry.extra);
    final vectorizedFuture = _vectorFutureFor(entry.id, _reloadTick);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderCard(entry: entry),
          if (entry.summary.isNotEmpty) ...[
            const SizedBox(height: 12),
            KbSectionCard(title: '概述', child: Text(entry.summary)),
          ],
          if (entry.contentMd.isNotEmpty) ...[
            const SizedBox(height: 12),
            KbSectionCard(
              title: '正文',
              child: MarkdownBody(data: entry.contentMd),
            ),
          ],
          if (extra.isNotEmpty) ...[
            const SizedBox(height: 12),
            KbSectionCard(
              title: '扩展字段',
              child: _ExtraTable(extra: extra, schema: schema),
            ),
          ],
          const SizedBox(height: 12),
          KbSectionCard(
            title: '双向关联',
            trailing: IconButton(
              tooltip: '刷新',
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: () => setState(() {
                _reloadTick++;
                _reloadRelated();
              }),
            ),
            child: FutureBuilder<List<KbEntry>>(
              key: ValueKey('related_${entry.id}_$_reloadTick'),
              future: _relatedFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                final linked = snapshot.data ?? const <KbEntry>[];
                final linkedNames = linked.map((e) => e.entryName).toSet();
                final pending = decodeStringList(entry.related)
                    .where(
                      (n) => n.trim().isNotEmpty && !linkedNames.contains(n),
                    )
                    .toSet()
                    .toList();
                return RelatedEntriesChips(
                  linked: linked,
                  pendingNames: pending,
                  onNavigate: (target) => navigateToKbEntry(context, target.id),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          KbSectionCard(
            title: '语义向量',
            child: FutureBuilder<EntryEmbedding?>(
              key: ValueKey('vec_${entry.id}_$_reloadTick'),
              future: vectorizedFuture,
              builder: (context, snapshot) {
                final embeddingAvailable =
                    ref.watch(embeddingConfigProvider).value != null &&
                    (ref.watch(kbAiAvailableProvider).value ?? false);
                if (!embeddingAvailable) {
                  return Text(
                    '未配置嵌入模型，跳过向量化；配置后条目可向量化并参与语义检索。',
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                }
                final row = snapshot.data;
                if (row != null) {
                  return const Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green),
                      SizedBox(width: 6),
                      Text('已向量化，可参与语义检索'),
                    ],
                  );
                }
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '未向量化',
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: Colors.orange.shade900),
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton.icon(
                      onPressed: () async {
                        await widget.onVectorize();
                        if (mounted) setState(() => _reloadTick++);
                      },
                      icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                      label: const Text('立即向量化'),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 按扩展字段 key 覆盖度推断条目适用的 Schema（kb_entries 不存 schema 列）。
  static KbSchema? _guessSchema(List<KbSchema> schemas, KbEntry entry) {
    if (schemas.isEmpty) return null;
    final extra = decodeJsonObject(entry.extra);
    KbSchema? best;
    var bestHits = -1;
    for (final schema in schemas) {
      var hits = 0;
      for (final field in schema.fields) {
        if (extra.containsKey(field.key)) hits++;
      }
      if (hits > bestHits) {
        best = schema;
        bestHits = hits;
      }
    }
    return bestHits > 0 ? best : null;
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.entry});

  final KbEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tags = decodeStringList(entry.tags);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.entryName, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                InputChip(
                  avatar: const Icon(Icons.folder_outlined, size: 16),
                  label: Text(entry.categoryPath),
                  visualDensity: VisualDensity.compact,
                  onPressed: null,
                ),
                CredibilityBadge(credibility: entry.credibility),
                if (entry.source != null)
                  Text('来源：${entry.source}', style: theme.textTheme.labelSmall),
              ],
            ),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('标签：${tags.join(' · ')}', style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

/// 详情/向导共用的分组卡片。
class KbSectionCard extends StatelessWidget {
  const KbSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _ExtraTable extends StatelessWidget {
  const _ExtraTable({required this.extra, required this.schema});

  final Map<String, Object?> extra;
  final KbSchema? schema;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Table(
      columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
      border: TableBorder.symmetric(
        inside: BorderSide(color: theme.dividerColor, width: 0.5),
      ),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        for (final key in extra.keys)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Text(
                  schema?.fieldByKey(key)?.label ?? key,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Text('${extra[key]}', style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
      ],
    );
  }
}

/// 编辑表单（与入库向导第3步同款控件语义，docs/02 D2 第3步）。
class _EditForm extends StatelessWidget {
  const _EditForm({
    required this.entry,
    required this.schemas,
    required this.schema,
    required this.nameCtrl,
    required this.categoryCtrl,
    required this.summaryCtrl,
    required this.contentCtrl,
    required this.tagsCtrl,
    required this.relatedCtrl,
    required this.extraCtrls,
    required this.credibility,
    required this.schemaId,
    required this.onPickCategory,
    required this.onSchemaChanged,
    required this.onCredibilityChanged,
  });

  final KbEntry entry;
  final List<KbSchema> schemas;
  final KbSchema? schema;
  final TextEditingController nameCtrl;
  final TextEditingController categoryCtrl;
  final TextEditingController summaryCtrl;
  final TextEditingController contentCtrl;
  final TextEditingController tagsCtrl;
  final TextEditingController relatedCtrl;
  final Map<String, TextEditingController> extraCtrls;
  final Credibility? credibility;
  final String? schemaId;
  final Future<void> Function() onPickCategory;
  final ValueChanged<String?> onSchemaChanged;
  final ValueChanged<Credibility?> onCredibilityChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: nameCtrl,
            decoration: const InputDecoration(
              labelText: '条目名称',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(
                    labelText: '分类路径（不存在将自动创建）',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                tooltip: '选择已有分类',
                onPressed: onPickCategory,
                icon: const Icon(Icons.account_tree_outlined),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: schemaId,
            decoration: const InputDecoration(
              labelText: '适用 Schema（决定校验与扩展字段）',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final s in schemas)
                DropdownMenuItem(
                  value: s.id,
                  child: Text('${s.name}（${s.id}）'),
                ),
            ],
            onChanged: onSchemaChanged,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: summaryCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: '概述',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: contentCtrl,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: '正文（Markdown）',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: tagsCtrl,
            decoration: const InputDecoration(
              labelText: '标签（中文逗号分隔）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: relatedCtrl,
            decoration: const InputDecoration(
              labelText: '关联条目（名称，逗号分隔；未匹配的显示为待创建）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Credibility?>(
            initialValue: credibility,
            decoration: const InputDecoration(
              labelText: '可信度',
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
            onChanged: onCredibilityChanged,
          ),
          if (schema != null && schema!.fields.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '扩展字段（${schema!.name}）',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (final field in schema!.fields)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: KbSchemaFieldEditor(
                  field: field,
                  controller: extraCtrls[field.key],
                ),
              ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
