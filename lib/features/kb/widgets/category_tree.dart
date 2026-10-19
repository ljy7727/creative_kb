import 'package:flutter/material.dart';

/// 分类树节点（path 形如「仙侠设定/势力宗门」，docs/01 第三节）。
class CategoryNode {
  CategoryNode({required this.label, required this.path});

  final String label;
  final String path;
  final List<CategoryNode> children = [];

  /// 含子分类的条目总数（docs/02 D4：树节点含每类计数）。
  int totalCount(Map<String, int> directCounts) {
    var total = directCounts[path] ?? 0;
    for (final child in children) {
      total += child.totalCount(directCounts);
    }
    return total;
  }
}

/// 由扁平 path 列表构建树（去重、逐级补父、按名称排序）。
List<CategoryNode> buildCategoryTree(Iterable<String> paths) {
  final root = CategoryNode(label: '', path: '');
  for (final path in paths.toSet()) {
    final segments = path.split('/');
    var current = root;
    var built = '';
    for (final segment in segments) {
      final label = segment.trim();
      if (label.isEmpty) continue;
      built = built.isEmpty ? label : '$built/$label';
      CategoryNode? child;
      for (final existing in current.children) {
        if (existing.label == label) {
          child = existing;
          break;
        }
      }
      child ??= () {
        final node = CategoryNode(label: label, path: built);
        current.children.add(node);
        return node;
      }();
      current = child;
    }
  }
  void sortDeep(CategoryNode node) {
    node.children.sort((a, b) => a.label.compareTo(b.label));
    for (final child in node.children) {
      sortDeep(child);
    }
  }

  sortDeep(root);
  return root.children;
}

/// [entryCategoryPath] 是否落在 [selectedPath] 子树内。
bool inCategorySubtree(String entryCategoryPath, String selectedPath) {
  return entryCategoryPath == selectedPath ||
      entryCategoryPath.startsWith('$selectedPath/');
}

/// 可折叠分类树（选中高亮；含每类计数，docs/02 D4）。
class CategoryTreeView extends StatelessWidget {
  const CategoryTreeView({
    super.key,
    required this.nodes,
    required this.directCounts,
    this.selectedPath,
    this.onSelect,
  });

  final List<CategoryNode> nodes;
  final Map<String, int> directCounts;
  final String? selectedPath;
  final ValueChanged<String?>? onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final node in nodes) _tile(context, node)],
    );
  }

  Widget _tile(BuildContext context, CategoryNode node) {
    final theme = Theme.of(context);
    final selected = selectedPath == node.path;
    final count = node.totalCount(directCounts);
    final title = Row(
      children: [
        Expanded(
          child: Text(
            node.label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: selected ? FontWeight.bold : null,
              color: selected ? theme.colorScheme.primary : null,
            ),
          ),
        ),
        Text('$count', style: theme.textTheme.labelSmall),
      ],
    );
    if (node.children.isEmpty) {
      return ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        selected: selected,
        title: title,
        onTap: onSelect == null ? null : () => onSelect!(node.path),
      );
    }
    return ExpansionTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
      childrenPadding: const EdgeInsets.only(left: 14),
      initiallyExpanded:
          selectedPath != null && inCategorySubtree(selectedPath!, node.path),
      title: title,
      children: [
        CategoryTreeView(
          nodes: node.children,
          directCounts: directCounts,
          selectedPath: selectedPath,
          onSelect: onSelect,
        ),
      ],
    );
  }
}
