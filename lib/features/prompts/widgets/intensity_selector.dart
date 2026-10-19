import 'package:flutter/material.dart';

import '../../../core/db/database.dart';

/// 思考强度选择 chips（生成/优化/变量提取处共用，docs/02 A4）。
class IntensitySelector extends StatelessWidget {
  const IntensitySelector({
    super.key,
    required this.presets,
    required this.selectedCode,
    required this.onChanged,
  });

  final List<IntensityPreset> presets;
  final String? selectedCode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (presets.isEmpty) {
      return Text('暂无强度预设', style: theme.textTheme.bodySmall);
    }
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final preset in presets)
          ChoiceChip(
            label: Text(preset.name),
            selected: preset.code == selectedCode,
            onSelected: (_) => onChanged(preset.code),
          ),
      ],
    );
  }
}
