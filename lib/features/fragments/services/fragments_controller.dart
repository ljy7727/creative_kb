// 模块B 状态层：列表/筛选/录入/删除/重新优化（flutter_riverpod Notifier）。
// 数据库未注入（如壳层冒烟测试的裸 ProviderScope）时优雅降级为空态，不崩溃。
import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ProviderException（watch/read 错误态 provider 时的包装异常）在 misc 导出中。
import 'package:flutter_riverpod/misc.dart';

import '../../../core/db/app_setting_keys.dart';
import '../../../core/db/database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/llm/vision_ocr.dart';
import '../../../core/tasks/task_runner_provider.dart';
import '../models/fragment_models.dart';
import 'fragment_optimize_task.dart';

/// 列表筛选条件：标签 + 关键词（docs/02 B2：标签筛选 + 简易关键词检索）。
class FragmentsFilter {
  const FragmentsFilter({this.tag, this.keyword = ''});

  final String? tag;
  final String keyword;

  FragmentsFilter copyWith({Object? tag = _unset, String? keyword}) {
    final nextTag = tag == _unset ? this.tag : tag as String?;
    return FragmentsFilter(tag: nextTag, keyword: keyword ?? this.keyword);
  }

  static const _unset = Object();
}

/// 纯函数：对倒序列表做标签/关键词过滤（关键词命中标题或原文，忽略大小写）。
List<Fragment> filterFragments(
  List<Fragment> fragments,
  FragmentsFilter filter,
) {
  final keyword = filter.keyword.trim().toLowerCase();
  return fragments.where((fragment) {
    if (filter.tag != null && !decodeTags(fragment.tags).contains(filter.tag)) {
      return false;
    }
    if (keyword.isNotEmpty &&
        !fragment.title.toLowerCase().contains(keyword) &&
        !fragment.rawText.toLowerCase().contains(keyword)) {
      return false;
    }
    return true;
  }).toList();
}

/// 汇总列表内全部标签（去重升序），供筛选 chips。
List<String> collectTags(List<Fragment> fragments) {
  final tags = <String>{};
  for (final fragment in fragments) {
    tags.addAll(decodeTags(fragment.tags));
  }
  return tags.toList()..sort();
}

/// 页面状态。
class FragmentsViewState {
  const FragmentsViewState({
    required this.dbReady,
    this.fragments = const [],
    this.filter = const FragmentsFilter(),
    this.optimizingIds = const {},
    this.lastError,
  });

  const FragmentsViewState.dbMissing() : this(dbReady: false);

  static const _unset = Object();

  final bool dbReady;
  final List<Fragment> fragments;
  final FragmentsFilter filter;

  /// 正在 AI 优化中的 fragmentId（列表/详情显示「优化中」并禁止重复发起）。
  final Set<int> optimizingIds;
  final String? lastError;

  bool isOptimizing(int fragmentId) => optimizingIds.contains(fragmentId);

  /// [lastError] 传 null 显式清除，缺省保持不变。
  FragmentsViewState copyWith({
    List<Fragment>? fragments,
    FragmentsFilter? filter,
    Set<int>? optimizingIds,
    Object? lastError = _unset,
  }) {
    return FragmentsViewState(
      dbReady: dbReady,
      fragments: fragments ?? this.fragments,
      filter: filter ?? this.filter,
      optimizingIds: optimizingIds ?? this.optimizingIds,
      lastError: lastError == _unset ? this.lastError : lastError as String?,
    );
  }
}

/// 单条灵感的实时流（详情页用）。
final fragmentByIdProvider = StreamProvider.family<Fragment?, int>((ref, id) {
  final db = ref.watch(appDatabaseProvider);
  final query = db.select(db.fragments)..where((t) => t.id.equals(id));
  return query.watchSingleOrNull();
});

/// 强度预设列表（详情页「重新优化」与录入页选择器共用）。
final intensityPresetsProvider = StreamProvider<List<IntensityPreset>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.intensityPresetsDao.watchAll();
});

/// 全局默认强度（docs/02 A4：默认 standard）。
final defaultIntensityProvider = FutureProvider<String>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final value = await db.appSettingsDao.get(AppSettingKeys.defaultIntensity);
  if (value == null || value.isEmpty) return 'standard';
  return value;
});

final fragmentsControllerProvider =
    NotifierProvider<FragmentsController, FragmentsViewState>(
      FragmentsController.new,
    );

class FragmentsController extends Notifier<FragmentsViewState> {
  @override
  FragmentsViewState build() {
    final AppDatabase db;
    try {
      db = ref.watch(appDatabaseProvider);
    } on ProviderException catch (error) {
      // 数据库未注入（如壳层冒烟测试的裸 ProviderScope）：空态降级，不崩溃。
      if (error.exception is UnimplementedError) {
        return const FragmentsViewState.dbMissing();
      }
      rethrow;
    } on UnimplementedError {
      return const FragmentsViewState.dbMissing();
    }
    final subscription = db.fragmentsDao.watchAll().listen(
      (rows) => state = state.copyWith(fragments: rows),
      onError: (Object error) =>
          state = state.copyWith(lastError: '读取灵感列表失败：$error'),
    );
    ref.onDispose(subscription.cancel);
    return const FragmentsViewState(dbReady: true);
  }

  // —— 筛选 ——

  void setTagFilter(String? tag) =>
      state = state.copyWith(filter: state.filter.copyWith(tag: tag));

  void setKeyword(String keyword) =>
      state = state.copyWith(filter: state.filter.copyWith(keyword: keyword));

  // —— 录入（B1）——

  /// 保存灵感；勾选 AI 时保存后立即发起优化（异步，不阻塞返回）。
  /// 返回是否已保存（供页面决定是否清空输入框）。
  Future<bool> submit({
    required String text,
    required bool useAi,
    required String intensityCode,
    List<String> tags = const [],
  }) async {
    final db = _database();
    if (db == null) return false;
    final raw = text.trim();
    if (raw.isEmpty) {
      state = state.copyWith(lastError: '请先输入灵感内容');
      return false;
    }

    final id = await db.fragmentsDao.add(
      FragmentsCompanion.insert(
        rawText: raw,
        source: FragmentSource.manual,
        tags: Value(encodeTags(tags)),
      ),
    );

    if (useAi) {
      await optimize(id, intensityCode: intensityCode);
    }
    return true;
  }

  /// 发起/重新发起 AI 优化（docs/02 B2「重新优化」：换强度重跑）。
  /// 经 core/tasks TaskRunner 入队执行：额度拦截、重试、超时与记账
  /// 由队列统一负责，这里只跟踪「优化中」状态并回显队列错误。
  Future<void> optimize(int fragmentId, {required String intensityCode}) async {
    final db = _database();
    if (db == null) return;
    if (state.isOptimizing(fragmentId)) return;

    // 触发任务处理器注册（桥接 provider 内部已做未注入降级）。
    ref.read(fragmentsTaskBridgeProvider);
    final runner = ref.read(taskRunnerProvider);

    state = state.copyWith(optimizingIds: {...state.optimizingIds, fragmentId});
    try {
      final taskId = await runner.enqueue(
        module: FragmentOptimizeTask.module,
        taskType: FragmentOptimizeTask.taskType,
        payload: {'fragmentId': fragmentId, 'intensity': intensityCode},
      );
      final row = await runner.whenFinished(taskId);
      if (row.status == QueueTaskStatus.failed &&
          row.error != null &&
          row.error!.isNotEmpty) {
        state = state.copyWith(lastError: row.error);
      }
    } catch (error) {
      state = state.copyWith(lastError: '优化失败：$error');
    } finally {
      final remaining = {...state.optimizingIds}..remove(fragmentId);
      state = state.copyWith(optimizingIds: remaining);
    }
  }

  // —— 编辑/删除（B3：无 Key 也可手动编辑/删除）——

  Future<void> updateRawText(int fragmentId, String rawText) async {
    final db = _database();
    if (db == null) return;
    final fragment = await db.fragmentsDao.byId(fragmentId);
    if (fragment == null) return;
    await db.fragmentsDao.updateRow(
      fragment.copyWith(rawText: rawText.trim(), updatedAt: DateTime.now()),
    );
  }

  /// 删除灵感，连带删除由它拆分出的派生行。
  Future<void> delete(int fragmentId) async {
    final db = _database();
    if (db == null) return;
    await removeDerivedRows(db, fragmentId);
    await db.fragmentsDao.remove(fragmentId);
  }

  void clearError() => state = state.copyWith(lastError: null);

  AppDatabase? _database() {
    try {
      return ref.watch(appDatabaseProvider);
    } on ProviderException catch (error) {
      if (error.exception is UnimplementedError) return null;
      rethrow;
    } on UnimplementedError {
      return null;
    }
  }
}

/// 图片 OCR 服务（调用视觉模型识别图片文字，见 core/llm/vision_ocr.dart）。
final visionOcrServiceProvider = Provider<VisionOcrService>(
  (ref) => VisionOcrService(ref.watch(appDatabaseProvider)),
);
