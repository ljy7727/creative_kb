// 设置页（docs/02 模块E + A2/A3/A6）：厂商与 Key、思考强度默认、额度、
// Schema 注册表管理、更新检查、数据导出导入。
// 数据库未注入（纯 UI 冒烟）时整体给引导空态。
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/db/app_setting_keys.dart';
import '../../../core/db/database.dart';
import '../../../core/llm/providers.dart';
import '../../../core/update/update_checker.dart';
import '../../kb/models/kb_schema.dart';
import '../../kb/services/kb_embedding_config.dart';
import '../../kb/services/kb_providers.dart'
    show embeddingConfigProvider, schemaDirProvider, schemaRegistryProvider;
import '../../kb/services/schema_registry.dart';
import '../providers/settings_providers.dart';
import '../services/backup_service.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(settingsDbProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: db == null
          ? const Center(child: Text('数据库未初始化，请从应用主入口启动后再配置。'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                _ProvidersGroup(),
                SizedBox(height: 16),
                _EmbeddingGroup(),
                SizedBox(height: 16),
                _IntensityGroup(),
                SizedBox(height: 16),
                _QuotaGroup(),
                SizedBox(height: 16),
                _SchemaGroup(),
                SizedBox(height: 16),
                _UpdateGroup(),
                SizedBox(height: 16),
                _DataGroup(),
                SizedBox(height: 32),
              ],
            ),
    );
  }
}

/// 分组卡片骨架：标题 + 说明 + 内容列。
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children, this.subtitle});

  final String title;
  final String? subtitle;
  final List<Widget> children;

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
            Text(title, style: theme.textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

// ---------------------------------------------------------------------------
// 分组一：厂商与 API Key（docs/02 A2/A3）
// ---------------------------------------------------------------------------
class _ProvidersGroup extends ConsumerWidget {
  const _ProvidersGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providers =
        ref.watch(providersStreamProvider).value ?? const <ProviderRow>[];
    return _Section(
      title: '厂商与 API Key',
      subtitle:
          'Key 只写入系统安全存储（Windows 凭据管理器 / Android Keystore），'
          '数据库仅保存引用名。模型标签为自动识别，可手动修正。',
      children: [
        if (providers.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('尚未配置厂商。添加一个厂商并填入 API Key 后即可使用 AI 功能。'),
          ),
        for (final provider in providers)
          _ProviderTile(key: ValueKey(provider.id), provider: provider),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.tonalIcon(
            onPressed: () => _showAddProviderDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('添加厂商'),
          ),
        ),
      ],
    );
  }
}

class _ProviderTile extends ConsumerStatefulWidget {
  const _ProviderTile({super.key, required this.provider});

  final ProviderRow provider;

  @override
  ConsumerState<_ProviderTile> createState() => _ProviderTileState();
}

class _ProviderTileState extends ConsumerState<_ProviderTile> {
  final _keyController = TextEditingController();
  bool _savingKey = false;
  bool _pulling = false;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  ProviderRow get _provider => widget.provider;

  Future<void> _saveKey() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      _toast(context, '请先输入 API Key');
      return;
    }
    setState(() => _savingKey = true);
    try {
      final keyRef = buildKeyRef(
        presetCode: _provider.presetCode,
        providerName: _provider.name,
      );
      await ref.read(secureKeysProvider).save(keyRef, key);
      if (_provider.keyRef != keyRef) {
        await ref
            .read(settingsDbProvider)!
            .providersDao
            .updateRow(_provider.copyWith(keyRef: Value<String?>(keyRef)));
      }
      _keyController.clear();
      if (mounted) _toast(context, 'Key 已保存到安全存储');
    } catch (e) {
      if (mounted) _toast(context, '保存失败：$e');
    } finally {
      if (mounted) setState(() => _savingKey = false);
    }
  }

  Future<void> _pullModels() async {
    if (_pulling) return;
    setState(() => _pulling = true);
    try {
      final keyRef = _provider.keyRef;
      final apiKey = keyRef == null
          ? null
          : await ref.read(secureKeysProvider).read(keyRef);
      if (apiKey == null || apiKey.isEmpty) {
        if (!mounted) return;
        _toast(context, '请先保存该厂商的 API Key');
        return;
      }
      final count = await ref
          .read(modelCatalogProvider)
          .refresh(
            provider: ProviderConfig(
              name: _provider.name,
              baseUrl: _provider.baseUrl,
              apiKey: apiKey,
            ),
            providerId: _provider.id,
          );
      if (mounted) _toast(context, '已拉取 ${count.length} 个模型并自动打标签');
    } catch (e) {
      if (mounted) _toast(context, '拉取失败：$e');
    } finally {
      if (mounted) setState(() => _pulling = false);
    }
  }

  Future<void> _deleteProvider() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除厂商？'),
        content: Text('将同时删除 ${_provider.name} 的模型列表与已存 Key。'),
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
    final db = ref.read(settingsDbProvider)!;
    await db.modelsDao.removeByProvider(_provider.id);
    final keyRef = _provider.keyRef;
    if (keyRef != null && keyRef.isNotEmpty) {
      await ref.read(secureKeysProvider).delete(keyRef);
    }
    await db.providersDao.remove(_provider.id);
    if (mounted) _toast(context, '已删除厂商');
  }

  @override
  Widget build(BuildContext context) {
    final modelsAsync = ref.watch(modelsByProviderProvider(_provider.id));
    final models = modelsAsync.value ?? const <ModelRow>[];
    final hasKey = _provider.keyRef != null && _provider.keyRef!.isNotEmpty;
    return ExpansionTile(
      title: Text(_provider.name),
      subtitle: Text(
        '${_provider.baseUrl}\n'
        '${hasKey ? '已配置 Key' : '未配置 Key'} · ${models.length} 个模型',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _keyController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'API Key',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _savingKey ? null : _saveKey,
                    child: const Text('保存 Key'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pulling ? null : _pullModels,
                    icon: _pulling
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_download_outlined),
                    label: const Text('拉取模型'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _deleteProvider,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('删除厂商'),
                  ),
                ],
              ),
              const Divider(),
              if (models.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('尚未拉取模型。保存 Key 后点「拉取模型」。'),
                )
              else
                for (final model in models)
                  _ModelTile(key: ValueKey(model.id), model: model),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModelTile extends ConsumerStatefulWidget {
  const _ModelTile({super.key, required this.model});

  final ModelRow model;

  @override
  ConsumerState<_ModelTile> createState() => _ModelTileState();
}

class _ModelTileState extends ConsumerState<_ModelTile> {
  static const _allTags = <String, String>{
    'general': '通用',
    'reasoning': '推理',
    'long_context': '长上下文',
    'embedding': '向量化',
  };

  ModelRow get _model => widget.model;

  List<String> get _tags {
    try {
      final decoded = jsonDecode(_model.tags);
      if (decoded is List) return [for (final t in decoded) '$t'];
    } on FormatException {
      // tags 损坏按空处理。
    }
    return const [];
  }

  Future<void> _toggleActive(bool value) async {
    await ref.read(settingsDbProvider)!.modelsDao.setActive(_model.id, value);
  }

  Future<void> _editTags() async {
    final selected = {..._tags};
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('模型标签'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('自动识别，可手动修正'),
              for (final entry in _allTags.entries)
                CheckboxListTile(
                  dense: true,
                  title: Text(entry.value),
                  subtitle: Text(entry.key),
                  value: selected.contains(entry.key),
                  onChanged: (checked) => setDialogState(() {
                    if (checked == true) {
                      selected.add(entry.key);
                    } else {
                      selected.remove(entry.key);
                    }
                  }),
                ),
            ],
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
      ),
    );
    if (confirmed == true) {
      await ref
          .read(settingsDbProvider)!
          .modelsDao
          .updateTags(_model.id, jsonEncode(selected.toList()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _editTags,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _model.displayName,
                    style: TextStyle(
                      decoration: _model.isActive
                          ? null
                          : TextDecoration.lineThrough,
                    ),
                  ),
                  Wrap(
                    spacing: 4,
                    children: [
                      for (final tag in _tags)
                        Chip(
                          label: Text(
                            _allTags[tag] ?? tag,
                            style: const TextStyle(fontSize: 11),
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Switch(value: _model.isActive, onChanged: _toggleActive),
      ],
    );
  }
}

Future<void> _showAddProviderDialog(BuildContext context, WidgetRef ref) async {
  var preset = ProviderPreset.deepseek;
  final nameController = TextEditingController(text: preset.displayName);
  final baseUrlController = TextEditingController(text: preset.baseUrl);
  final keyController = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: const Text('添加厂商'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<ProviderPreset>(
              initialValue: preset,
              decoration: const InputDecoration(labelText: '预设'),
              items: [
                for (final p in ProviderPreset.values)
                  DropdownMenuItem(value: p, child: Text(p.displayName)),
              ],
              onChanged: (value) => setDialogState(() {
                preset = value ?? ProviderPreset.custom;
                nameController.text = preset.displayName;
                baseUrlController.text = preset.baseUrl;
              }),
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '名称'),
            ),
            TextField(
              controller: baseUrlController,
              decoration: const InputDecoration(
                labelText: 'Base URL（OpenAI 兼容根路径）',
              ),
            ),
            TextField(
              controller: keyController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'API Key（可稍后在列表中填写）',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('添加'),
          ),
        ],
      ),
    ),
  );
  if (confirmed != true) return;
  if (!context.mounted) return;
  final name = nameController.text.trim();
  final baseUrl = baseUrlController.text.trim();
  if (name.isEmpty || baseUrl.isEmpty) {
    _toast(context, '名称与 Base URL 不能为空');
    return;
  }
  final db = ref.read(settingsDbProvider)!;
  final keyRef = buildKeyRef(presetCode: preset.name, providerName: name);
  await db.providersDao.add(
    ProvidersCompanion.insert(
      name: name,
      baseUrl: baseUrl,
      presetCode: preset.name,
      keyRef: Value<String?>(keyRef),
    ),
  );
  final key = keyController.text.trim();
  if (key.isNotEmpty) {
    await ref.read(secureKeysProvider).save(keyRef, key);
  }
  if (context.mounted) _toast(context, '已添加厂商，可点「拉取模型」获取模型列表');
}

// ---------------------------------------------------------------------------
// 分组二：思考强度默认值（docs/02 A4）
// ---------------------------------------------------------------------------
class _IntensityGroup extends ConsumerWidget {
  const _IntensityGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presets =
        ref.watch(intensityPresetsSettingsProvider).value ??
        const <IntensityPreset>[];
    final current = ref.watch(defaultIntensityProvider).value ?? 'standard';
    return _Section(
      title: '思考强度',
      subtitle: '所有 AI 功能的默认强度；各功能发起处仍可临时切换。',
      children: [
        RadioGroup<String>(
          groupValue: current,
          onChanged: (value) async {
            if (value == null) return;
            await ref
                .read(settingsDbProvider)!
                .appSettingsDao
                .set(AppSettingKeys.defaultIntensity, value);
          },
          child: Column(
            children: [
              for (final preset in presets)
                RadioListTile<String>(
                  dense: true,
                  value: preset.code,
                  title: Text(preset.name),
                  subtitle: Text(_paramsSummary(preset.params)),
                ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: presets.isEmpty
                ? null
                : () => _showCustomParamsDialog(context, ref, presets),
            icon: const Icon(Icons.tune),
            label: const Text('编辑「自定义」参数'),
          ),
        ),
      ],
    );
  }

  String _paramsSummary(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final parts = <String>[
          if (decoded['temperature'] != null)
            'temperature=${decoded['temperature']}',
          if (decoded['maxTokens'] != null) 'maxTokens=${decoded['maxTokens']}',
          if (decoded['topP'] != null) 'topP=${decoded['topP']}',
        ];
        return parts.join('，');
      }
    } catch (_) {}
    return raw;
  }

  Future<void> _showCustomParamsDialog(
    BuildContext context,
    WidgetRef ref,
    List<IntensityPreset> presets,
  ) async {
    final custom = presets.where((p) => p.code == 'custom').firstOrNull;
    if (custom == null) {
      _toast(context, '没有「自定义」预设');
      return;
    }
    double? temperature;
    int? maxTokens;
    double? topP;
    try {
      final decoded = jsonDecode(custom.params);
      if (decoded is Map<String, dynamic>) {
        temperature = (decoded['temperature'] as num?)?.toDouble();
        maxTokens = (decoded['maxTokens'] as num?)?.toInt();
        topP = (decoded['topP'] as num?)?.toDouble();
      }
    } catch (_) {}
    final temperatureCtrl = TextEditingController(
      text: temperature?.toString() ?? '',
    );
    final topPCtrl = TextEditingController(text: topP?.toString() ?? '');
    final maxTokensCtrl = TextEditingController(
      text: maxTokens?.toString() ?? '',
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('自定义强度参数'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: temperatureCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'temperature（0–2）'),
            ),
            TextField(
              controller: topPCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'topP（0–1，可空）'),
            ),
            TextField(
              controller: maxTokensCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'maxTokens'),
            ),
          ],
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
    if (confirmed != true) return;
    final params = jsonEncode({
      if (temperatureCtrl.text.trim().isNotEmpty)
        'temperature': double.tryParse(temperatureCtrl.text.trim()),
      if (topPCtrl.text.trim().isNotEmpty)
        'topP': double.tryParse(topPCtrl.text.trim()),
      if (maxTokensCtrl.text.trim().isNotEmpty)
        'maxTokens': int.tryParse(maxTokensCtrl.text.trim()),
    });
    await ref
        .read(settingsDbProvider)!
        .intensityPresetsDao
        .updateParams('custom', params);
    if (context.mounted) _toast(context, '自定义参数已保存');
  }
}

// ---------------------------------------------------------------------------
// 分组三：额度（docs/02 A5）
// ---------------------------------------------------------------------------
class _QuotaGroup extends ConsumerStatefulWidget {
  const _QuotaGroup();

  @override
  ConsumerState<_QuotaGroup> createState() => _QuotaGroupState();
}

class _QuotaGroupState extends ConsumerState<_QuotaGroup> {
  final _singleController = TextEditingController();
  final _dailyController = TextEditingController();
  bool _loaded = false;

  @override
  void dispose() {
    _singleController.dispose();
    _dailyController.dispose();
    super.dispose();
  }

  Future<void> _loadOnce() async {
    if (_loaded) return;
    _loaded = true;
    final db = ref.read(settingsDbProvider);
    if (db == null) return;
    final values = await db.appSettingsDao.getAll();
    _singleController.text = values[AppSettingKeys.singleTaskMaxTokens] ?? '';
    _dailyController.text = values[AppSettingKeys.dailyMaxTokens] ?? '';
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    final single = int.tryParse(_singleController.text.trim());
    final daily = int.tryParse(_dailyController.text.trim());
    if (single == null || single <= 0 || daily == null || daily <= 0) {
      _toast(context, '请输入正整数额度');
      return;
    }
    final db = ref.read(settingsDbProvider)!;
    await db.appSettingsDao.set(AppSettingKeys.singleTaskMaxTokens, '$single');
    await db.appSettingsDao.set(AppSettingKeys.dailyMaxTokens, '$daily');
    if (mounted) _toast(context, '额度已保存：单次 $single / 每日 $daily token');
  }

  @override
  Widget build(BuildContext context) {
    _loadOnce();
    return _Section(
      title: '额度防护',
      subtitle: '单次任务 max_tokens 封顶；当日累计超过日上限后新任务被拦截并在用量页留痕。',
      children: [
        TextField(
          controller: _singleController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '单次任务 token 上限',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _dailyController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '每日 token 上限',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.tonal(onPressed: _save, child: const Text('保存')),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 分组四：Schema 注册表管理（docs/02 D1）
// ---------------------------------------------------------------------------
class _SchemaGroup extends ConsumerWidget {
  const _SchemaGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schemasAsync = ref.watch(schemaRegistryProvider);
    return _Section(
      title: 'Schema 注册表',
      subtitle: '入库向导的扩展字段模板，JSON 文件存于应用数据目录 schemas/，保存即热加载。',
      children: [
        schemasAsync.when(
          loading: () =>
              const Padding(padding: EdgeInsets.all(8), child: Text('读取中…')),
          error: (error, _) => Text('读取失败：$error'),
          data: (schemas) => Column(
            children: [
              for (final schema in schemas)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('${schema.name}（${schema.id}）'),
                  subtitle: Text(
                    schema.fields.isEmpty
                        ? '无扩展字段'
                        : schema.fields.map((f) => f.label).join('、'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: '编辑 JSON',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () =>
                            _showSchemaJsonDialog(context, ref, schema),
                      ),
                      IconButton(
                        tooltip: '删除',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteSchema(context, ref, schema),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => _showSchemaJsonDialog(context, ref, null),
              icon: const Icon(Icons.add),
              label: const Text('新增 Schema'),
            ),
            OutlinedButton.icon(
              onPressed: () => _restoreBuiltin(context, ref),
              icon: const Icon(Icons.restore),
              label: const Text('恢复内置 4 套'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showSchemaJsonDialog(
    BuildContext context,
    WidgetRef ref,
    KbSchema? existing,
  ) async {
    final controller = TextEditingController(
      text:
          existing?.encode() ??
          const JsonEncoder.withIndent('  ').convert({
            'id': 'my_schema',
            'name': '我的模板',
            'matchKeywords': ['关键词'],
            'baseSchema': 'general',
            'fields': [
              {
                'key': 'field1',
                'label': '字段1',
                'type': 'text',
                'required': false,
              },
            ],
          }),
    );
    final errorNotifier = ValueNotifier<String?>(null);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          existing == null ? '新增 Schema' : '编辑 Schema：${existing.id}',
        ),
        content: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<String?>(
                valueListenable: errorNotifier,
                builder: (_, error, _) => error == null
                    ? const SizedBox.shrink()
                    : Text(
                        error,
                        style: TextStyle(
                          color: Theme.of(dialogContext).colorScheme.error,
                        ),
                      ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: controller,
                maxLines: 14,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Schema JSON',
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
            onPressed: () {
              try {
                final decoded = jsonDecode(controller.text);
                if (decoded is! Map<String, dynamic>) {
                  errorNotifier.value = '顶层必须是 JSON 对象';
                  return;
                }
                final schema = KbSchema.fromJson(decoded);
                if (schema.id.trim().isEmpty) {
                  errorNotifier.value = 'id 不能为空';
                  return;
                }
                Navigator.of(dialogContext).pop(true);
              } on FormatException catch (e) {
                errorNotifier.value = 'JSON 不合法：${e.message}';
              } catch (e) {
                errorNotifier.value = '$e';
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    errorNotifier.dispose();
    if (confirmed != true) return;
    try {
      final schema = KbSchema.fromJson(
        jsonDecode(controller.text) as Map<String, dynamic>,
      );
      final dir = await ref.read(schemaDirProvider.future);
      if (dir == null) {
        if (context.mounted) _toast(context, '数据目录不可用，无法保存');
        return;
      }
      await SchemaRegistry(dir).save(schema);
      ref.invalidate(schemaRegistryProvider);
      if (context.mounted) _toast(context, 'Schema 已保存并热加载');
    } catch (e) {
      if (context.mounted) _toast(context, '保存失败：$e');
    }
  }

  Future<void> _deleteSchema(
    BuildContext context,
    WidgetRef ref,
    KbSchema schema,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('删除 Schema「${schema.name}」？'),
        content: const Text('仅删除模板文件，不影响已入库条目。'),
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
    final dir = await ref.read(schemaDirProvider.future);
    if (dir == null) return;
    await SchemaRegistry(dir).delete(schema.id);
    ref.invalidate(schemaRegistryProvider);
    if (context.mounted) _toast(context, '已删除');
  }

  Future<void> _restoreBuiltin(BuildContext context, WidgetRef ref) async {
    final dir = await ref.read(schemaDirProvider.future);
    if (dir == null) {
      if (context.mounted) _toast(context, '数据目录不可用');
      return;
    }
    final written = await SchemaRegistry(dir).restoreBuiltin();
    ref.invalidate(schemaRegistryProvider);
    if (context.mounted) {
      _toast(context, '已补写 ${written.length} 个内置 Schema（不覆盖已有）');
    }
  }
}

// ---------------------------------------------------------------------------
// 分组五：更新检查（docs/02 A6）
// ---------------------------------------------------------------------------
class _UpdateGroup extends ConsumerStatefulWidget {
  const _UpdateGroup();

  @override
  ConsumerState<_UpdateGroup> createState() => _UpdateGroupState();
}

class _UpdateGroupState extends ConsumerState<_UpdateGroup> {
  final _repoController = TextEditingController();
  bool _loaded = false;
  bool _checking = false;
  String? _lastChecked;

  @override
  void dispose() {
    _repoController.dispose();
    super.dispose();
  }

  Future<void> _loadOnce() async {
    // 流式设置项首帧可能尚未就绪：拿到值前每帧重试，拿到后停止。
    if (_loaded) return;
    final repo = ref.read(updateRepoSettingProvider).value;
    if (repo == null) return;
    _loaded = true;
    _repoController.text = repo;
    if (mounted) setState(() {});
  }

  Future<void> _saveRepo() async {
    final value = _repoController.text.trim();
    final parsed = parseUpdateRepo(value);
    if (parsed == null) {
      _toast(context, '格式应为 owner/repo，例如 yourname/creative_kb');
      return;
    }
    await ref
        .read(settingsDbProvider)!
        .appSettingsDao
        .set(AppSettingKeys.updateRepo, value);
    if (mounted) _toast(context, '已保存：$value');
  }

  Future<void> _checkNow() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final parsed = parseUpdateRepo(_repoController.text.trim());
      if (parsed == null) {
        _toast(context, '请先填写仓库（owner/repo）');
        return;
      }
      final result = await ref
          .read(updateCheckerProvider)
          .check(
            owner: parsed.owner,
            repo: parsed.repo,
            currentVersion: await resolveCurrentVersion(),
          );
      if (!mounted) return;
      if (result.hasUpdate) {
        await _showUpdateDialog(context, result);
      } else {
        _toast(context, '当前已是最新版本（${result.currentVersion}）');
      }
      _lastChecked = '上次检查：${DateTime.now().toString().substring(0, 16)}';
    } catch (e) {
      if (mounted) _toast(context, '检查更新失败：$e');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _loadOnce();
    final autoCheck = ref.watch(updateAutoCheckProvider).value ?? true;
    final version = ref.watch(appVersionProvider).value;
    return _Section(
      title: '更新检查',
      subtitle:
          '连接 GitHub Releases 检查新版本；404（未发布）静默跳过。'
          '桌面端「前往下载」打开 Release 页，Android 直接打开 APK 下载。',
      children: [
        TextField(
          controller: _repoController,
          decoration: InputDecoration(
            labelText: '仓库（owner/repo）',
            border: const OutlineInputBorder(),
            isDense: true,
            helperText: version == null ? null : '当前版本 $version',
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _saveRepo,
            icon: const Icon(Icons.save_outlined),
            label: const Text('保存仓库'),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('启动时自动检查'),
                value: autoCheck,
                onChanged: (value) async {
                  await ref
                      .read(settingsDbProvider)!
                      .appSettingsDao
                      .set(
                        AppSettingKeys.updateAutoCheck,
                        value ? 'true' : 'false',
                      );
                },
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: _checking ? null : _checkNow,
              icon: _checking
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.system_update_alt),
              label: const Text('检查更新'),
            ),
          ],
        ),
        if (_lastChecked != null)
          Text(_lastChecked!, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// 发现新版本对话框：Release Notes（markdown）+ 前往下载。
Future<void> _showUpdateDialog(
  BuildContext context,
  UpdateCheckResult result,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('发现新版本 ${result.tagName ?? ''}'),
      content: SizedBox(
        width: 480,
        child: result.releaseNotes == null || result.releaseNotes!.isEmpty
            ? const Text('（无 Release Notes）')
            : SizedBox(
                height: 280,
                child: MarkdownBody(data: result.releaseNotes!),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('稍后再说'),
        ),
        FilledButton(
          onPressed: () async {
            final url = UpdateChecker.downloadUrl(
              result,
              isAndroid: UpdateChecker.isAndroidPlatform,
            );
            try {
              await launchUrl(
                Uri.parse(url),
                mode: LaunchMode.externalApplication,
              );
            } catch (e) {
              if (!dialogContext.mounted) return;
              await showDialog<void>(
                context: dialogContext,
                builder: (_) => AlertDialog(content: Text('无法打开链接：$url\n$e')),
              );
            }
          },
          child: const Text('前往下载'),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// 分组六：数据导出 / 导入（docs/02 模块E）
// ---------------------------------------------------------------------------
class _DataGroup extends ConsumerStatefulWidget {
  const _DataGroup();

  @override
  ConsumerState<_DataGroup> createState() => _DataGroupState();
}

class _DataGroupState extends ConsumerState<_DataGroup> {
  bool _busy = false;

  Future<void> _export() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final service = await ref.read(backupServiceProvider.future);
      if (service == null) {
        if (mounted) _toast(context, '数据目录不可用，无法导出');
        return;
      }
      final file = await service.exportTo(service.exportsDir);
      if (mounted) {
        _toast(context, '已导出到 ${file.path}');
      }
    } catch (e) {
      if (mounted) _toast(context, '导出失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final service = await ref.read(backupServiceProvider.future);
      if (service == null) {
        if (mounted) _toast(context, '数据目录不可用，无法导入');
        return;
      }
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      final path = picked?.path;
      if (path == null) return;
      final bytes = await File(path).readAsBytes();
      final backup = await service.importFrom(bytes);
      ref.invalidate(schemaRegistryProvider);
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('导入完成'),
            content: Text(
              'Schema 已热加载；数据库将在下次启动时换入。\n\n'
              '导入前的数据已自动备份到：\n${backup.path}',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('知道了'),
              ),
            ],
          ),
        );
      }
    } on BackupValidationException catch (e) {
      if (mounted) _toast(context, e.toString());
    } catch (e) {
      if (mounted) _toast(context, '导入失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: '数据导出 / 导入',
      subtitle:
          '导出 = SQLite 数据库 + schemas 目录 + 版本清单的 zip；'
          '导入前会自动备份当前数据，导入后重启应用生效。',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _busy ? null : _export,
              icon: const Icon(Icons.archive_outlined),
              label: const Text('导出全部数据'),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _import,
              icon: const Icon(Icons.unarchive_outlined),
              label: const Text('从备份导入'),
            ),
          ],
        ),
      ],
    );
  }
}

/// 向量化模型分组（docs/02 D7）：语义检索的嵌入模型选择；不选择时资料库
/// 检索自动降级为关键词（FTS）。候选 = 已配 Key 厂商下启用中且带
///「向量化」标签的模型（kb.embedding_model 设置，见 kb_embedding_config.dart）。
class _EmbeddingGroup extends ConsumerStatefulWidget {
  const _EmbeddingGroup();

  @override
  ConsumerState<_EmbeddingGroup> createState() => _EmbeddingGroupState();
}

class _EmbeddingGroupState extends ConsumerState<_EmbeddingGroup> {
  KbEmbeddingConfig? _current;
  List<(ProviderRow, ModelRow)> _candidates = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final db = ref.read(settingsDbProvider);
    if (db == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final current = await KbEmbeddingConfigResolver.resolve(db);
    final providers = await db.providersDao.getAll();
    final candidates = <(ProviderRow, ModelRow)>[];
    for (final provider in providers) {
      if ((provider.keyRef ?? '').isEmpty) continue;
      final models = await db.modelsDao.activeByProvider(provider.id);
      for (final model in models) {
        if (_hasEmbeddingTag(model.tags)) candidates.add((provider, model));
      }
    }
    if (!mounted) return;
    setState(() {
      _current = current;
      _candidates = candidates;
      _loading = false;
    });
  }

  static bool _hasEmbeddingTag(String tagsJson) {
    try {
      final decoded = jsonDecode(tagsJson);
      if (decoded is List && decoded.contains('embedding')) return true;
    } on FormatException {
      // tags 损坏按无标签处理（与 _ModelTile 同容错）。
    }
    return false;
  }

  int get _groupValue {
    if (_current == null) return -1;
    for (var i = 0; i < _candidates.length; i++) {
      final (provider, model) = _candidates[i];
      if (provider.id == _current!.providerId &&
          model.modelId == _current!.model) {
        return i;
      }
    }
    return -1;
  }

  Future<void> _select(int index) async {
    final db = ref.read(settingsDbProvider);
    if (db == null) return;
    if (index < 0) {
      await KbEmbeddingConfigResolver.clear(db);
    } else {
      final (provider, model) = _candidates[index];
      await KbEmbeddingConfigResolver.save(
        db,
        providerId: provider.id,
        model: model.modelId,
      );
    }
    // kb 模块 FutureProvider 有缓存，失效后检索页/详情页立即按新配置工作。
    ref.invalidate(embeddingConfigProvider);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: '向量化模型',
      subtitle: '用于资料库语义检索；不选择时自动降级为关键词检索',
      children: [
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_candidates.isEmpty)
          const Text(
            '暂无可用的向量化模型：先在「厂商与模型」中添加 API Key 并拉取模型，'
            '标签为「向量化」的模型会出现在这里（通义/智谱等厂商提供）。',
          )
        else
          RadioGroup<int>(
            groupValue: _groupValue,
            onChanged: (value) => _select(value ?? -1),
            child: Column(
              children: [
                const RadioListTile<int>(
                  value: -1,
                  title: Text('不使用向量化'),
                  subtitle: Text('仅关键词检索'),
                  contentPadding: EdgeInsets.zero,
                ),
                for (var i = 0; i < _candidates.length; i++)
                  RadioListTile<int>(
                    value: i,
                    title: Text(
                      '${_candidates[i].$1.name} / ${_candidates[i].$2.modelId}',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
