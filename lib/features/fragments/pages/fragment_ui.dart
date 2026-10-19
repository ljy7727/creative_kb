// 灵感碎片模块内共用的小型 UI 片段（状态徽章）。
import 'package:flutter/material.dart';

import '../../../core/db/database.dart';

/// 状态中文标签（docs/02 B1/B2：raw / optimized / failed，优化中为运行态）。
String fragmentStatusLabel(Fragment fragment, {required bool optimizing}) {
  if (optimizing) return '优化中';
  return switch (fragment.status) {
    FragmentStatus.raw => '原始',
    FragmentStatus.optimized => '已优化',
    FragmentStatus.failed => '优化失败',
  };
}

Color fragmentStatusColor(
  Fragment fragment,
  bool optimizing,
  ColorScheme scheme,
) {
  if (optimizing) return scheme.tertiary;
  return switch (fragment.status) {
    FragmentStatus.raw => scheme.secondary,
    FragmentStatus.optimized => scheme.primary,
    FragmentStatus.failed => scheme.error,
  };
}

/// 状态小徽章。
Widget fragmentStatusBadge(
  BuildContext context,
  Fragment fragment, {
  required bool optimizing,
}) {
  final scheme = Theme.of(context).colorScheme;
  final color = fragmentStatusColor(fragment, optimizing, scheme);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      fragmentStatusLabel(fragment, optimizing: optimizing),
      style: Theme.of(context).textTheme.labelSmall
          ?.copyWith(color: color, fontWeight: FontWeight.w600),
    ),
  );
}
