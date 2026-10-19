import 'package:flutter/material.dart';

/// 只读标签 chips：超过 [maxVisible] 折叠为「+N」。各列表页复用。
class TagChipList extends StatelessWidget {
  const TagChipList({
    super.key,
    required this.tags,
    this.maxVisible = 6,
    this.onTagTap,
    this.spacing = 6,
    this.runSpacing = 6,
  });

  final List<String> tags;
  final int maxVisible;
  final ValueChanged<String>? onTagTap;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    final visible = tags.take(maxVisible).toList();
    final hidden = tags.length - visible.length;
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: [
        for (final tag in visible)
          ActionChip(
            label: Text(tag),
            visualDensity: VisualDensity.compact,
            onPressed: onTagTap == null ? null : () => onTagTap!(tag),
          ),
        if (hidden > 0)
          ActionChip(
            label: Text('+$hidden'),
            visualDensity: VisualDensity.compact,
            onPressed: null,
          ),
      ],
    );
  }
}
