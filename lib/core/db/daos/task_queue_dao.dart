part of '../database.dart';

/// task_queue 表 DAO：任务持久化与状态机流转（docs/02 A5）。
@DriftAccessor(tables: [TaskQueue])
class TaskQueueDao extends DatabaseAccessor<AppDatabase>
    with _$TaskQueueDaoMixin {
  TaskQueueDao(super.db);

  Stream<List<TaskQueueItem>> watchAll() =>
      (select(taskQueue)..orderBy([(t) => OrderingTerm.desc(t.id)])).watch();

  Future<List<TaskQueueItem>> byStatus(QueueTaskStatus status) =>
      (select(taskQueue)..where((t) => t.status.equalsValue(status))).get();

  /// 待执行任务，先进先出。
  Future<List<TaskQueueItem>> pending({int limit = 20}) =>
      (select(taskQueue)
            ..where((t) => t.status.equalsValue(QueueTaskStatus.pending))
            ..orderBy([(t) => OrderingTerm.asc(t.id)])
            ..limit(limit))
          .get();

  Future<TaskQueueItem?> byId(int id) =>
      (select(taskQueue)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> add(TaskQueueCompanion entry) => into(taskQueue).insert(entry);

  Future<void> markRunning(int id) =>
      (update(taskQueue)..where((t) => t.id.equals(id))).write(
        TaskQueueCompanion(
          status: const Value(QueueTaskStatus.running),
          startedAt: Value(DateTime.now()),
        ),
      );

  Future<void> markFinished(
    int id, {
    required bool success,
    String? result,
    String? error,
  }) => (update(taskQueue)..where((t) => t.id.equals(id))).write(
    TaskQueueCompanion(
      status: Value(success ? QueueTaskStatus.success : QueueTaskStatus.failed),
      result: Value(result),
      error: Value(error),
      finishedAt: Value(DateTime.now()),
    ),
  );

  Future<void> markCancelled(int id) =>
      (update(taskQueue)..where((t) => t.id.equals(id))).write(
        TaskQueueCompanion(
          status: const Value(QueueTaskStatus.cancelled),
          finishedAt: Value(DateTime.now()),
        ),
      );

  Future<void> incrementRetries(int id) => customUpdate(
    'UPDATE task_queue SET retries = retries + 1 WHERE id = ?',
    variables: [Variable.withInt(id)],
    updates: {taskQueue},
  );

  /// 启动时把上次异常退出的遗留 running 重置为 pending（docs/02 A5）。
  Future<int> resetRunningToPending() =>
      (update(
        taskQueue,
      )..where((t) => t.status.equalsValue(QueueTaskStatus.running))).write(
        const TaskQueueCompanion(status: Value(QueueTaskStatus.pending)),
      );

  Future<int> remove(int id) =>
      (delete(taskQueue)..where((t) => t.id.equals(id))).go();
}
