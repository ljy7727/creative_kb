import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/prompt_models.dart';
import '../services/prompt_variables.dart';

/// 变量填值 → 实时替换预览 → 复制（docs/02 模块C 详情页变量面板）。
class VariableFillDialog extends StatefulWidget {
  const VariableFillDialog({
    super.key,
    required this.body,
    required this.variables,
  });

  final String body;
  final List<PromptVariable> variables;

  @override
  State<VariableFillDialog> createState() => _VariableFillDialogState();
}

class _VariableFillDialogState extends State<VariableFillDialog> {
  final Map<String, TextEditingController> _controllers = {};
  late String _preview = fillVariables(widget.body, _currentValues());

  @override
  void initState() {
    super.initState();
    for (final variable in widget.variables) {
      final controller = TextEditingController();
      controller.addListener(_refreshPreview);
      _controllers[variable.name] = controller;
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<String, String> _currentValues() => {
    for (final entry in _controllers.entries) entry.key: entry.value.text,
  };

  void _refreshPreview() => setState(() {
    _preview = fillVariables(widget.body, _currentValues());
  });

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _preview));
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('填充结果已复制到剪贴板')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('填充变量并复制'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.variables.isEmpty)
              const Text('该提示词暂无变量，可直接复制正文。')
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final variable in widget.variables)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TextField(
                            controller: _controllers[variable.name],
                            decoration: InputDecoration(
                              labelText: variable.name,
                              helperText: variable.desc.isEmpty
                                  ? null
                                  : variable.desc,
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            const Divider(),
            Text('填充结果预览', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Flexible(
              child: SingleChildScrollView(
                child: SelectableText(
                  _preview,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
        FilledButton.icon(
          onPressed: _copy,
          icon: const Icon(Icons.copy_outlined),
          label: const Text('复制结果'),
        ),
      ],
    );
  }
}
