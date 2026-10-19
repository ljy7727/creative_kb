import 'dart:convert';

import '../../../core/db/database.dart';
import '../models/prompt_models.dart';
import 'prompt_templates.dart';
import 'prompt_variables.dart';

/// AI 调用接缝：本模块只依赖该抽象。集成收尾（T7）把它适配到 core/llm 的
/// StructuredOutput/TaskRunner（JSON 围栏剥离、额度防护与 token 记账由 core
/// 统一负责），实现后 override prompts_providers.promptAiInvokerProvider 即可。
abstract interface class PromptAiInvoker {
  /// 返回模型原始文本输出；[intensityCode] 为思考强度预设 code（docs/02 A4）。
  Future<String> invoke({
    required String systemPrompt,
    required String userPrompt,
    required String intensityCode,
  });
}

/// AI 调用失败或契约校验失败。message 直接面向用户展示。
class PromptAiException implements Exception {
  PromptAiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 「从碎片生成 3 风格版本」系统提示词（docs/02 模块C JSON 契约）。
String buildStyleGenerateSystemPrompt(PromptType type) {
  final structure = PromptSkeletonTemplates.byType(type).sections
      .map((s) => s.title)
      .join('、');
  return '你是提示词工程助手。用户会给出若干条灵感碎片，请把它们融合为一个'
      '「${type.label}」提示词，并输出 3 个风格版本：\n'
      '- 精简：一句话级核心指令，保留全部关键要求；\n'
      '- 详细：结构化完整提示词（建议按 $structure 分段组织）；\n'
      '- 创意：在忠实原意的前提下加入巧思与表现力表达。\n'
      '只输出 JSON，不要输出任何其他文字，格式：\n'
      '{"versions":[{"style":"精简","body":"…"},{"style":"详细","body":"…"},'
      '{"style":"创意","body":"…"}]}\n'
      '要求：body 为可直接使用的完整提示词正文；三个版本差异明显；'
      '不得编造碎片中不存在的事实性信息。';
}

/// 「从碎片生成」用户消息：目标类型 + 全部碎片文本。
String buildStyleGenerateUserPrompt({
  required PromptType type,
  required List<Fragment> fragments,
}) {
  final buffer = StringBuffer(
    '目标类型：${type.label}提示词。灵感碎片共 ${fragments.length} 条：',
  );
  for (var i = 0; i < fragments.length; i++) {
    final fragment = fragments[i];
    final title = fragment.title.isEmpty ? '未命名碎片' : fragment.title;
    buffer
      ..writeln()
      ..writeln('【碎片${i + 1}】$title')
      ..write(fragment.rawText.trim());
  }
  return buffer.toString();
}

/// 解析 3 风格版本契约；缺任一风格或非法 JSON 抛 [PromptAiException]。
List<StyleDraft> parseStyleVersions(String raw) {
  final json = _decodeJsonObject(raw);
  final list = json['versions'];
  if (list is! List) throw PromptAiException('模型输出缺少 versions 数组');

  final byLabel = <String, StyleDraft>{};
  for (final item in list) {
    if (item is! Map<String, dynamic>) continue;
    final style = promptStyleFromLabel((item['style'] ?? '').toString());
    final body = (item['body'] ?? '').toString().trim();
    if (style == null || body.isEmpty) continue;
    byLabel.putIfAbsent(
      style.label,
      () => StyleDraft(style: style, body: body),
    );
  }
  final drafts = [
    for (final style in PromptStyle.values)
      if (byLabel[style.label] != null) byLabel[style.label]!,
  ];
  if (drafts.length < PromptStyle.values.length) {
    throw PromptAiException('模型输出未包含完整的「精简/详细/创意」三个版本');
  }
  return drafts;
}

/// 「定向优化」系统提示词（4 方向共用，方向细节在用户消息中给出）。
const String _optimizeSystemPrompt =
    '你是提示词优化助手。按用户给定的方向改写提示词正文：'
    '保持原意与全部硬性要求，输出改写后的完整正文与一句话改动说明。'
    '只输出 JSON，不要输出任何其他文字，格式：\n'
    '{"body":"优化后的完整正文","note":"一句话说明本次改动"}';

String buildOptimizeSystemPrompt() => _optimizeSystemPrompt;

String _directionGuidance(OptimizeDirection direction) => switch (direction) {
  OptimizeDirection.condense => '精简压缩：删除冗余重复表述，尽量缩短篇幅，但不得丢掉任何硬性要求。',
  OptimizeDirection.expand => '扩写丰富：补充细节、示例与边界情形，使指令更具体、可直接执行。',
  OptimizeDirection.adaptModel => '适配特定模型：按目标模型的指令偏好与上下文特点调整措辞、结构与长度。',
  OptimizeDirection.restyle => '风格转换：把语言风格改为用户指定的风格，任务实质保持不变。',
};

String buildOptimizeUserPrompt({
  required String body,
  required OptimizeDirection direction,
  String? targetModel,
  String? targetStyle,
}) {
  final buffer = StringBuffer(
    '优化方向：${direction.label}。${_directionGuidance(direction)}',
  );
  if (direction.needsTargetModel) buffer.write('目标模型：${targetModel ?? ''}。');
  if (direction.needsTargetStyle) buffer.write('目标风格：${targetStyle ?? ''}。');
  buffer
    ..writeln()
    ..writeln('原正文（用 <<<PROMPT 与 PROMPT 包裹）：')
    ..writeln('<<<PROMPT')
    ..writeln(body)
    ..write('PROMPT');
  return buffer.toString();
}

/// 解析定向优化契约；body 缺失抛 [PromptAiException]，note 可缺省。
OptimizeResult parseOptimizeResult(String raw) {
  final json = _decodeJsonObject(raw);
  final body = (json['body'] ?? '').toString().trim();
  if (body.isEmpty) throw PromptAiException('模型输出缺少优化后的正文 body');
  final noteValue = json['note'];
  final note = noteValue?.toString().trim();
  return OptimizeResult(
    body: body,
    note: (note == null || note.isEmpty) ? null : note,
  );
}

/// 「变量提取」系统提示词（docs/02 模块C：分析 body 输出 variables）。
const String _variablesSystemPrompt =
    '你是提示词变量分析助手。找出正文中适合参数化、'
    '由使用者填写的可变信息（如名称、地点、数量、模型名、风格词等），'
    '为每个变量取一个简短中文名。只输出 JSON，不要输出任何其他文字，格式：\n'
    '{"variables":[{"name":"变量名","desc":"一句话说明该处应填什么"}]}\n'
    '要求：变量数量 3-8 个为宜；正文没有可参数化内容时输出空数组。';

String buildVariablesSystemPrompt() => _variablesSystemPrompt;

String buildVariablesUserPrompt(String body) =>
    '待分析正文（用 <<<PROMPT 与 PROMPT 包裹）：\n<<<PROMPT\n$body\nPROMPT';

/// 解析变量提取契约并本地标注正文：变量名裸出现包成 {{变量名}}。
VariablesExtractResult parseVariablesResult(
  String raw, {
  required String originalBody,
}) {
  final json = _decodeJsonObject(raw);
  final list = json['variables'];
  if (list is! List) throw PromptAiException('模型输出缺少 variables 数组');

  final variables = <PromptVariable>[];
  for (final item in list) {
    if (item is! Map<String, dynamic>) continue;
    final name = (item['name'] ?? '').toString().trim();
    if (name.isEmpty) continue;
    if (variables.any((variable) => variable.name == name)) continue;
    variables.add(
      PromptVariable(name: name, desc: (item['desc'] ?? '').toString().trim()),
    );
  }
  return VariablesExtractResult(
    variables: variables,
    annotatedBody: annotateVariables(originalBody, [
      for (final variable in variables) variable.name,
    ]),
  );
}

/// 组合「构建提示词 → 调用 → 契约校验」。契约不合法时把错误拼回消息自动重试，
/// 最多 [maxRetries] 次（docs/00 验收 5：≤2 次）。
class PromptAiService {
  PromptAiService(this._invoker, {this.maxRetries = 2});

  final PromptAiInvoker _invoker;
  final int maxRetries;

  /// 从碎片一次生成 3 个风格版本。
  /// 参数类错误以失败 Future 形式抛出（调用方 await 均可捕获）。
  Future<List<StyleDraft>> generateStyleVersions({
    required PromptType type,
    required List<Fragment> fragments,
    required String intensityCode,
  }) async {
    if (fragments.isEmpty) throw PromptAiException('请先选择至少一条灵感碎片');
    return _runWithRetry(
      system: buildStyleGenerateSystemPrompt(type),
      baseUser: buildStyleGenerateUserPrompt(type: type, fragments: fragments),
      intensityCode: intensityCode,
      parse: parseStyleVersions,
    );
  }

  /// 四方向定向优化。
  Future<OptimizeResult> optimize({
    required String body,
    required OptimizeDirection direction,
    String? targetModel,
    String? targetStyle,
    required String intensityCode,
  }) async {
    if (direction.needsTargetModel &&
        (targetModel == null || targetModel.trim().isEmpty)) {
      throw PromptAiException('请先填写目标模型名');
    }
    if (direction.needsTargetStyle &&
        (targetStyle == null || targetStyle.trim().isEmpty)) {
      throw PromptAiException('请先填写目标风格');
    }
    return _runWithRetry(
      system: buildOptimizeSystemPrompt(),
      baseUser: buildOptimizeUserPrompt(
        body: body,
        direction: direction,
        targetModel: targetModel?.trim(),
        targetStyle: targetStyle?.trim(),
      ),
      intensityCode: intensityCode,
      parse: parseOptimizeResult,
    );
  }

  /// 变量提取（正文标注在本模块本地完成，见 [parseVariablesResult]）。
  Future<VariablesExtractResult> extractVariables({
    required String body,
    required String intensityCode,
  }) {
    return _runWithRetry<VariablesExtractResult>(
      system: buildVariablesSystemPrompt(),
      baseUser: buildVariablesUserPrompt(body),
      intensityCode: intensityCode,
      parse: (raw) => parseVariablesResult(raw, originalBody: body),
    );
  }

  Future<T> _runWithRetry<T>({
    required String system,
    required String baseUser,
    required String intensityCode,
    required T Function(String raw) parse,
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      final user = attempt == 0
          ? baseUser
          : '$baseUser\n\n注意：上一次输出未通过校验（$lastError），请严格按约定只输出 JSON。';
      try {
        final raw = await _invoker.invoke(
          systemPrompt: system,
          userPrompt: user,
          intensityCode: intensityCode,
        );
        return parse(raw);
      } on PromptAiException catch (error) {
        lastError = error.message;
      }
    }
    throw PromptAiException('AI 输出多次未通过校验：$lastError');
  }
}

/// 剥离 ```json 围栏并要求解码结果为对象（docs/01 第五节）。
Map<String, dynamic> _decodeJsonObject(String raw) {
  var text = raw.trim();
  final fenced = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(text);
  if (fenced != null) text = fenced.group(1)!.trim();
  try {
    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) return decoded;
  } on FormatException {
    // 落到下方统一报错，由上层把错误拼回消息重试。
  }
  throw PromptAiException('模型未输出合法 JSON');
}
