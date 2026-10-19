// 最近明细表（docs/02 A5：最近 50 条，费用列无价显示 "—"）。
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/db/database.dart';

final _intFormat = NumberFormat('#,##0');
final _timeFormat = DateFormat('MM-dd HH:mm');

const _moduleLabels = <String, String>{
  'fragments': '灵感',
  'prompts': '提示词',
  'kb': '资料库',
  'usage': '用量',
  'settings': '设置',
};

/// module 英文标识 → 中文展示；未登记的原样显示。
String moduleLabel(String module) => _moduleLabels[module] ?? module;

class UsageDetailTable extends StatelessWidget {
  const UsageDetailTable({super.key, required this.entries});

  final List<UsageLogEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Text('暂无明细')),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        headingRowHeight: 40,
        columns: const <DataColumn>[
          DataColumn(label: Text('时间')),
          DataColumn(label: Text('模块')),
          DataColumn(label: Text('任务')),
          DataColumn(label: Text('模型')),
          DataColumn(label: Text('输入'), numeric: true),
          DataColumn(label: Text('输出'), numeric: true),
          DataColumn(label: Text('费用(元)'), numeric: true),
          DataColumn(label: Text('状态')),
        ],
        rows: <DataRow>[
          for (final entry in entries)
            DataRow(
              cells: <DataCell>[
                DataCell(Text(_timeFormat.format(entry.ts))),
                DataCell(Text(moduleLabel(entry.module))),
                DataCell(Text(entry.taskType)),
                DataCell(Text(entry.model.isEmpty ? '—' : entry.model)),
                DataCell(Text(_intFormat.format(entry.inputTokens))),
                DataCell(Text(_intFormat.format(entry.outputTokens))),
                // 查不到价格表只记 token，费用显示 "—"（docs/00 D5）。
                DataCell(
                  Text(
                    entry.costEstimate == null
                        ? '—'
                        : entry.costEstimate!.toStringAsFixed(4),
                  ),
                ),
                DataCell(_statusCell(entry)),
              ],
            ),
        ],
      ),
    );
  }

  static Widget _statusCell(UsageLogEntry entry) {
    final (color, label) = switch (entry.status) {
      UsageStatus.ok => (const Color(0xFF2E7D32), '成功'),
      UsageStatus.error => (const Color(0xFFC62828), '失败'),
      UsageStatus.blocked => (const Color(0xFFEF6C00), '已拦截'),
    };
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
        border: Border.fromBorderSide(BorderSide(color: color)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12)),
    );
    final error = entry.error;
    if (error == null || error.isEmpty) return chip;
    return Tooltip(message: error, child: chip);
  }
}
