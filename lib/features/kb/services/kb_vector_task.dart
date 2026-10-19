import 'dart:convert';

import '../../../core/db/database.dart';
import '../../../core/search/vector_index.dart';
import 'kb_ai_gateway.dart';

/// 向量化任务（docs/02 D2 第5步）：入库后可选入队，失败不阻塞入库，
/// 条目无 embeddings 行即在 UI 标「未向量化」。
/// 队列行落在全局 task_queue 表（module=kb, taskType=kb_embed），
/// 处理器由本模块提供（向导入库后与检索页按需触发）。
class KbVectorTaskService {
  KbVectorTaskService(this._db, {this.gateway});

  static const module = 'kb';
  static const taskType = 'kb_embed';

  final AppDatabase _db;

  /// null = 未配置嵌入网关（入队后原样保留，等配置后再处理）。
  final KbAiGateway? gateway;

  /// 入队一条向量化任务，返回队列行 id。
  Future<int> enqueue({required int entryId, required String model}) {
    return _db.taskQueueDao.add(
      TaskQueueCompanion.insert(
        module: module,
        taskType: taskType,
        payload: jsonEncode({'entryId': entryId, 'model': model}),
      ),
    );
  }

  /// 处理本模块待执行任务。网关未配置时原样保留（不标记失败，等配置后再处理）。
  Future<({int success, int failed, int skipped})> processPending({
    int limit = 10,
  }) async {
    final tasks = (await _db.taskQueueDao.pending(limit: limit))
        .where((t) => t.module == module && t.taskType == taskType)
        .toList();
    var success = 0;
    var failed = 0;
    var skipped = 0;
    for (final task in tasks) {
      if (gateway == null) {
        skipped++;
        continue;
      }
      await _db.taskQueueDao.markRunning(task.id);
      try {
        final payload = jsonDecode(task.payload) as Map<String, dynamic>;
        final entryId = (payload['entryId'] as num).toInt();
        final model = payload['model'] as String? ?? '';
        final entry = await _db.kbEntriesDao.byId(entryId);
        if (entry == null) {
          await _db.taskQueueDao.markFinished(
            task.id,
            success: false,
            error: '条目不存在（可能已删除）',
          );
          failed++;
          continue;
        }
        await processEntry(entryId: entryId, model: model);
        await _db.taskQueueDao.markFinished(
          task.id,
          success: true,
          result: jsonEncode({'model': model}),
        );
        success++;
      } catch (e) {
        await _db.taskQueueDao.markFinished(
          task.id,
          success: false,
          error: '向量化失败：$e',
        );
        failed++;
      }
    }
    return (success: success, failed: failed, skipped: skipped);
  }

  /// 对单条条目计算并写入向量（TaskRunner 的 kb_embed 处理器与本服务共用；
  /// 幂等：embeddings 以 entryId 为主键覆盖）。网关未配置时抛 KbAiNotConfiguredException。
  Future<void> processEntry({
    required int entryId,
    required String model,
  }) async {
    final gw = gateway;
    if (gw == null) {
      throw const KbAiNotConfiguredException('未配置嵌入模型，无法向量化');
    }
    final entry = await _db.kbEntriesDao.byId(entryId);
    if (entry == null) {
      throw StateError('条目不存在：$entryId');
    }
    final vector = await gw.embed(model: model, text: embeddingTextFor(entry));
    await _db.embeddingsDao.upsert(
      entryId: entryId,
      model: model,
      dim: vector.length,
      vector: VectorCodec.encodeFloat32Le(vector),
    );
  }

  /// 条目是否已有向量（UI「未向量化」标记依据）。
  Future<bool> isVectorized(int entryId) async {
    final row = await _db.embeddingsDao.byEntry(entryId);
    return row != null;
  }

  /// 向量化输入文本：名称 + 摘要 + 正文（剥离 Markdown 记号，压缩空白）。
  static String embeddingTextFor(KbEntry entry) {
    final body = entry.contentMd.replaceAll(RegExp(r'[#*`>\[\]()~-]'), ' ');
    final text = '${entry.entryName}\n${entry.summary}\n$body';
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

/// 条目向量解码（检索页/测试复用）。
List<double> decodeEntryVector(EntryEmbedding row) =>
    VectorCodec.decodeFloat32Le(row.vector, dim: row.dim);
