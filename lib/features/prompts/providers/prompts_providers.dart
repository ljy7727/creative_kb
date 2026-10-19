import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/db/database_provider.dart';
import '../services/prompt_ai_contracts.dart';
import '../services/prompt_ai_invoker_impl.dart';
import '../services/prompt_repository.dart';

/// 模块C 数据仓库。
final promptRepositoryProvider = Provider<PromptRepository>(
  (ref) => PromptRepository(ref.watch(appDatabaseProvider)),
);

/// AI 调用接缝（见 PromptAiInvoker 注释）：生产默认 LlmPromptAiInvoker
/// （core/llm 直调 + 额度防护 + 记账，prompt_ai_invoker_impl.dart）；
/// 测试以脚本化假实现 override 本 provider。
final promptAiInvokerProvider = Provider<PromptAiInvoker>(
  (ref) => LlmPromptAiInvoker(ref.watch(appDatabaseProvider)),
);

final promptAiServiceProvider = Provider<PromptAiService>(
  (ref) => PromptAiService(ref.watch(promptAiInvokerProvider)),
);

/// 「AI 可用」：已配置 Key 的厂商中存在启用中的模型（与 fragments 模块
/// pickOptimizeModel 的选取语义一致；docs/01 第四节：未配置时 AI 按钮 disabled）。
final promptAiReadyProvider = FutureProvider<bool>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final providers = await db.providersDao.getAll();
  for (final provider in providers) {
    if (provider.keyRef == null || provider.keyRef!.isEmpty) continue;
    final models = await db.modelsDao.activeByProvider(provider.id);
    if (models.isNotEmpty) return true;
  }
  return false;
});

/// 列表筛选状态：类型 + 分类 + 关键词（docs/02 模块C「分类与检索」）。
class PromptFilterState {
  const PromptFilterState({this.type, this.category, this.keyword = ''});

  final PromptType? type;
  final String? category;
  final String keyword;
}

class PromptFilterNotifier extends Notifier<PromptFilterState> {
  @override
  PromptFilterState build() => const PromptFilterState();

  void setType(PromptType? type) => state = PromptFilterState(
    type: type,
    category: state.category,
    keyword: state.keyword,
  );

  void setCategory(String? category) => state = PromptFilterState(
    type: state.type,
    category: category,
    keyword: state.keyword,
  );

  void setKeyword(String keyword) => state = PromptFilterState(
    type: state.type,
    category: state.category,
    keyword: keyword,
  );
}

final promptFilterProvider =
    NotifierProvider<PromptFilterNotifier, PromptFilterState>(
      PromptFilterNotifier.new,
    );

/// 列表流：筛选条件变化时切换查询。
final promptListProvider = StreamProvider<List<Prompt>>((ref) {
  final repository = ref.watch(promptRepositoryProvider);
  final filter = ref.watch(promptFilterProvider);
  return repository.watchFiltered(
    type: filter.type,
    category: filter.category,
    keyword: filter.keyword,
  );
});

/// 已用分类去重列表（分类筛选 chips 数据源）。
final promptCategoriesProvider = StreamProvider<List<String>>(
  (ref) => ref.watch(promptRepositoryProvider).watchCategories(),
);

/// 详情页：单条提示词流（删除后为 null）。
final promptDetailProvider = StreamProvider.family<Prompt?, int>(
  (ref, promptId) => ref.watch(promptRepositoryProvider).watchById(promptId),
);

/// 版本历史流，新版本在前。
final promptVersionsProvider = StreamProvider.family<List<PromptVersion>, int>(
  (ref, promptId) =>
      ref.watch(promptRepositoryProvider).watchVersions(promptId),
);

/// 思考强度预设（生成/优化/提取变量处共用的强度选择器数据源，docs/02 A4）。
final intensityPresetsProvider = StreamProvider<List<IntensityPreset>>(
  (ref) => ref.watch(appDatabaseProvider).intensityPresetsDao.watchAll(),
);

/// 灵感碎片列表（生成页选择数据源；直接读骨架 DAO，避免耦合 fragments 模块进度）。
final promptSourceFragmentsProvider = StreamProvider<List<Fragment>>(
  (ref) => ref.watch(appDatabaseProvider).fragmentsDao.watchAll(),
);
