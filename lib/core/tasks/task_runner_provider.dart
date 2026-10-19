// 全局任务队列入口（docs/01 main：初始化 DB/设置/队列）。
// 业务模块（fragments/prompts/kb）注册 handler 后经此入队；
// 首次读取即重置遗留 running 并恢复持久化任务（docs/02 A5）。
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database_provider.dart';
import 'task_runner.dart';

final taskRunnerProvider = Provider<TaskRunner>((ref) {
  final runner = TaskRunner(ref.watch(appDatabaseProvider));
  unawaited(runner.start());
  return runner;
});
