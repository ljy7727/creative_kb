// 结构化输出三态（成功 / 校验失败重试耗尽 / 传输异常透出）、围栏剥离、Schema 校验、
// 重试次数与错误回拼（docs/01 第五节、docs/03 测试策略）。
import 'package:creative_kb/core/llm/llm_client.dart';
import 'package:creative_kb/core/llm/providers.dart';
import 'package:creative_kb/core/llm/structured_output.dart';
import 'package:flutter_test/flutter_test.dart';

/// 假 LlmClient：按序回放预置文本，记录调用与消息，无网络。
class FakeLlmClient implements LlmClient {
  FakeLlmClient(this.responses);

  final List<String> responses;
  int calls = 0;
  final List<List<ChatMessage>> seenMessages = <List<ChatMessage>>[];

  @override
  Future<ChatResult> chat({
    required ProviderConfig provider,
    required String model,
    required List<ChatMessage> messages,
    double? temperature,
    double? topP,
    int? maxTokens,
    Map<String, dynamic>? extra,
    void Function(String delta)? onDelta,
  }) async {
    final index = calls < responses.length ? calls : responses.length - 1;
    calls++;
    seenMessages.add(List.of(messages));
    final raw = responses[index];
    onDelta?.call(raw);
    return ChatResult(
      content: raw,
      usage: UsageInfo(inputTokens: 10 * calls, outputTokens: calls),
    );
  }

  @override
  Future<List<ModelInfo>> listModels(ProviderConfig provider) async =>
      <ModelInfo>[];

  @override
  Future<List<List<double>>> embed({
    required ProviderConfig provider,
    required String model,
    required List<String> texts,
  }) async => <List<double>>[];
}

const _provider = ProviderConfig(
  name: 'DeepSeek',
  baseUrl: 'https://api.example.com/v1',
  apiKey: 'sk-test',
);

/// 模块B 碎片优化同款契约：{"items":[{"title":str,"content":str}]}。
const _itemsSchema = StructSchema.object(
  required: {'items'},
  properties: {
    'items': StructSchema.array(
      items: StructSchema.object(
        required: {'title', 'content'},
        properties: {
          'title': StructSchema.string(),
          'content': StructSchema.string(),
        },
      ),
    ),
  },
);

typedef Items = List<Map<String, String>>;

Items _decodeItems(Map<String, dynamic> json) => [
  for (final item in json['items'] as List)
    {'title': item['title'] as String, 'content': item['content'] as String},
];

void main() {
  group('JSON 提取（围栏剥离）', () {
    test('剥离 ```json 围栏与前后说明文字', () {
      const raw =
          '好的，结果如下：\n```json\n{"items":[{"title":"唐朝笏板","content":"官员上朝持笏板"}]}\n```\n希望有帮助';
      final extraction = extractJson(raw);
      expect(extraction.ok, isTrue);
      final decoded = extraction.value! as Map<String, dynamic>;
      expect((decoded['items'] as List).first, isA<Map<String, dynamic>>());
    });

    test('无围栏的裸 JSON、含字符串内花括号均正确截取', () {
      expect(extractJson('{"a":"含}括号"}').ok, isTrue);
      expect((extractJson('前缀 [1,2] 后缀').value! as List), [1, 2]);
      expect(extractJson('完全没有 JSON').error, contains('未找到 JSON'));
      expect(extractJson('{"a": 1').error, contains('不配对'));
    });
  });

  group('Schema 校验', () {
    test('缺必填与类型错误按路径报出', () {
      final violations = validateStruct({
        'items': [
          {'title': '只有标题'},
          {'content': 42},
        ],
      }, _itemsSchema);
      final paths = violations.map((v) => v.path).toList();
      expect(paths, contains('\$.items[0].content')); // 缺必填
      expect(paths, contains('\$.items[1].title')); // 缺必填
      // items[1].content = 42 → 类型错误
      expect(
        violations.firstWhere((v) => v.path == '\$.items[1].content').message,
        contains('字符串'),
      );
    });

    test('顶层非对象与嵌套数组元素非对象均报错', () {
      expect(validateStruct(<String>[], _itemsSchema), hasLength(1));
      expect(validateStruct({'items': '不是数组'}, _itemsSchema), hasLength(1));
      expect(validateStruct({'items': []}, _itemsSchema), isEmpty);
    });
  });

  group('StructuredOutput.request 三态', () {
    test('成功态：围栏输出解码入库，rawText 与 usage 保留', () async {
      final client = FakeLlmClient([
        '```json\n{"items":[{"title":"唐朝笏板","content":"五品以上持象牙笏板"}]}\n```',
      ]);
      final output = StructuredOutput(client: client);
      final result = await output.request<Items>(
        provider: _provider,
        model: 'deepseek-chat',
        messages: const [ChatMessage.system('只输出 JSON')],
        schema: _itemsSchema,
        decode: _decodeItems,
      );
      expect(result, isA<StructuredSuccess<Items>>());
      final success = result as StructuredSuccess<Items>;
      expect(success.value.single['title'], '唐朝笏板');
      expect(success.rawText, contains('```'));
      expect(success.usage.inputTokens, 10);
    });

    test('重试态：首次坏输出拼回校验错误，第二次成功', () async {
      final client = FakeLlmClient([
        '{"items":[{"title":"缺内容"}]}',
        '{"items":[{"title":"唐朝笏板","content":"补全了"}]}',
      ]);
      final deltas = <String>[];
      final result = await StructuredOutput(client: client).request<Items>(
        provider: _provider,
        model: 'deepseek-chat',
        messages: const [ChatMessage.user('整理这条灵感')],
        schema: _itemsSchema,
        decode: _decodeItems,
        onDelta: deltas.add,
      );
      expect(result, isA<StructuredSuccess<Items>>());
      expect(client.calls, 2);
      // 第二次请求带上原输出（assistant）+ 校验错误反馈（user）。
      final retryMessages = client.seenMessages[1];
      expect(retryMessages, hasLength(3));
      expect(retryMessages[1].role, 'assistant');
      expect(retryMessages[2].role, 'user');
      expect(retryMessages[2].content, contains('items[0].content'));
      // 流式增量只在首次尝试推送，重试不重复推送。
      expect(deltas, hasLength(1));
    });

    test('失败态：连续校验失败，重试 ≤2 次后返回错误明细', () async {
      final client = FakeLlmClient(['不是 JSON', '{"items":"类型不对"}', '还是不对']);
      final result = await StructuredOutput(client: client).request<Items>(
        provider: _provider,
        model: 'deepseek-chat',
        messages: const [ChatMessage.user('整理')],
        schema: _itemsSchema,
        decode: _decodeItems,
      );
      expect(result, isA<StructuredFailure<Items>>());
      final failure = result as StructuredFailure<Items>;
      expect(failure.attempts, 3); // 1 次初始 + 2 次重试（docs/01 第五节）
      expect(failure.violations, isNotEmpty);
      expect(failure.rawText, '还是不对');
      expect(client.calls, 3);
    });

    test('传输异常不吞掉：网络类异常直接透出（第三态）', () async {
      final client = FakeLlmClient(const []);
      var thrown = false;
      // 用抛异常的 client 包装：覆盖 chat。
      final failing = _ThrowingClient();
      try {
        await StructuredOutput(client: failing).request<Items>(
          provider: _provider,
          model: 'deepseek-chat',
          messages: const [ChatMessage.user('整理')],
          schema: _itemsSchema,
          decode: _decodeItems,
        );
      } on LlmNetworkException {
        thrown = true;
      }
      expect(thrown, isTrue);
      expect(client.calls, 0);
    });

    test('maxRetries 可调：设 0 时不重试', () async {
      final client = FakeLlmClient(['垃圾输出']);
      final result = await StructuredOutput(client: client, maxRetries: 0)
          .request<Items>(
            provider: _provider,
            model: 'deepseek-chat',
            messages: const [ChatMessage.user('整理')],
            schema: _itemsSchema,
            decode: _decodeItems,
          );
      expect((result as StructuredFailure<Items>).attempts, 1);
      expect(client.calls, 1);
    });
  });
}

class _ThrowingClient implements LlmClient {
  @override
  Future<ChatResult> chat({
    required ProviderConfig provider,
    required String model,
    required List<ChatMessage> messages,
    double? temperature,
    double? topP,
    int? maxTokens,
    Map<String, dynamic>? extra,
    void Function(String delta)? onDelta,
  }) async {
    throw LlmNetworkException('网络连接失败');
  }

  @override
  Future<List<ModelInfo>> listModels(ProviderConfig provider) async =>
      <ModelInfo>[];

  @override
  Future<List<List<double>>> embed({
    required ProviderConfig provider,
    required String model,
    required List<String> texts,
  }) async => <List<double>>[];
}
