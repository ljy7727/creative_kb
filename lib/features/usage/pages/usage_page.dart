// 用量看板（docs/02 A5）：今日/累计 token、按模块占比、按模型柱状、最近 50 条明细。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/db/database.dart';
import '../../../shared/empty_state.dart';
import '../usage_providers.dart';
import '../widgets/usage_charts.dart';
import '../widgets/usage_detail_table.dart';

final _intFormat = NumberFormat('#,##0');

String _fmtCost(double value) {
  if (value == 0) return '0.00';
  if (value.abs() < 0.01) return value.toStringAsFixed(4);
  return value.toStringAsFixed(2);
}

class UsagePage extends ConsumerWidget {
  const UsagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(usageTotalsProvider);
    final recent = ref.watch(usageRecentProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('用量统计')),
      body: totals.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => EmptyState(
          icon: Icons.error_outline,
          title: '用量数据加载失败',
          hint: '$error',
        ),
        data: (data) {
          final entries = recent.asData?.value ?? const <UsageLogEntry>[];
          if (data.totalTokens == 0 && entries.isEmpty) {
            return const EmptyState(
              icon: Icons.insights_outlined,
              title: '暂无用量记录',
              hint: '执行 AI 任务后，这里将展示 token 用量、模块占比、模型分布与费用参考。',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCards(totals: data),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final pie = _SectionCard(
                    title: '按模块占比（输出 token）',
                    child: UsagePieChart(data: data.outputByModule),
                  );
                  final bar = _SectionCard(
                    title: '按模型柱状（输出 token）',
                    child: UsageBarChart(data: data.outputByModel),
                  );
                  if (constraints.maxWidth >= 900) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: pie),
                        const SizedBox(width: 16),
                        Expanded(child: bar),
                      ],
                    );
                  }
                  return Column(
                    children: [pie, const SizedBox(height: 16), bar],
                  );
                },
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: '最近明细（最多 50 条，费用为参考估值）',
                child: UsageDetailTable(entries: entries),
              ),
            ],
          );
        },
      ),
    );
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.totals});

  final UsageTotals totals;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _statCard(
        context,
        title: '今日 token',
        value: _intFormat.format(totals.todayTotal),
        subtitle:
            '输入 ${_intFormat.format(totals.todayInput)}'
            ' · 输出 ${_intFormat.format(totals.todayOutput)}',
      ),
      _statCard(
        context,
        title: '累计 token',
        value: _intFormat.format(totals.totalTokens),
        subtitle:
            '输入 ${_intFormat.format(totals.totalInput)}'
            ' · 输出 ${_intFormat.format(totals.totalOutput)}',
      ),
      _statCard(
        context,
        title: '费用参考（元）',
        value: '¥${_fmtCost(totals.totalCost)}',
        subtitle: '今日 ¥${_fmtCost(totals.todayCost)}（估值）',
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 700) {
          // ListView 内高度无界，Row 不能用 stretch。
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: cards[i]),
              ],
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              cards[i],
            ],
          ],
        );
      },
    );
  }

  Widget _statCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
