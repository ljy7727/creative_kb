// FragmentOptimizeTask 提示词契约（docs/02 B2）。
// 任务标识 module/taskType 同时用于 task_queue 与 usage_log。
abstract final class FragmentOptimizePrompt {
  static const module = 'fragments';
  static const taskType = 'fragment_optimize';

  /// 系统提示词：JSON 契约 + 整理规则（纠错/提炼/拆分/打标签/不编造）。
  static const systemPrompt = '''
你是创作灵感整理助手。用户会给出口语化、零散甚至混乱的灵感记录，你要把它们整理为标准灵感条目。

输出要求：只输出一个 JSON 对象，不要输出任何解释文字或围栏。格式如下：
{"items":[{"title":"条目标题","content":"整理后的完整表述（Markdown）","tags":["#主题-子类"],"context":"可选：补充背景"}]}

整理规则：
1. 纠错润色：修正错别字与语病，把残缺句补成通顺完整的表述；
2. 剥离语气词与冗余，保留核心创意；
3. 一条输入包含多个独立灵感时，必须拆分为多条 items，每条只表达一个主题；
4. 标签形如 #主题-子类（例如 #设定-官职、#情节-冲突），每条 2~4 个；
5. 不得编造原输入中没有的事实性信息；不确定的内容保留原表述并在其后加 "(存疑)"。''';

  static String userPrompt(String rawText) => '请整理以下灵感记录：\n\n$rawText';

  /// 结构化校验失败后重试：把校验错误拼回消息（docs/01 第五节）。
  static String retryUserPrompt(String rawText, String validationError) =>
      '${userPrompt(rawText)}\n\n'
      '上一次输出未通过校验，错误：$validationError\n'
      '请修正后重新输出，仍然只输出符合上述格式的 JSON 对象。';
}
