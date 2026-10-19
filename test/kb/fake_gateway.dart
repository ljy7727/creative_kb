import 'dart:collection';

import 'package:creative_kb/features/kb/services/kb_ai_gateway.dart';

/// 伪造 AI 网关：按脚本回放响应、记录调用参数（docs/03：伪造 riverpod 覆盖/假客户端）。
class FakeKbAiGateway implements KbAiGateway {
  FakeKbAiGateway(List<String> responses, {this.embedVector = const [1.0, 0.0]})
    : _responses = Queue<String>.from(responses);

  final Queue<String> _responses;
  final List<double> embedVector;

  int completeCalls = 0;
  int embedCalls = 0;
  String lastSystem = '';
  String lastUser = '';
  double? lastTemperature;
  int? lastMaxTokens;

  void enqueue(String text) => _responses.add(text);

  bool get hasPendingResponse => _responses.isNotEmpty;

  @override
  Future<KbAiCompletion> complete({
    required String system,
    required String user,
    double? temperature,
    int? maxTokens,
  }) async {
    completeCalls++;
    lastSystem = system;
    lastUser = user;
    lastTemperature = temperature;
    lastMaxTokens = maxTokens;
    return KbAiCompletion(
      text: _responses.removeFirst(),
      model: 'deepseek-chat',
      providerName: 'DeepSeek',
      inputTokens: 100,
      outputTokens: 200,
    );
  }

  @override
  Future<List<double>> embed({
    required String model,
    required String text,
  }) async {
    embedCalls++;
    return embedVector;
  }
}
