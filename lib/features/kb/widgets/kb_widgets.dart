import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/router.dart';
import '../models/kb_schema.dart';

/// 可信度语义（docs/02 D4：结果列表带可信度色点）。
Color credibilityColor(BuildContext context, Credibility? credibility) {
  switch (credibility) {
    case Credibility.high:
      return Colors.green.shade600;
    case Credibility.mid:
      return Colors.orange.shade600;
    case Credibility.low:
      return Colors.red.shade600;
    case null:
      return Theme.of(context).colorScheme.outline;
  }
}

String credibilityLabel(Credibility? credibility) {
  switch (credibility) {
    case Credibility.high:
      return '可信度高';
    case Credibility.mid:
      return '可信度中';
    case Credibility.low:
      return '可信度低';
    case null:
      return '未标注';
  }
}

/// 可信度色点 + 文字。
class CredibilityBadge extends StatelessWidget {
  const CredibilityBadge({super.key, required this.credibility});

  final Credibility? credibility;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: credibilityColor(context, credibility),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          credibilityLabel(credibility),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// 条目列表瓦片：标题 / 分类 / 摘要两行 / 标签 / 可信度色点（docs/02 D4）。
class KbEntryTile extends StatelessWidget {
  const KbEntryTile({super.key, required this.entry, this.onTap});

  final KbEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Container(
        width: 10,
        height: 10,
        margin: const EdgeInsets.only(top: 6),
        decoration: BoxDecoration(
          color: credibilityColor(context, entry.credibility),
          shape: BoxShape.circle,
        ),
      ),
      title: Text(
        entry.entryName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            entry.categoryPath,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          if (entry.summary.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                entry.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}

/// 双向关联 chips：已入库的可点击跳转；未匹配的显示「待创建」（docs/02 D3）。
class RelatedEntriesChips extends ConsumerWidget {
  const RelatedEntriesChips({
    super.key,
    required this.linked,
    required this.pendingNames,
    this.onNavigate,
  });

  final List<KbEntry> linked;
  final List<String> pendingNames;
  final ValueChanged<KbEntry>? onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (linked.isEmpty && pendingNames.isEmpty) {
      return Text('暂无关联条目', style: Theme.of(context).textTheme.bodySmall);
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final entry in linked)
          ActionChip(
            avatar: const Icon(Icons.link, size: 16),
            label: Text(entry.entryName),
            visualDensity: VisualDensity.compact,
            onPressed: onNavigate == null ? null : () => onNavigate!(entry),
          ),
        for (final name in pendingNames)
          ActionChip(
            avatar: Icon(
              Icons.link_off,
              size: 16,
              color: Colors.orange.shade700,
            ),
            label: Text('$name（待创建）'),
            visualDensity: VisualDensity.compact,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('关联条目「$name」尚未入库，可先在入库向导中创建')),
              );
            },
          ),
      ],
    );
  }
}

/// 条目跳转辅助：同一详情页可复用（详情页内跳关联条目）。
void navigateToKbEntry(BuildContext context, int entryId) {
  Navigator.of(context).pushNamed(
    RoutePaths.kbEntryDetail,
    arguments: {RouteArgs.entryId: entryId},
  );
}

/// Schema 扩展字段编辑控件（docs/02 D1 类型：enum/text/markdown/number）。
/// 控制器由父级持有（向导第3步与条目编辑共用）。
class KbSchemaFieldEditor extends StatelessWidget {
  const KbSchemaFieldEditor({
    super.key,
    required this.field,
    required this.controller,
  });

  final KbSchemaField field;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    if (controller == null) return const SizedBox.shrink();
    final label = field.required ? '${field.label} *' : field.label;
    InputDecoration decoration(String hint) => InputDecoration(
      labelText: label,
      helperText: hint,
      border: const OutlineInputBorder(),
    );
    switch (field.type) {
      case KbSchemaFieldType.enumeration:
        // 当前值不在 options 里时不能作为 initialValue（Dropdown 会断言失败），
        // 保留控制器文本由校验提示修正。
        final current = field.options.contains(controller!.text)
            ? controller!.text
            : null;
        return DropdownButtonFormField<String>(
          initialValue: current,
          decoration: decoration('枚举'),
          items: [
            const DropdownMenuItem(value: '', child: Text('（未填写）')),
            for (final option in field.options)
              DropdownMenuItem(value: option, child: Text(option)),
          ],
          onChanged: (value) => controller!.text = value ?? '',
        );
      case KbSchemaFieldType.number:
        return TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: decoration('数字'),
        );
      case KbSchemaFieldType.markdown:
        return TextFormField(
          controller: controller,
          maxLines: 4,
          decoration: decoration('Markdown'),
        );
      case KbSchemaFieldType.text:
        return TextFormField(
          controller: controller,
          decoration: decoration('文本'),
        );
    }
  }
}

/// 逗号/中文逗号分隔的名称输入 → 列表（标签、关联输入共用）。
List<String> splitNames(String? raw) {
  return (raw ?? '')
      .split(RegExp('[，,]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

/// AI 输出的可信度字符串（high/mid/low）→ 枚举；非法值返回 null。
Credibility? credibilityFromName(String? name) {
  if (name == null) return null;
  for (final value in Credibility.values) {
    if (value.name == name) return value;
  }
  return null;
}
